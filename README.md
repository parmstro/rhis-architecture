# RHIS Architecture

**Red Hat Infrastructure Standard — Central Architecture Documentation**

This repository is the central architecture documentation and reference for
RHIS (Red Hat Infrastructure Standard) — an enterprise infrastructure
deployment platform supporting bare metal, KVM, AWS, Azure, and more.

## What is RHIS?

RHIS is a standardized, automated infrastructure deployment platform:

- **Multi-Platform**: Bare metal, KVM, AWS, Azure today — every Satellite compute resource planned
- **Air-Gap Ready**: Hermetic container-based deployment for disconnected environments
- **Identity-First**: Integrated Red Hat Identity Management throughout
- **Complete Lifecycle**: Provision, configure, secure, upgrade, day-2 operations
- **Satellite-Driven**: Universal provisioning through Red Hat Satellite
- **Configuration as Code**: Single source of truth in rhis-builder-inventory

## Repository Structure

```
rhis-architecture/
├── README.md              # This file
├── index.md               # GitHub Pages landing page
├── ARCHITECTURE.md        # System architecture and design
├── REPOSITORIES.md        # Complete inventory of all 28 RHIS repos
├── DEPENDENCIES.md        # Inter-repository dependencies
├── DEPLOYMENT.md          # End-to-end deployment guide
├── ADOPTION_MODEL.md      # RHISAM adoption process
├── CONTRIBUTING.md        # Contribution guidelines
├── diagrams/              # Architecture diagrams (Mermaid)
└── reviews/               # Historical code review reports
```

## Quick Start

### Understanding the Architecture

1. [ARCHITECTURE.md](ARCHITECTURE.md) — system design and patterns
2. [REPOSITORIES.md](REPOSITORIES.md) — all 28 repositories with status
3. [DEPLOYMENT.md](DEPLOYMENT.md) — how to deploy RHIS
4. [DEPENDENCIES.md](DEPENDENCIES.md) — component relationships
5. [ADOPTION_MODEL.md](ADOPTION_MODEL.md) — organizational adoption process

### Deploying RHIS

```bash
# 1. Download (not clone) rhis-builder-inventory
wget https://github.com/parmstro/rhis-builder-inventory/archive/refs/heads/main.zip
unzip main.zip && mv rhis-builder-inventory-main rhis-builder-inventory
cd rhis-builder-inventory

# 2. Generate deployment configuration
cp inventory_basevars.yml example_ca_basevars.yml
vim example_ca_basevars.yml
./inventory_update.sh --basevars-file example_ca_basevars.yml

# 3. Configure secrets
cd deployments/example.ca/vault
cp ../../../vault_SAMPLES/rhis_builder_vault_SAMPLE.yml rhis_builder_vault.yml
vim rhis_builder_vault.yml
ansible-vault encrypt rhis_builder_vault.yml

# 4. Launch provisioner container
cd ../../..
./example.ca.25.sh

# 5. Inside container: deploy in order
#    Phase 1: Bootstrap (IdM primary, Satellite primary)
#    Phase 2: Register bootstrap hosts to Satellite
#    Phase 3: Validate compute resources
#    Phase 4: AAP
#    Phase 5: Infrastructure services (per location)
#    Phase 6: Workloads
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete instructions.

## Key Components

### Core Foundation
- [rhis-builder-inventory](https://github.com/parmstro/rhis-builder-inventory) — central configuration
- [rhis-provisioner-container](https://github.com/parmstro/rhis-provisioner-container) — hermetic execution environment

### Bootstrap Infrastructure (Deploy First)
1. **Landing Zones**: bootstrap-init (bare metal), kvm-lz, aws-lz, azure-lz
2. [rhis-builder-idm](https://github.com/parmstro/rhis-builder-idm) — Identity Management (auth, DNS, CA)
3. [rhis-builder-satellite](https://github.com/parmstro/rhis-builder-satellite) — universal provisioner

### Infrastructure Services
- **Security**: NBDE, Keycloak, YubiKey
- **Automation**: AAP, Pipelines
- **Infrastructure**: KVM, Quadlet/Quay, OCP
- **Lifecycle**: convert2rhel, imagebuilder, day-2-ops

## Project Status

- **Total Repositories**: 28
- **Implemented Platforms**: Bare metal, KVM, AWS, Azure
- **Planned Platforms**: VMware, GCP, Hyper-V, Proxmox, OpenStack, OCP Virt
- **Base OS**: RHEL 9.x, 10.x
- **Container Base**: RHEL UBI 9, UBI 10
- **ansible-lint Coverage**: 100% of Ansible repos

## Published Documentation

[parmstro.github.io/rhis-architecture](https://parmstro.github.io/rhis-architecture)

## License

See individual component repositories for licensing information.

---

**Last Updated**: 2026-10-16
**Author**: parmstro
