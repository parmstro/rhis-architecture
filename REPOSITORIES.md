---
layout: default
title: RHIS Repository Inventory
---

# RHIS Repository Inventory

**Complete inventory of all RHIS (Red Hat Infrastructure Standard) repositories**

Last Updated: 2026-10-16

---

## Repository Summary

| Category | Count | Notes |
|----------|-------|-------|
| Core Foundation | 2 | Inventory + provisioner container |
| Landing Zones | 4 | 3 cloud/hypervisor + 1 bare metal |
| Core Infrastructure | 3 | IdM, Satellite, Satellite templates |
| Automation Platform | 2 | AAP, pipelines |
| Infrastructure Services | 7 | NBDE, Keycloak, YubiKey, Quay, Quadlet, KVM, OCP |
| Lifecycle Management | 3 | convert2rhel, imagebuilder, day-2-ops |
| Supporting | 6 | EE testbed, vault sample, UI, maintenance, architecture, MCP |
| Adoption Model | 1 | RHISAM |
| **Total** | **28** | |

---

## Core Foundation

### rhis-builder-inventory

- **GitHub**: [parmstro/rhis-builder-inventory](https://github.com/parmstro/rhis-builder-inventory)
- **Purpose**: Single source of truth for all infrastructure configuration
- **Status**: Active
- **Dependencies**: None (keystone repository)
- **Roles**: 0 (configuration data, not automation)
- **In container**: Yes (cloned at build time)
- **Key components**:
  - `inventory_template/` — source-of-truth templates (group_vars, host_vars, Jinja2 templates)
  - `inventory_update.sh` — renders per-deployment configurations
  - `deployments/` — generated output (never edited directly)
  - Band-based IP addressing scheme
  - Installer inventory templates (growth, enterprise topologies)
- **Documentation**: README.md, .ansible-lint

### rhis-provisioner-container

- **GitHub**: [parmstro/rhis-provisioner-container](https://github.com/parmstro/rhis-provisioner-container)
- **Purpose**: Hermetic container aggregating all RHIS components for deployment
- **Status**: Active
- **Dependencies**: All rhis-builder-* repos (cloned at build time via `configure_rhis_builder.yml`)
- **Roles**: 0 (build scripts and playbooks)
- **In container**: This IS the container
- **Key components**:
  - `rhis-base/` — UBI 9/10 base image with Ansible, collections, scanning tools
  - `rhis-provisioner/` — layered image with all repos, build scripts, deploy scripts
  - `rhis_build_base.sh`, `rhis_build_provisioner.sh` — container build scripts
  - Scanning pipeline: Grype, Trivy, ClamAV, Syft, cosign, KICS
  - `scan_accepted_risks.yml` — CVE accepted risk tracking
  - `validate_collection_compatibility.yml` — collection version analysis
- **Build pipeline**: pre-build scan → build → post-build scan → sign → attest → push to quay.io
- **Documentation**: README.md, .ansible-lint

---

## Landing Zones

Landing zones create minimal RHEL hosts for IdM and Satellite bootstrap.
A landing zone may perform introspection (discover existing infrastructure),
build (create using certified Ansible collections), or both.

The goal is to support every compute resource Red Hat Satellite manages.

### Implemented

#### rhis-builder-bootstrap-init

- **GitHub**: [parmstro/rhis-builder-bootstrap-init](https://github.com/parmstro/rhis-builder-bootstrap-init)
- **Purpose**: Bare metal initialization — kickstart and OEMDRV generation
- **Status**: Active
- **Roles**: 1
- **In container**: Yes
- **Documentation**: CLAUDE.md, README.md, .ansible-lint

#### rhis-builder-kvm-lz

- **GitHub**: [parmstro/rhis-builder-kvm-lz](https://github.com/parmstro/rhis-builder-kvm-lz)
- **Purpose**: Bootstrap RHIS landing zone on KVM/libvirt
- **Location**: `~/landing_zones/rhis-builder-kvm-lz`
- **Status**: Active
- **In container**: Yes
- **Documentation**: CLAUDE.md, README.md, .ansible-lint

#### rhis-builder-aws-lz

- **GitHub**: [parmstro/rhis-builder-aws-lz](https://github.com/parmstro/rhis-builder-aws-lz)
- **Purpose**: Bootstrap RHIS landing zone in AWS
- **Location**: `~/landing_zones/rhis-builder-aws-lz`
- **Status**: Active (currently commented out of container build)
- **In container**: No (commented out in `configure_rhis_builder.yml`)
- **Documentation**: README.md

#### rhis-builder-azure-lz

- **GitHub**: [parmstro/rhis-builder-azure-lz](https://github.com/parmstro/rhis-builder-azure-lz)
- **Purpose**: Bootstrap RHIS landing zone in Azure
- **Location**: `~/landing_zones/rhis-builder-azure-lz`
- **Status**: Active
- **In container**: Yes
- **Documentation**: README.md

### Planned Landing Zones

Target platforms matching Satellite compute resource support:

| Platform | Status |
|----------|--------|
| Bare metal | Implemented (`bootstrap-init`) |
| KVM / libvirt | Implemented (`kvm-lz`) |
| AWS | Implemented (`aws-lz`, not in container build) |
| Azure | Implemented (`azure-lz`) |
| VMware | Planned |
| GCP | Planned |
| Hyper-V | Planned |
| Proxmox | Planned |
| OpenStack | Planned |
| OpenShift Virtualization | Planned |
| Azure Local | Planned |

---

## Core Infrastructure Services

Deployed first, in order. These bootstrap the platform.

### rhis-builder-idm (Deploy 1st)

- **GitHub**: [parmstro/rhis-builder-idm](https://github.com/parmstro/rhis-builder-idm)
- **Purpose**: Deploy and configure Red Hat Identity Management
- **Status**: Active
- **Deploy order**: 1st — all other services depend on IdM
- **Roles**: 18
- **In container**: Yes
- **Build scripts**: `build_idm_primary.sh`, `build_idm_replicas.sh`
- **Key features**:
  - Integrated CA for platform-wide TLS certificates
  - DNS (forward and reverse zones with dynamic updates)
  - Kerberos realm
  - User, group, host group management
  - Sudo rules and HBAC policies
  - Active Directory trust relationships
- **Collections**: `redhat.rhel_idm`
- **Documentation**: CLAUDE.md, README.md, .ansible-lint

### rhis-builder-satellite (Deploy 2nd)

- **GitHub**: [parmstro/rhis-builder-satellite](https://github.com/parmstro/rhis-builder-satellite)
- **Purpose**: Deploy and configure Red Hat Satellite as universal provisioner
- **Status**: Active
- **Deploy order**: 2nd — after IdM, before everything else
- **Roles**: 56
- **In container**: Yes
- **Build scripts**: `build_sat_primary.sh`, `build_sat_1_capsules_satellite_pre.sh`, `build_sat_2_capsules.sh`, `build_sat_3_capsules_satellite_post.sh`, `build_sat_disconnected_export.sh`, `build_sat_disconnected_import.sh`
- **Key features**:
  - IdM client with realm integration (`foreman-prepare-realm`)
  - HTTP service principal and IdM CA certificates
  - Compute resources for all supported platforms
  - Compute profiles and hostgroups
  - Content views and lifecycle environments
  - Provisioning templates via GitOps
  - `pulp_container_optimization` role for container sync performance
- **Collections**: `redhat.satellite`
- **Documentation**: README.md, .ansible-lint

### rhis-builder-satellite-templates

- **GitHub**: [parmstro/rhis-builder-satellite-templates](https://github.com/parmstro/rhis-builder-satellite-templates)
- **Purpose**: GitOps for Satellite provisioning templates (kickstart, cloud-init, etc.)
- **Status**: Active
- **In container**: Not in container (Satellite syncs from git directly)
- **Key features**:
  - Template synchronization with Satellite via `foreman_templates` plugin
  - ERB provisioning templates
- **Documentation**: README.md, .ansible-lint

---

## Automation Platform

### rhis-builder-aap

- **GitHub**: [parmstro/rhis-builder-aap](https://github.com/parmstro/rhis-builder-aap)
- **Purpose**: Deploy and configure Ansible Automation Platform
- **Status**: Active
- **Roles**: 5 (`platform`, `platform_node_pre`, `platform_post`, `hub_post`, `standalone_hub`)
- **In container**: Yes
- **Build scripts**: `build_aap_controller.sh`, `build_aap_standalone_hub.sh`, `build_aap24_controller.sh`, `build_aap24_hub.sh`
- **Key features**:
  - Container and RPM deployment types
  - Growth and enterprise topologies
  - IdM certificate integration (per-node certs via `platform_node_pre`)
  - Certificate distribution to installer node (`fetch_node_crts.yml`)
  - Installer inventory template generation
  - Post-install: job templates, credentials, EE configuration, manifest upload
  - Gateway as unified API entry point (`aap_gateway_host` variable)
- **Collections**: `ansible.controller`, `infra.ah_configuration`
- **Documentation**: README.md, .ansible-lint

### rhis-builder-pipelines

- **GitHub**: [parmstro/rhis-builder-pipelines](https://github.com/parmstro/rhis-builder-pipelines)
- **Purpose**: Operational automation workflows, test content, and CI/CD pipelines
- **Status**: Active
- **Roles**: 4 (plus test content roles)
- **In container**: Yes
- **Key features**:
  - Node builder roles for Satellite-driven provisioning
  - VMware operations automation
  - Satellite operations automation
  - Northwind test application deployment content
  - Uses roles from `rhis-builder-day-2-ops`
- **Documentation**: README.md, .ansible-lint

---

## Infrastructure Services

### rhis-builder-nbde

- **GitHub**: [parmstro/rhis-builder-nbde](https://github.com/parmstro/rhis-builder-nbde)
- **Purpose**: Network Bound Disk Encryption (Tang servers + Clevis clients)
- **Status**: Active
- **Roles**: 1 (`tang_container`)
- **In container**: Yes
- **Key features**:
  - Tang servers in Podman containers with systemd integration
  - Clevis client configuration for automated disk unlock at boot
  - Firewall and SELinux configuration
  - Deployment verification via encrypt/decrypt test
- **Collections**: `containers.podman`, `rhel-system-roles.nbde_client`
- **Documentation**: README.md, .ansible-lint

### rhis-builder-keycloak

- **GitHub**: [parmstro/rhis-builder-keycloak](https://github.com/parmstro/rhis-builder-keycloak)
- **Purpose**: Deploy Keycloak identity broker
- **Status**: Active
- **Roles**: 2
- **In container**: Yes
- **Key features**:
  - Standalone and containerized deployment options
  - SAML/OAuth/OIDC identity brokering
  - Integration with IdM
- **Documentation**: README.md, .ansible-lint

### rhis-builder-yubi

- **GitHub**: [parmstro/rhis-builder-yubi](https://github.com/parmstro/rhis-builder-yubi)
- **Purpose**: YubiKey hardware token integration with IdM
- **Status**: Active
- **Roles**: 2
- **In container**: Yes
- **Playbooks**: `initialize_yubikey.yml`, `enable_idm_smartcard_server.yml`, `enable_idm_smartcard_client.yml`
- **Key features**:
  - YubiKey enrollment in IdM
  - Smart card authentication for IdM server and clients
  - Hardware token 2FA for privileged access
- **Documentation**: README.md, .ansible-lint

### rhis-builder-quay

- **GitHub**: [parmstro/rhis-builder-quay](https://github.com/parmstro/rhis-builder-quay)
- **Purpose**: Deploy Quay container registry via quadlet pattern
- **Status**: Active
- **Roles**: 1
- **In container**: Yes
- **Key features**:
  - Quadlet container deployment on dedicated host
  - Canonical example of the quadlet deploy pattern
- **Documentation**: README.md, .ansible-lint

### rhis-builder-quadlet-deploy

- **GitHub**: [parmstro/rhis-builder-quadlet-deploy](https://github.com/parmstro/rhis-builder-quadlet-deploy)
- **Purpose**: Generic quadlet container deployment pattern
- **Status**: Active
- **Roles**: 1
- **In container**: Yes
- **Build script**: `build_quadlets.sh`
- **Key features**:
  - Deploys containerized services via systemd quadlet
  - Used for Quay, log aggregation, and other container workloads
  - Dedicated host + quadlet containers per service model
- **Documentation**: README.md, .ansible-lint

### rhis-builder-kvm

- **GitHub**: [parmstro/rhis-builder-kvm](https://github.com/parmstro/rhis-builder-kvm)
- **Purpose**: KVM hypervisor provisioning and configuration
- **Status**: Active (feature/kvm-iscsi-lvmlock branch)
- **Roles**: 7
- **In container**: Yes
- **Build script**: `build_kvm_hosts.sh`
- **Key features**:
  - KVM hypervisor setup and configuration
  - iSCSI shared storage on Synology NAS (in progress)
  - LVM lock for shared storage coordination
- **Documentation**: README.md, .ansible-lint

### rhis-builder-ocp-certs

- **GitHub**: [parmstro/rhis-builder-ocp-certs](https://github.com/parmstro/rhis-builder-ocp-certs)
- **Purpose**: IdM wildcard certificates for OpenShift Container Platform
- **Status**: Active
- **In container**: Yes
- **Key features**:
  - Automated wildcard SSL/TLS certificate deployment from IdM
  - Certificate management for OCP clusters
- **Documentation**: README.md, .ansible-lint

### rhis-builder-ocp-upi

- **GitHub**: [parmstro/rhis-builder-ocp-upi](https://github.com/parmstro/rhis-builder-ocp-upi)
- **Purpose**: OpenShift Container Platform UPI deployment with virtualization
- **Status**: Active
- **In container**: Yes
- **Documentation**: README.md, .ansible-lint

---

## Lifecycle Management

### rhis-builder-convert2rhel

- **GitHub**: [parmstro/rhis-builder-convert2rhel](https://github.com/parmstro/rhis-builder-convert2rhel)
- **Purpose**: Convert CentOS/Oracle Linux to RHEL
- **Status**: Active
- **Roles**: 13
- **In container**: Yes
- **Key features**:
  - Pre-conversion analysis
  - Automated conversion orchestration via AAP
  - Integration with Satellite for subscription management
- **Documentation**: README.md, .ansible-lint

### rhis-builder-imagebuilder

- **GitHub**: [parmstro/rhis-builder-imagebuilder](https://github.com/parmstro/rhis-builder-imagebuilder)
- **Purpose**: On-premise image building with Satellite
- **Status**: Active
- **Roles**: 1
- **In container**: Yes
- **Key features**:
  - Custom RHEL image builds via Image Builder (composer)
  - Multiple output formats (qcow2, vmdk, vhd, AMI, etc.)
  - Blueprint management
- **Documentation**: README.md, .ansible-lint

### rhis-builder-day-2-ops

- **GitHub**: [parmstro/rhis-builder-day-2-ops](https://github.com/parmstro/rhis-builder-day-2-ops)
- **Purpose**: Day-2 operations automation
- **Status**: Active
- **Roles**: 12
- **In container**: Yes
- **Key features**:
  - Patching and updates
  - Operational task automation
  - Roles consumed by `rhis-builder-pipelines`
- **Documentation**: README.md, .ansible-lint

---

## Supporting Repositories

### rhis-builder-ansible-ee

- **GitHub**: [parmstro/rhis-builder-ansible-ee](https://github.com/parmstro/rhis-builder-ansible-ee)
- **Purpose**: Standalone Execution Environment build testbed
- **Status**: Active (development/testing only)
- **In container**: Yes
- **Note**: NOT the production EE build source. Production EE definitions live in
  `rhis-builder-inventory/inventory_templates/` and are rendered during the AAP build process.
- **Documentation**: .ansible-lint

### rhis-builder-vault-SAMPLE

- **GitHub**: [parmstro/rhis-builder-vault-SAMPLE](https://github.com/parmstro/rhis-builder-vault-SAMPLE)
- **Purpose**: Sample vault files showing required secrets structure
- **Status**: Active (reference material)
- **Documentation**: README.md, .ansible-lint

### rhis-builder-ui

- **GitHub**: [parmstro/rhis-builder-ui](https://github.com/parmstro/rhis-builder-ui)
- **Purpose**: Web UI for RHIS
- **Status**: In development
- **Components**: `backend/`, `frontend/`, `Containerfile`
- **Documentation**: .ansible-lint

### rhis-builder

- **GitHub**: [parmstro/rhis-builder](https://github.com/parmstro/rhis-builder)
- **Purpose**: Course content and instructional material for the rhis-builder project
- **Status**: Active (educational content)
- **Note**: Not an automation repo — contains guided experience content
- **Documentation**: README.md

### rhis-maintenance

- **Purpose**: Collection usage audit and maintenance scripts
- **Status**: Active (tooling)
- **Components**: `audit_collection_usage.py`, `audit_collection_usage.sh`, `cache_collection_docs.py`

### rhis-mcp-server

- **GitHub**: [parmstro/rhis-mcp-server](https://github.com/parmstro/rhis-mcp-server) (private)
- **Purpose**: MCP server and knowledge base for the autonomous monitoring agent
- **Status**: In development
- **Components**: `knowledge/{architecture,operations,troubleshooting}/`, confidence schema
- **Documentation**: README.md

### rhis-architecture

- **GitHub**: [parmstro/rhis-architecture](https://github.com/parmstro/rhis-architecture)
- **Purpose**: Architecture documentation, diagrams, and review reports
- **Status**: Active (this repository)
- **Published**: [parmstro.github.io/rhis-architecture](https://parmstro.github.io/rhis-architecture)

### rhisam

- **GitHub**: [parmstro/rhisam](https://github.com/parmstro/rhisam)
- **Purpose**: Red Hat Infrastructure Standard Adoption Model documentation
- **Status**: Early stage
- **Authors**: Paul Armstrong, Mike Savage
- **Documentation**: AsciiDoc format, GitHub Pages via AsciiDoctor

---

## Repos Baked into the Provisioner Container

The following 20 repos are cloned into the container at build time via
`configure_rhis_builder.yml` (using `ansible.builtin.git`):

| Repository | Branch |
|---|---|
| rhis-builder-idm | main |
| rhis-builder-satellite | main |
| rhis-builder-pipelines | main |
| rhis-builder-aap | main |
| rhis-builder-day-2-ops | main |
| rhis-builder-nbde | main |
| rhis-builder-imagebuilder | main |
| rhis-builder-yubi | main |
| rhis-builder-convert2rhel | main |
| rhis-builder-ansible-ee | main |
| rhis-builder-quadlet-deploy | main |
| rhis-builder-kvm | feature/kvm-iscsi-lvmlock |
| rhis-builder-bootstrap-init | main |
| rhis-builder-azure-lz | main |
| rhis-builder-keycloak | main |
| rhis-builder-kvm-lz | main |
| rhis-builder-ocp-certs | main |
| rhis-builder-ocp-upi | main |
| rhis-builder-quay | main |
| rhis-builder-inventory | (mounted at runtime, not baked) |

`rhis-builder-aws-lz` is currently commented out of the build.

`rhis-builder-inventory` is mounted at runtime from the host, not cloned at
build time — this allows different deployments to use different configurations
with the same container image.

---

## Code Quality Status

### ansible-lint Coverage

21 of 21 Ansible-based repos have `.ansible-lint` configuration (100%).

All repos use the RHIS standard `.ansible-lint` configuration with production profile.

### CLAUDE.md Coverage

| Repository | Has CLAUDE.md |
|---|---|
| Workspace root | Yes |
| rhis-builder-bootstrap-init | Yes |
| rhis-builder-idm | Yes |
| rhis-builder-kvm-lz | Yes (in ~/landing_zones/) |
| All others | No |

### Argument Specifications

No repos currently have `argument_specs.yml` files.

---

## Technology Stack

### Platforms Supported

- **Implemented**: Bare metal, KVM/libvirt, AWS, Azure
- **Planned**: VMware, GCP, Hyper-V, Proxmox, OpenStack, OpenShift Virtualization

### Core Technologies

- **Automation**: ansible-core >= 2.14, Ansible Automation Platform 2.6
- **Identity**: Red Hat Identity Management, Kerberos, LDAP
- **Provisioning**: Red Hat Satellite 6.18
- **Containers**: Podman, RHEL UBI 9/10
- **Security**: NBDE (Tang/Clevis), Keycloak, YubiKey
- **Scanning**: Grype, Trivy, ClamAV, Syft, cosign, KICS
- **Configuration**: Ansible Vault, Git

### Ansible Collections Used

- `redhat.rhel_idm`
- `redhat.satellite`
- `redhat.rhel_system_roles`
- `containers.podman`
- `ansible.posix`
- `ansible.utils`
- `community.general`
- `ansible.controller`
- `infra.ah_configuration`
- `amazon.aws` (AWS landing zone)
- `azure.azcollection` (Azure landing zone)

---

**Document Version**: 2.0
**Last Updated**: 2026-10-16
**Authors**: parmstro, Claude Opus 4.6
