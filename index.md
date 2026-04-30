---
layout: default
title: RHIS Architecture Documentation
---

# RHIS Architecture Documentation

**Red Hat Infrastructure Standard - Central Architecture Documentation**

Welcome to the RHIS architecture documentation. This site provides comprehensive documentation for the RHIS platform - a standardized, automated infrastructure deployment system supporting multi-cloud and on-premise environments.

---

## 📚 Documentation

### Core Documentation

<div class="doc-grid">

#### [Architecture Overview](ARCHITECTURE.md)
Complete system architecture, design principles, and patterns
- Multi-layer architecture
- Identity-first design
- Hermetic deployment
- Security architecture

#### [Repository Inventory](REPOSITORIES.md)
Detailed inventory of all 25 RHIS components
- Component descriptions
- Technology stack
- Status and maturity
- Documentation coverage

#### [Deployment Guide](DEPLOYMENT.md)
End-to-end deployment instructions
- Prerequisites
- Phase-by-phase deployment
- Validation procedures
- Troubleshooting

#### [Dependencies](DEPENDENCIES.md)
Component relationships and integration points
- Dependency graph
- Deploy order
- External dependencies
- Critical path

#### [Contributing](CONTRIBUTING.md)
Development standards and contribution workflow
- Code standards
- Testing requirements
- Review process
- Community guidelines

</div>

---

## 🎨 Architecture Diagrams

Visual representations of the RHIS platform:

- **[High-Level Architecture](diagrams/01-high-level-architecture.md)** - Complete platform overview
- **[Deployment Flow](diagrams/02-deployment-flow.md)** - Step-by-step deployment sequence
- **[Dependency Graph](diagrams/03-dependency-graph.md)** - Repository dependencies
- **[Container Architecture](diagrams/04-container-architecture.md)** - Hermetic packaging
- **[Integration & Data Flow](diagrams/05-integration-dataflow.md)** - Service integrations

[View all diagrams →](diagrams/)

---

## 🚀 Quick Start

### For New Users

1. **Understand the Architecture**
   - Read [Architecture Overview](ARCHITECTURE.md)
   - Review [High-Level Diagram](diagrams/01-high-level-architecture.md)

2. **Plan Your Deployment**
   - Review [Repository Inventory](REPOSITORIES.md)
   - Check [Deployment Guide](DEPLOYMENT.md) prerequisites

3. **Deploy RHIS**
   - Follow [Deployment Guide](DEPLOYMENT.md)
   - Start with landing zone → IdM → Satellite

### For Contributors

1. **Review Standards**
   - Read [Contributing Guidelines](CONTRIBUTING.md)
   - Understand [Dependencies](DEPENDENCIES.md)

2. **Set Up Development Environment**
   - Clone component repository
   - Install ansible-lint, yamllint
   - Review best practices

3. **Make Your Contribution**
   - Create feature branch
   - Follow naming conventions
   - Submit pull request

---

## 🏗️ Platform Overview

### What is RHIS?

RHIS is a comprehensive enterprise infrastructure deployment platform that provides:

- 🌐 **Multi-Cloud Support**: AWS, Azure, GCP, KVM, Bare Metal
- 🔒 **Air-Gap Ready**: Hermetic container-based deployment for disconnected environments
- 🔐 **Identity-First**: Integrated Red Hat Identity Management throughout
- 📦 **Complete Lifecycle**: Provision → Configure → Secure → Upgrade → Day-2 Operations
- 🎯 **Satellite-Driven**: Universal provisioning through Red Hat Satellite
- ✅ **Production-Ready**: Battle-tested enterprise infrastructure patterns

### Components

**25+ repositories** organized into:

- **Landing Zones** (5): AWS, Azure, GCP, KVM, Bare Metal
- **Core Services** (6): IdM, Satellite, Templates
- **Automation** (3): AAP, Pipelines, Provisioner
- **Security** (4): NBDE, Keycloak, YubiKey, OSCAP
- **Lifecycle** (4): Convert2RHEL, Upgrades, ImageBuilder, Day-2 Ops
- **Dev Tools** (3): Templates and utilities

### Key Features

#### Identity-First Architecture
Red Hat Identity Management provides centralized authentication, DNS, and certificates for the entire platform.

#### Satellite-Driven Provisioning
After IdM deployment, Satellite becomes the universal provisioner for all infrastructure across clouds and on-premise.

#### Hermetic Packaging
All components bundled into `rhis-provisioner-container` for validation, signing, and air-gap deployment.

#### Configuration as Code
`rhis-builder-inventory` provides declarative infrastructure definitions with template-based deployment generation.

---

## 📊 Architecture Layers

```
┌─────────────────────────────────────────┐
│  Application Infrastructure             │
│  (Customer workloads)                   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  Infrastructure Services                │
│  (AAP, Keycloak, NBDE, OSCAP)          │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  Universal Provisioner (Satellite)      │
│  (Compute resources, Hostgroups)        │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  Identity & DNS (IdM)                   │
│  (Auth, DNS, CA, Kerberos)             │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  Compute Platform (Landing Zone)        │
│  (AWS, Azure, GCP, KVM, Bare Metal)    │
└─────────────────────────────────────────┘
```

---

## 🔗 Links

- **GitHub Repository**: [parmstro/rhis-architecture](https://github.com/parmstro/rhis-architecture)
- **Component Repositories**: See [Repository Inventory](REPOSITORIES.md)
- **Issues**: [Report issues](https://github.com/parmstro/rhis-architecture/issues)
- **Discussions**: [GitHub Discussions](https://github.com/parmstro/rhis-architecture/discussions)

---

## 📝 Recent Updates

- **2026-04-29**: Initial release of architecture documentation
- **2026-04-29**: Added comprehensive architecture diagrams
- **2026-04-29**: Created deployment guide and repository inventory

---

## 📞 Support

For questions or issues:
- Review the [Documentation](README.md)
- Check [Deployment Guide](DEPLOYMENT.md) troubleshooting section
- Open an [issue](https://github.com/parmstro/rhis-architecture/issues)

---

<style>
.doc-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  margin: 2rem 0;
}

.doc-grid h4 {
  color: #0366d6;
  margin-top: 0;
}
</style>

**Last Updated**: 2026-04-29  
**Maintained By**: parmstro
