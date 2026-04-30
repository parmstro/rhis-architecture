# RHIS Architecture

**Red Hat Infrastructure Standard - Central Architecture Documentation**

This repository serves as the central architecture documentation and reference for the RHIS (Red Hat Infrastructure Standard) platform - a comprehensive enterprise infrastructure deployment system supporting multi-cloud and on-premise environments.

## What is RHIS?

RHIS is a standardized, automated infrastructure deployment platform that provides:

- 🌐 **Multi-Cloud Support**: AWS, Azure, GCP, KVM, Bare Metal
- 🔒 **Air-Gap Ready**: Hermetic container-based deployment for disconnected environments
- 🔐 **Identity-First**: Integrated Red Hat Identity Management throughout
- 📦 **Complete Lifecycle**: Provision → Configure → Secure → Upgrade → Day-2 Operations
- 🎯 **Satellite-Driven**: Universal provisioning through Red Hat Satellite
- ✅ **Production-Ready**: Battle-tested enterprise infrastructure patterns

## Repository Structure

```
rhis-architecture/
├── README.md              # This file
├── ARCHITECTURE.md        # Overall system architecture and design
├── REPOSITORIES.md        # Complete inventory of all RHIS components
├── DEPENDENCIES.md        # Inter-repository dependencies and relationships
├── DEPLOYMENT.md          # End-to-end deployment guide
├── CONTRIBUTING.md        # Contribution guidelines and standards
├── repos/                 # Per-repository analysis and documentation
│   ├── idm/
│   ├── satellite/
│   ├── nbde/
│   └── ...
├── diagrams/              # Architecture diagrams (Mermaid, PlantUML, etc.)
└── scripts/               # Utility scripts for analysis and automation
```

## Quick Start

### Understanding the Architecture

1. **Start here**: [ARCHITECTURE.md](ARCHITECTURE.md) - Overall system design
2. **Component inventory**: [REPOSITORIES.md](REPOSITORIES.md) - All 25+ repositories
3. **Deployment flow**: [DEPLOYMENT.md](DEPLOYMENT.md) - How to deploy RHIS
4. **Dependencies**: [DEPENDENCIES.md](DEPENDENCIES.md) - Component relationships

### Deploying RHIS

```bash
# 1. Download (not clone) rhis-builder-inventory
wget https://github.com/parmstro/rhis-builder-inventory/archive/refs/heads/main.zip
unzip main.zip && mv rhis-builder-inventory-main rhis-builder-inventory
cd rhis-builder-inventory

# 2. Generate deployment configuration for your domain
cp inventory_basevars.yml example_ca_basevars.yml
vim example_ca_basevars.yml  # Edit for your environment
./inventory_update.sh --basevars-file example_ca_basevars.yml

# 3. Configure secrets
cd deployments/example.ca/vault
cp ../../../vault_SAMPLES/rhis_builder_vault_SAMPLE.yml rhis_builder_vault.yml
vim rhis_builder_vault.yml  # Add your secrets
ansible-vault encrypt rhis_builder_vault.yml

# 4. Launch the rhis-provisioner container
cd ../../..  # Back to rhis-builder-inventory root
./example.ca.25.sh  # For AAP 2.5+

# 5. Inside container: Deploy infrastructure in order
# Phase 1: Landing Zone (creates minimal IdM and Satellite hosts)
# Phase 2: IdM Primary (authentication, DNS, CA) - FIRST SERVICE
# Phase 3: Satellite Primary (universal provisioner) - SECOND SERVICE  
# Phase 4: All other services (via Satellite)
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete instructions.

## Key Components

### Core Foundation
- **[rhis-builder-inventory](https://github.com/parmstro/rhis-builder-inventory)** - Central configuration repository
- **[rhis-provisioner-container](https://github.com/parmstro/rhis-provisioner-container)** - Unified execution environment

### Bootstrap Infrastructure (Deploy First)
1. **Landing Zones**: AWS, Azure, GCP, KVM, Bare Metal
2. **[rhis-builder-idm](https://github.com/parmstro/rhis-builder-idm)** - Identity Management (auth, DNS)
3. **[rhis-builder-satellite](https://github.com/parmstro/rhis-builder-satellite)** - Universal provisioner

### Infrastructure Services
- **Security**: NBDE, Keycloak, YubiKey, OSCAP
- **Automation**: Ansible Automation Platform, Pipelines
- **Lifecycle**: Convert2RHEL, Upgrades, ImageBuilder, Day-2 Ops

## Architecture Principles

### 1. Hermetic Deployment
All components bundled into `rhis-provisioner-container` for:
- Validation and signing of all components together
- Air-gap deployment to disconnected environments
- No external runtime dependencies
- Reproducible deployments

### 2. Identity-First
Red Hat Identity Management (IdM) provides:
- Central authentication and authorization
- DNS services for entire infrastructure
- Certificate authority
- All services integrate with IdM

### 3. Satellite-Driven Provisioning
After IdM deployment, Satellite becomes the universal provisioner:
- Hostgroups defined for each system type
- Compute resources for all platforms (KVM, VMware, AWS, Azure, GCP)
- Unified provisioning workflow
- All systems registered and managed

### 4. Configuration as Code
`rhis-builder-inventory` provides:
- Declarative infrastructure definitions
- Template-based deployment generation
- Centralized secrets management (Ansible Vault)
- Version-controlled configurations

## Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture design and patterns
- **[REPOSITORIES.md](REPOSITORIES.md)** - Complete component inventory (25+ repos)
- **[DEPENDENCIES.md](DEPENDENCIES.md)** - Dependency graph and relationships
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Step-by-step deployment guide
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development and contribution guidelines

## Project Status

- **Status**: Production-Ready
- **Total Repositories**: 25+
- **Supported Platforms**: AWS, Azure, GCP, KVM, Bare Metal
- **Base OS**: RHEL 8.x, RHEL 9.x
- **Container Base**: RHEL UBI 9
- **Ansible Version**: 2.9+

## Support & Community

- **Issues**: Report to individual component repositories
- **Discussions**: [GitHub Discussions](https://github.com/parmstro/rhis-architecture/discussions) (if enabled)
- **Author**: parmstro

## License

See individual component repositories for licensing information.

## Related Projects

- [Red Hat Identity Management](https://access.redhat.com/products/identity-management)
- [Red Hat Satellite](https://access.redhat.com/products/red-hat-satellite)
- [Ansible Automation Platform](https://www.redhat.com/en/technologies/management/ansible)

---

**Last Updated**: 2026-04-29  
**Maintained By**: parmstro
