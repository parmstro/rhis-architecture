---
layout: default
title: RHIS Architecture
---

# RHIS Architecture

**Red Hat Infrastructure Standard — System Architecture**

---

## Table of Contents

- [Overview](#overview)
- [Design Principles](#design-principles)
- [Architecture Layers](#architecture-layers)
- [Deployment Flow](#deployment-flow)
- [Component Architecture](#component-architecture)
- [Configuration Architecture](#configuration-architecture)
- [Container Architecture](#container-architecture)
- [Security Architecture](#security-architecture)
- [Network Architecture](#network-architecture)
- [Data Flow](#data-flow)
- [Scalability](#scalability)
- [Disaster Recovery](#disaster-recovery)
- [Future Roadmap](#future-roadmap)

---

## Overview

RHIS is an enterprise infrastructure deployment platform for multi-cloud, on-premise,
and air-gapped environments. It automates the full lifecycle of Red Hat infrastructure:
provisioning, identity, content management, configuration, security, and day-2 operations.

The platform is implemented as a set of Ansible-based repositories (`rhis-builder-*`),
packaged into a hermetic provisioner container for validated, reproducible deployment.

### Key Characteristics

- **Hermetic Packaging**: All dependencies baked into a scanned, signed container image
- **Identity-Driven**: IdM is the first service deployed; all components integrate with it
- **Declarative**: Infrastructure defined as code in `rhis-builder-inventory`
- **Satellite-Driven**: After bootstrap, Satellite provisions all infrastructure
- **Air-Gap Ready**: Single container transfer for disconnected environments
- **Multi-Platform**: Targets every compute resource Red Hat Satellite supports

---

## Design Principles

### 1. Hermetic Deployment

All dependencies are packaged within the provisioner container at build time.

- `rhis-provisioner-container` clones all component repos via `configure_rhis_builder.yml`
- All Python packages, Ansible collections, and binary tools are baked into the base image
- No runtime fetching of code or dependencies
- The container is scanned, signed, and attested before push to quay.io

### 2. Identity-First Architecture

Red Hat Identity Management is the first service deployed and all components integrate with it.

- IdM provides DNS (forward and reverse zones with dynamic updates)
- IdM CA issues TLS certificates for all services
- Kerberos provides service-to-service authentication
- All hosts auto-enroll in IdM during provisioning
- Satellite uses `realm-capsule` integration for automated IdM enrollment

### 3. Configuration as Code

All infrastructure is defined declaratively in `rhis-builder-inventory`.

- `inventory_template/` contains the source-of-truth templates
- `inventory_update.sh` renders per-deployment configurations
- Rendered output goes to `deployments/<domain>/` — never edited directly
- Secrets are vault-encrypted and preserved across regeneration
- Git tracks all configuration changes

### 4. Satellite-Driven Provisioning

After the bootstrap phase (IdM + Satellite), Satellite provisions all subsequent infrastructure.

- Hostgroups define each system type
- Compute resources abstract the underlying platform
- Provisioning templates are managed via GitOps (`rhis-builder-satellite-templates`)
- Content views and lifecycle environments control what packages are available
- System deployments to every compute resource Satellite manages

### 5. Component-Scoped Variables

Variables use component-scoped prefixes (`satellite_`, `idm_`, `kvm_`, `platform_`),
not role-scoped prefixes. All tasks use fully-qualified collection names (`ansible.builtin.*`).

---

## Architecture Layers

```
┌────────────────────────────────────────────────────────────┐
│  Layer 5: Application Infrastructure                       │
│  Customer workloads, applications                          │
└────────────────┬───────────────────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────────────────┐
│  Layer 4: Infrastructure Services                          │
│  AAP, Keycloak, NBDE, Quay, Quadlet services, YubiKey     │
└────────────────┬───────────────────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────────────────┐
│  Layer 3: Universal Provisioner (Satellite)                │
│  Compute resources, hostgroups, content management,        │
│  lifecycle environments, provisioning templates            │
└────────────────┬───────────────────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────────────────┐
│  Layer 2: Identity & DNS (IdM)                             │
│  Authentication, authorization, DNS, CA, Kerberos          │
└────────────────┬───────────────────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────────────────┐
│  Layer 1: Compute Platform (Landing Zone)                  │
│  Bare metal, KVM, VMware, AWS, Azure, and more             │
│  Minimal RHEL hosts for IdM + Satellite bootstrap          │
└────────────────────────────────────────────────────────────┘
```

---

## Deployment Flow

### Phase 0: Landing Zone

**Goal**: Create minimal RHEL hosts for IdM and Satellite bootstrap.

The landing zone abstraction is designed to create the underlying infrastructure components for an RHIS deployment to bootstrap from.
The goal is to support a landing zone configurator for any compute resource that Satellite can then provision to. 
The landing zone model in RHIS is a bit of a chicken and egg challenge. 
Each landing zone becomes both a bootstrap source and a provisioning target.
A landing zone may perform introspection (discover existing infrastructure),build (create infrastructure using certified Ansible collections), or both.
It is not necessary to implement a landing zone through RHIS.
A landing zone may be built or provide through other common deployment implementations, e.g. Azure provisioning templates, Terraform infrastructure provisioning, etc..

**Current implementations**:
- `rhis-builder-bootstrap-init` — bare metal (kickstart/OEMDRV generation)
- `rhis-builder-kvm-lz` — KVM/libvirt
- `rhis-builder-aws-lz` — Amazon Web Services
- `rhis-builder-azure-lz` — Microsoft Azure

**Target platforms** (matching Satellite compute resource support):
bare metal, VMware, Hyper-V, Proxmox, KVM/libvirt, OpenStack,
OpenShift Virtualization, AWS, Azure, GCP, and local cloud variants.

**Output**: Minimal RHEL hosts with network connectivity for IdM and Satellite.

### Phase 1: Bootstrap Infrastructure

**Goal**: Deploy foundational identity and provisioning services.

#### Step 1: Deploy IdM Primary

**Repository**: `rhis-builder-idm`
**Build script**: `build_idm_primary.sh`

1. Install IdM server with integrated CA
2. Configure forward and reverse DNS zones
3. Create users, groups, host groups
4. Configure sudo rules and HBAC policies
5. Establish Active Directory trusts (if required)
6. Enable dynamic DNS updates

**Output**: Functional IdM providing authentication, authorization, DNS,
and certificate authority for the entire platform.

#### Step 2: Deploy Satellite Primary

**Repository**: `rhis-builder-satellite`
**Build script**: `build_sat_primary.sh`

1. Install Satellite server
2. Register as IdM client
3. Run `foreman-prepare-realm` for automated host enrollment
4. Create HTTP service principal and IdM CA certificates
5. Configure compute resources
6. Create compute profiles and hostgroups
7. Import provisioning templates from git
8. Configure content views and lifecycle environments
9. Sync Red Hat content

**Output**: Functional Satellite integrated with IdM, ready to provision
all subsequent infrastructure.

### Phase 2: Infrastructure Services

**Goal**: Deploy operational services via Satellite provisioning.

All systems are provisioned through Satellite using appropriate hostgroups,
then configured via Ansible playbooks from the provisioner container.

**Components and build scripts**:
- **AAP**: `build_aap_controller.sh` — Ansible Automation Platform (controller, gateway, hub, EDA)
- **Satellite Capsules**: `build_sat_1_capsules_satellite_pre.sh` → `build_sat_2_capsules.sh` → `build_sat_3_capsules_satellite_post.sh`
- **IdM Replicas**: `build_idm_replicas.sh`
- **KVM Hypervisors**: `build_kvm_hosts.sh`
- **Quadlet Services**: `build_quadlets.sh` — containerized services (Quay, log aggregation, etc.)
- **NBDE**: Tang servers for network-bound disk encryption
- **Keycloak**: Identity brokering (SAML/OAuth/OIDC)
- **YubiKey**: Hardware token 2FA via IdM

### Phase 3: Application Infrastructure

**Goal**: Provision customer workloads using the same Satellite-driven workflow
with customer-defined hostgroups and content views.

---

## Component Architecture

### rhis-builder-inventory

Single source of truth for all infrastructure configuration.

```
rhis-builder-inventory/
├── inventory_template/              # Source-of-truth templates
│   ├── group_vars/                  # Template group variables
│   │   ├── all/                     # Variables for all hosts
│   │   ├── idm_primary/
│   │   ├── idm_replicas/
│   │   ├── imagebuilders/
│   │   ├── keycloak_servers/
│   │   ├── kvm_hypervisors/
│   │   ├── platform_installer/
│   │   ├── provisioner/
│   │   └── quay_servers/
│   ├── host_vars/                   # Template host variables
│   │   ├── aapcontroller26/         # AAP 2.6 controller config
│   │   ├── aapedacontroller26/
│   │   ├── aaphub26/
│   │   ├── capsule/
│   │   ├── idm/
│   │   ├── quadlet/
│   │   ├── quay/
│   │   └── satellite/
│   ├── inventory/                   # Inventory template (inventory.j2)
│   ├── templates/                   # Jinja2 templates (installer inventories, etc.)
│   └── scripts/                     # Launcher template (template.25.sh.j2)
├── inventory_basevars.yml           # Default base variables
├── inventory_update.sh              # Renders templates into deployments/
├── deployments/                     # Generated output (never edit directly)
│   └── <domain>/
│       ├── inventory/               # Rendered Ansible inventory
│       ├── group_vars/              # Domain-specific group vars
│       ├── host_vars/               # Domain-specific host vars (FQDN-based)
│       ├── templates/               # Rendered templates
│       ├── vault/                   # Encrypted secrets (preserved across regeneration)
│       ├── vault_SAMPLES/           # Reference vault file
│       ├── external_tasks/          # Custom playbooks
│       ├── files/                   # Static files
│       ├── vars/                    # Additional variables
│       ├── scripts/                 # Generated launcher scripts
│       └── logs/                    # Deployment logs
└── docs/                            # IP addressing documentation
```

**Key workflow**: Edit `inventory_template/` → run `inventory_update.sh` →
rendered output appears in `deployments/<domain>/`. The vault directory is
preserved across regenerations.

### rhis-provisioner-container

Hermetic container aggregating all RHIS components for deployment.

**Two-layer build**:

1. **rhis-base** (built via `rhis_build_base.sh`):
   - RHEL UBI 9/10 base
   - Python dependencies (from `dnf_requirements.txt` — no `pip install`)
   - Ansible core + all required collections
   - Scanning tools (Grype, Trivy, ClamAV, Syft, cosign, KICS)
   - Security hardening

2. **rhis-provisioner** (built via `rhis_build_provisioner.sh`, layered on rhis-base):
   - Clones all rhis-builder-* repos via `configure_rhis_builder.yml`
     (uses `ansible.builtin.git`, not shell `git clone`)
   - Creates symlinks from each project's config directories to mounted volumes
   - Adds build/deploy helper scripts (`build_*.sh`)
   - All repos available at `/rhis/rhis-builder-*/`

**Runtime mounts** (from rendered deployment directory):

| Container Path | Source |
|---|---|
| `/rhis/vars/external_inventory/` | `deployments/<domain>/inventory/` |
| `/rhis/vars/group_vars/` | `deployments/<domain>/group_vars/` |
| `/rhis/vars/host_vars/` | `deployments/<domain>/host_vars/` |
| `/rhis/vars/vault/` | `deployments/<domain>/vault/` |
| `/rhis/vars/templates/` | `deployments/<domain>/templates/` |
| `/rhis/vars/vars/` | `deployments/<domain>/vars/` |
| `/rhis/vars/files/` | `deployments/<domain>/files/` |
| `/rhis/vars/external_tasks/` | `deployments/<domain>/external_tasks/` |

**Launching**: Generated launcher scripts (e.g., `example.ca.25.sh`) call
`run_container.sh` with the appropriate mount flags (`-e`, `-f`, `-g`, `-h`,
`-i`, `-s`, `-t`, `-v` for each directory) and container image coordinates.

**Inside the container**: An operator runs individual build scripts
(`build_idm_primary.sh`, `build_sat_primary.sh`, etc.) which invoke
`ansible-playbook` with the mounted inventory. There is no single orchestration
script — each phase is run deliberately by the operator.

Default inventory path: `/rhis/vars/external_inventory/inventory`
Default user: `ansiblerunner`

---

## Configuration Architecture

### Variable Hierarchy

RHIS follows standard Ansible variable precedence. The key layers used:

- **Extra vars**: Passed via `-e` on the command line
- **Host vars**: Per-host configuration in `host_vars/<hostname>/`
- **Group vars**: Per-group configuration in `group_vars/<group>/`
- **Role defaults**: Default values in `roles/<role>/defaults/main.yml`

### Variable Naming Convention

Variables use **component-scoped prefixes**, not role-scoped:
- `satellite_` for Satellite configuration
- `idm_` for IdM configuration
- `kvm_` for KVM hypervisor configuration
- `platform_` for AAP platform configuration
- `aap_` for AAP installer variables

### Secrets Management

Secrets are managed via Ansible Vault with a naming convention:

```yaml
# vault file (encrypted)
aap_admin_password_vault: "<encrypted>"
aap_registry_username_vault: "<encrypted>"

# main vars (references vault)
platform_installer_config:
  aap_admin_password: "{{ aap_admin_password_vault }}"
  aap_registry_username: "{{ aap_registry_username_vault }}"
```

Vault files live in `deployments/<domain>/vault/` and are preserved when
`inventory_update.sh` regenerates the deployment. A sample vault file
is provided in `vault_SAMPLES/`.

### Deployment Generation

`inventory_update.sh` drives the rendering pipeline:
1. Reads `inventory_basevars.yml` (or domain-specific basevars)
2. Runs a containerized Ansible playbook (`inventory_update.yml`)
3. Renders all Jinja2 templates from `inventory_template/`
4. Produces the deployment directory with inventory, group_vars, host_vars,
   templates, scripts, and configuration files
5. Preserves the vault directory across regenerations

Per-domain basevars files (e.g., `example.ca_inventory_basevars.yml`,
`highside.example.ca_inventory_basevars.yml`) configure different deployments.

---

## Container Architecture

### Build Pipeline

```
Pre-build scan                Container build              Post-build scan
(ansible-lint, ClamAV)  →  (Containerfile + playbook)  →  (Grype, Trivy, Syft)
                                                                   │
                                                                   ▼
                                                         Policy enforcement
                                                         (fail on critical CVE)
                                                                   │
                                                                   ▼
                                                         cosign keyless signing
                                                         (Sigstore/Fulcio/Rekor)
                                                                   │
                                                                   ▼
                                                         SBOM + vulnerability attestation
                                                                   │
                                                                   ▼
                                                         Push to quay.io
```

**Build scripts**: `rhis_build_base.sh` (base image), `rhis_build_provisioner.sh` (provisioner layer)

**Scan configuration**: `scan_base_pre_build.yml`, `scan_base_post_build.yml`,
`scan_provisioner_pre_build.yml`, `scan_provisioner_post_build.yml`

**IaC scanning**: `scan_kics_iac.yml` for infrastructure-as-code analysis

**Accepted risks**: `scan_accepted_risks.yml` tracks CVEs with documented
rationale, fix-available tracking, and review-by dates. Reconciled automatically
from scan results.

**Build artifacts**: Single directory per build (`scan-reports/build-ubi{ver}-{timestamp}/`)
containing all scan reports, SBOMs, and logs.

**Base image verification**: Base image signatures are verified before
provisioner builds proceed.

### Air-Gap Transfer

```bash
# Connected environment: save the signed container
podman save quay.io/parmstro/rhis-provisioner:latest -o rhis-provisioner.tar

# Transfer via physical media (diode pattern)

# Disconnected environment: load and verify
podman load -i rhis-provisioner.tar
```

The provisioner container contains everything needed for deployment.
Inventory configuration is mounted from the host at runtime.

---

## Security Architecture

### Container Supply Chain

- **Pre-build**: ansible-lint (safety profile), ClamAV malware scan
- **Post-build**: Trivy vulnerability scan, Grype vulnerability scan, Syft SBOM generation
- **Signing**: cosign keyless signing via Sigstore (Fulcio certificates, Rekor transparency log)
- **Attestation**: SBOM attestation and vulnerability scan attestation attached to image
- **Policy**: Builds blocked on unaccepted critical/high CVEs
- **IaC scanning**: KICS for Ansible playbook security analysis

### Identity & Certificates

- IdM CA issues TLS certificates for all services
- `platform_node_pre` role generates per-host certificates via `ipa cert-request`
- Certificates stored at `/etc/ipa/private/<fqdn>/` on each host
- `certmonger` tracks renewal
- `custom_ca_cert` points at `/etc/ipa/ca.crt` for trust chain

### Encryption

- NBDE (Network Bound Disk Encryption) via Tang/Clevis for automated disk unlock
- Ansible Vault for secrets at rest
- TLS for all service communication

### Authentication

- Kerberos for service-to-service authentication
- YubiKey hardware tokens for 2FA via IdM
- Keycloak for application identity brokering (SAML/OAuth/OIDC)

### Compliance

- Token/credential cleanup is mandatory in container builds
- `ansible.cfg` is redacted at end of build
- No `pip install` — all Python dependencies via RHEL RPM packages

---

## Network Architecture

### DNS

**Primary DNS**: Red Hat Identity Management

- Forward zones for each environment domain
- Reverse zones with PTR records for all subnets
- Dynamic DNS: Satellite-provisioned hosts auto-register via realm integration
- External forwarders for internet resolution (connected environments)

### Lab Environments

| Environment | Subnet | Domain | Purpose |
|---|---|---|---|
| Primary Dev | 192.168.140.0/22 | example.ca | Development source of truth |
| Disconnected | 192.168.240.0/22 | highside.example.ca | Air-gapped testing, no internet |
| Production Demo | 192.168.252.0/22 | parmstrong.ca | Demo network with AD integration |

**Routing**: OPNsense router provides internet gateway, inter-subnet routing,
and DHCP per subnet. Connected environments (example.ca, parmstrong.ca) can
reach each other. Highside is isolated — content synced via diode pattern.

**Shared services** (192.168.252.0/22): 3 stratum 1 time servers accessible
from all subnets.

### IP Addressing Scheme

The inventory uses a band-based allocation scheme within each subnet:

| Band | Offsets | Purpose |
|---|---|---|
| 10-29 | IdM | Primary + replicas |
| 30-39 | Core services | Provisioner, Satellite, log server |
| 40-49 | Capsules | Satellite capsules |
| 50-59 | AAP Gateways | Gateway nodes |
| 60-69 | AAP Controllers | Controller + platform installer |
| 70-79 | AAP EDA | Event-Driven Ansible |
| 80-94 | VMware | vCenter + ESXi hosts |
| 100-109 | AAP Hubs | Automation Hub |
| 110-119 | AAP Databases | Dedicated database servers |
| 120-129 | Execution Nodes | AAP execution nodes |
| 130-139 | Hop Nodes | AAP hop nodes |
| 140-149 | KVM Hypervisors | Bare metal hypervisors |
| 150-159 | Quay | Container registry |
| 160-179 | Quadlet | Quadlet container hosts |

The .x0 address in each band is reserved for emergency use.

### Per-Environment Hardware

Each environment is a self-contained datacenter chassis:
- 14 NUC systems (7 VMware hypervisors + 7 bare metal)
- 3 backplane NUCs (provisioner + IdM primary + Satellite primary)
- VMware vCenter across the 7 hypervisor nodes
- Synology NAS on managed switch providing iSCSI storage for VMware
- Internal unmanaged switch + upstream managed switch

---

## Data Flow

### Provisioning Flow

```
Operator launches provisioner container
         │
         ▼
Container reads inventory from mounted volume
         │
         ▼
Operator runs build script (e.g., build_sat_primary.sh)
         │
         ▼
ansible-playbook targets the component (main.yml)
         │
         ▼
Satellite provisions host via compute resource
         │
         ▼
New host boots, runs kickstart, auto-enrolls in IdM
         │
         ▼
Configuration applied via Ansible from the provisioner container
(or later via AAP job templates)
```

### Identity Flow

```
Service request arrives
         │
         ▼
Service authenticates via IdM (Kerberos/LDAP)
         │
         ▼
IdM validates credentials (+ 2FA if configured)
         │
         ▼
Authorization checked (groups, HBAC, sudo rules)
         │
         ▼
Access granted or denied
```

---

## Scalability

### Horizontal Scaling

- **IdM**: Multi-master replicas for geographic distribution and redundancy
- **Satellite**: Capsules for remote sites (content caching, proxying, load distribution)
- **AAP**: Automation mesh with execution nodes and hop nodes for distributed capacity

### Topology Modes

RHIS supports multiple AAP topologies via inventory configuration:

- **Growth**: All AAP components on a single controller host (current lab topology)
- **Enterprise**: Dedicated hosts per component (gateway, controller, hub, EDA, database)

In growth mode, inventory groups (`aap_gateways`, `aap_hubs`, `aap_edacontroller`,
`aap_databases`) fall back to the controller host. In enterprise mode, each group
resolves to its own dedicated host. SSL certificate paths automatically adapt —
each component references its own inventory group.

---

## Disaster Recovery

### Backup Strategy

- **IdM**: `ipa-backup`, replica promotion capability
- **Satellite**: `satellite-maintain backup`, content on separate volumes
- **Configuration**: Git-tracked in `rhis-builder-inventory`, vault password secured separately
- **Containers**: Signed images in quay.io with SBOM attestation

### Recovery Strategy

- **IdM loss**: Restore from backup or promote replica to primary
- **Satellite loss**: Restore from backup; capsules continue operations temporarily
- **Complete site loss**: Rebuild from landing zone, restore configs from git, restore backups
- **Disconnected environment**: Drift report from connected agent drives diode sync content

---

## Future Roadmap

### In Progress

- **Autonomous agent**: Read-only monitoring agent on the provisioner detecting drift,
  build staleness, and configuration inconsistency across environments. Write-capable
  phase after trust is established through accurate reporting.
- **Log aggregation**: Loki + Grafana on a dedicated host via the quadlet deployment pattern,
  with rsyslog forwarding via system role.
- **KVM iSCSI storage**: Shared storage on Synology NAS for low-criticality VMs.

### Planned

- **Monorepo consolidation**: Consolidate `rhis-builder-*` repos into a single repository.
  ELISE upstream project for CentOS Stream/FreeIPA/Foreman/AWX community equivalent.
- **Deployment versioning**: Version per deployment (schema + inventory_update run count
  + timestamp), surfaced on Satellite/IdM splash pages.
- **Inventory tailoring**: Per-deployment overlays following the OpenSCAP tailoring model,
  with a Cockpit UI for SOE selection.
- **EE testing regime**: Smoke tests, rollback capability, and version tagging for
  Execution Environments (currently pulling latest with no gate).
- **CVE/errata monitoring**: CSAF VEX API for pre-rebuild CVE checks, authenticated
  Red Hat API + EDA for automated rebuild triggers.
- **Landing zone expansion**: Implementations for all Satellite-supported compute resources.

---

**Document Version**: 2.0
**Last Updated**: 2026-10-16
**Authors**: parmstro, Claude Opus 4.6
