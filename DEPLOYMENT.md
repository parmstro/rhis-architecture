---
layout: default
title: RHIS Deployment Guide
---

# RHIS Deployment Guide

**End-to-end deployment guide for Red Hat Infrastructure Standard**

Last Updated: 2026-10-16

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Sequence](#deployment-sequence)
- [Phase 1: Bootstrap](#phase-1-bootstrap)
- [Phase 2: Registration](#phase-2-registration)
- [Phase 3: Validation](#phase-3-validation)
- [Phase 4: AAP](#phase-4-aap)
- [Phase 5: Infrastructure Services](#phase-5-infrastructure-services)
- [Phase 6: Workloads](#phase-6-workloads)
- [Disconnected Environments](#disconnected-environments)
- [Helper Script Reference](#helper-script-reference)

---

## Prerequisites

### Required Access

- Red Hat Customer Portal account
- Red Hat subscriptions for:
  - RHEL (enough for all systems)
  - Satellite
  - Ansible Automation Platform
- Cloud credentials (if using a cloud landing zone):
  - AWS: IAM user with EC2/VPC permissions
  - Azure: Service principal

### Required Systems

Minimum three hosts for initial bootstrap:

| System | RAM | Disk | Cores | Purpose |
|--------|-----|------|-------|---------|
| Provisioner | 16 GB | 256 GB | 2 | Runs the RHIS container |
| IdM Primary | 16 GB | 256 GB | 2 | Identity, DNS, CA |
| Satellite Primary | 32 GB | 1 TB (fast) | 4 | Content, provisioning |

For disconnected Satellite, allocate 3x the space of your library export.

You can provision these manually or use a landing zone project:
- `rhis-builder-bootstrap-init` for bare metal (recommended for POC/lab)
- `rhis-builder-kvm-lz` for KVM/libvirt
- `rhis-builder-azure-lz` for Azure
- `rhis-builder-aws-lz` for AWS

### Required Tools

On the provisioner host:

- git
- podman
- SSH client
- Text editor (VS Code with Remote SSH recommended)

### Network Requirements

- DNS domain you control (e.g., `example.ca`)
- IP address range with sufficient space for all hosts
- RHIS uses a band-based IP addressing scheme within your subnet
- Firewall rules for IdM, Satellite, and AAP services

---

## Quick Start

### 1. Get the inventory repository

Download as ZIP and re-initialize — do NOT clone. Your configuration will contain
environment-specific settings and should be version-controlled independently.

```bash
wget https://github.com/parmstro/rhis-builder-inventory/archive/refs/heads/main.zip
unzip main.zip
mv rhis-builder-inventory-main rhis-builder-inventory
cd rhis-builder-inventory
git init -b main
git add . --all
git commit -m "Initial commit"
git remote add origin https://github.com/<your_org>/rhis-builder-inventory.git
git push -u origin main
```

### 2. Configure and generate your deployment

Edit `inventory_basevars.yml` or create a copy for your domain, then run `inventory_update.sh`.

```bash
cp inventory_basevars.yml example_ca_basevars.yml
vim example_ca_basevars.yml
./inventory_update.sh --basevars-file example_ca_basevars.yml
```

This runs a containerized Ansible playbook that generates a complete deployment
configuration in `deployments/<yourdomain>/`.

### 3. Review the generated deployment

```bash
ls deployments/example.ca/
# external_tasks/   - Custom tasks to extend RHIS
# files/            - Files for playbook consumption (OSCAP content, etc.)
# group_vars/       - Group-level Ansible variables
# host_vars/        - Host-specific Ansible variables
# inventory/        - Ansible inventory file
# templates/        - Jinja2 templates for Satellite provisioning
# vars/             - Additional variable files
# vault/            - Ansible vault files (empty, populate manually)
```

**Configuration philosophy**:
- For testing: modify files directly in `deployments/<yourdomain>/`
- For production GitOps: edit templates in `inventory_template/` to ensure
  changes persist across regenerations
- `inventory_update.sh` regenerates everything **except** the `vault/` directory

### 4. Create vault secrets

The `vault/` directory is never touched by regeneration. Copy the sample vault
file and populate your secrets:

```bash
cd deployments/example.ca/vault
cp ../../../vault_SAMPLES/rhis_builder_vault_SAMPLE.yml rhis_builder_vault.yml
vim rhis_builder_vault.yml
ansible-vault encrypt rhis_builder_vault.yml
```

The vault file contains sections for: landing zone credentials, registry
credentials, IdM passwords, Satellite settings, AAP configuration, and
infrastructure service credentials.

### 5. Launch the provisioner container

```bash
# Ensure latest container images
./update_containers.sh

# Launch (use the .25.sh script for AAP 2.5+)
./example.ca.25.sh
```

The container mounts your deployment at `/rhis/vars/` and provides all RHIS
automation at `/rhis/rhis-builder-*/`. You get a shell prompt inside the container.

### 6. Deploy in order

Inside the container, follow the deployment sequence below.

---

## Deployment Sequence

RHIS deployment follows a strict dependency-driven order. Each layer must be
operational before the next can provision against it.

```
Phase 1: Bootstrap
  └─ Provisioner → IdM Primary → Satellite Primary

Phase 2: Registration
  └─ Register IdM and provisioner to Satellite

Phase 3: Validation
  └─ Test compute resources → destroy test machines

Phase 4: AAP
  └─ Deploy AAP hosts via Satellite → build AAP controller

Phase 5: Infrastructure (location by location)
  └─ IdM replicas → security infrastructure → Satellite capsules → AAP nodes

Phase 6: Workloads
  └─ Application deployments via AAP job templates
```

Each phase is repeated until perfect. Rework resets to the start of the
affected phase.

---

## Phase 1: Bootstrap

The bootstrap phase creates the three foundational systems. For bare metal,
use `rhis-builder-bootstrap-init` to generate kickstart and OEMDRV USB drives.

### IdM Primary

Inside the container:

```bash
cd /rhis/rhis-builder-idm
./build_idm_primary.sh
```

This runs `main.yml` against the `idm_primary` host limit. It installs IdM
with integrated CA, DNS, and Kerberos. All subsequent services integrate
with IdM for identity, DNS, and TLS certificates.

**Duration**: ~15-30 minutes

**Verification**:
```bash
ssh root@idm1.example.ca
kinit admin
ipactl status        # All services should show RUNNING
ipa user-find        # Verify user directory
```

### Satellite Primary

```bash
cd /rhis/rhis-builder-satellite
./build_sat_primary.sh
```

This runs `main.yml` against the `sat_primary` host limit. Satellite is
installed as an IdM client with realm integration, HTTP service principal,
and IdM CA certificates. The build configures content views, lifecycle
environments, activation keys, hostgroups, and compute resources.

**Duration**: 30 minutes to several hours (content sync is the variable)

**Verification**:
```bash
ssh root@satellite1.example.ca
hammer ping          # All services should respond
hammer realm list    # Should show your IdM realm
```

---

## Phase 2: Registration

Register the IdM primary and provisioner to Satellite for content management
and patching.

---

## Phase 3: Validation

Test bare metal and VM compute resource functionality:
- Deploy test hosts via Satellite
- Verify IdM enrollment, DNS registration, content access
- Destroy test machines

Use `deploy_rhel9_test_hosts.sh` and `deploy_rhel10_test_hosts.sh` from
`/rhis/rhis-builder-pipelines/` to provision test hosts through Satellite.

---

## Phase 4: AAP

### Deploy AAP Hosts

AAP hosts are provisioned via Satellite using the deploy script:

```bash
cd /rhis/rhis-builder-pipelines
./deploy_aap_hosts.sh
```

This uses `rhis_build_from_provisioner.yml` to have Satellite create the AAP
hosts from the `aap_hosts` configuration variable.

### Build AAP Controller

Once hosts are provisioned and registered:

```bash
cd /rhis/rhis-builder-aap
./build_aap_controller.sh
```

This runs `main.yml` which:
1. Runs `platform_node_pre` — creates IdM HTTP service principals and requests
   TLS certificates for each AAP node
2. Runs `platform` — distributes certificates to the installer node, generates
   the installer inventory from templates, launches the AAP installer
3. Runs `platform_post` — configures job templates, credentials, EE settings,
   uploads the AAP manifest

RHIS supports both growth topology (all-in-one on a single controller) and
enterprise topology (dedicated gateway, hub, EDA, database hosts). The
inventory template system automatically generates the correct installer
inventory for either topology.

### Build Standalone Hub (optional)

```bash
cd /rhis/rhis-builder-aap
./build_aap_standalone_hub.sh
```

---

## Phase 5: Infrastructure Services

Deploy location by location. Each location gets its own local services before
dependent workloads arrive.

### IdM Replicas

```bash
# Deploy replica hosts via Satellite
cd /rhis/rhis-builder-pipelines
./deploy_idm_replica_hosts.sh

# Build replicas
cd /rhis/rhis-builder-idm
./build_idm_replicas.sh
```

### Security Infrastructure

**NBDE (Tang servers)** — Network Bound Disk Encryption:
```bash
cd /rhis/rhis-builder-pipelines
./deploy_quadlet_hosts.sh

cd /rhis/rhis-builder-quadlet-deploy
./build_quadlets.sh
```

### Satellite Capsules

Multi-stage capsule deployment:
```bash
# Deploy capsule hosts
cd /rhis/rhis-builder-pipelines
./deploy_sat_capsule_hosts.sh

# Stage 1: Prepare Satellite for capsules
cd /rhis/rhis-builder-satellite
./build_sat_1_capsules_satellite_pre.sh

# Stage 2: Install capsule software
./build_sat_2_capsules.sh

# Stage 3: Configure content replication to capsules
./build_sat_3_capsules_satellite_post.sh
```

### KVM Hypervisors

```bash
cd /rhis/rhis-builder-pipelines
./deploy_kvm_hypervisors.sh

cd /rhis/rhis-builder-kvm
./build_kvm_hosts.sh
```

---

## Phase 6: Workloads

Application deployments run through AAP job templates configured in Phase 4.
The `rhis-builder-pipelines` repo contains operational automation and test
content (e.g., Northwind application deployment).

---

## Disconnected Environments

RHIS supports air-gapped environments via the diode pattern:

### Connected Side — Export

```bash
cd /rhis/rhis-builder-satellite
./build_sat_disconnected_export.sh
```

Exports Satellite content (repos, content views, errata) to transferable media.

### Disconnected Side — Import

```bash
cd /rhis/rhis-builder-satellite
./build_sat_disconnected_import.sh
```

Imports content on the disconnected Satellite. The connected Satellite must be
built first — the disconnected Satellite needs the exported content.

---

## Helper Script Reference

All helper scripts accept these parameters:

| Flag | Default | Purpose |
|------|---------|---------|
| `-u`, `--sshuser` | `ansiblerunner` | SSH user for playbook execution |
| `-i`, `--inventory` | `/rhis/vars/external_inventory/inventory` | Inventory path |
| `-h`, `--help` | — | Print usage |

You will be prompted for SSH password and vault password.

### Build Scripts (configure software)

Located in each component's directory inside the container:

| Script | Container Path | Limit |
|--------|---------------|-------|
| `build_idm_primary.sh` | `/rhis/rhis-builder-idm/` | `idm_primary` |
| `build_idm_replicas.sh` | `/rhis/rhis-builder-idm/` | `idm_replicas` |
| `build_sat_primary.sh` | `/rhis/rhis-builder-satellite/` | `sat_primary` |
| `build_sat_1_capsules_satellite_pre.sh` | `/rhis/rhis-builder-satellite/` | — |
| `build_sat_2_capsules.sh` | `/rhis/rhis-builder-satellite/` | — |
| `build_sat_3_capsules_satellite_post.sh` | `/rhis/rhis-builder-satellite/` | — |
| `build_sat_disconnected_export.sh` | `/rhis/rhis-builder-satellite/` | — |
| `build_sat_disconnected_import.sh` | `/rhis/rhis-builder-satellite/` | — |
| `build_aap_controller.sh` | `/rhis/rhis-builder-aap/` | — |
| `build_aap_standalone_hub.sh` | `/rhis/rhis-builder-aap/` | — |
| `build_kvm_hosts.sh` | `/rhis/rhis-builder-kvm/` | — |
| `build_quadlets.sh` | `/rhis/rhis-builder-quadlet-deploy/` | — |

### Deploy Scripts (provision hosts via Satellite)

All located in `/rhis/rhis-builder-pipelines/`:

| Script | Provisions |
|--------|-----------|
| `deploy_aap_hosts.sh` | AAP controller/hub/EDA hosts |
| `deploy_idm_replica_hosts.sh` | IdM replica servers |
| `deploy_kvm_hypervisors.sh` | KVM hypervisor hosts |
| `deploy_quadlet_hosts.sh` | Container service hosts |
| `deploy_sat_capsule_hosts.sh` | Satellite capsule hosts |
| `deploy_rhel8_test_hosts.sh` | RHEL 8 test hosts |
| `deploy_rhel9_test_hosts.sh` | RHEL 9 test hosts |
| `deploy_rhel10_test_hosts.sh` | RHEL 10 test hosts |

Deploy scripts use `rhis_build_from_provisioner.yml` to have Satellite
create hosts based on hostgroup definitions.

### Run Scripts (ad-hoc role/task execution)

Each major component has three helper scripts for targeted execution:

| Pattern | Purpose | Example |
|---------|---------|---------|
| `run_<component>_role.sh` | Run a single role | `run_satellite_role.sh` |
| `run_<component>_role_task.sh` | Run a specific task within a role | `run_satellite_role_task.sh` |
| `run_<component>_task.sh` | Run a standalone task file | `run_satellite_task.sh` |

Available for: `satellite`, `idm`, `aap`

---

**Document Version**: 2.0
**Last Updated**: 2026-10-16
**Authors**: parmstro, Claude Opus 4.6
