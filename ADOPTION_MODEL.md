---
layout: default
title: RHIS Adoption Model
---

# Red Hat Infrastructure Standard Adoption Model (RHISAM)

**The process for designing, configuring, and implementing RHIS within an organization**

Last Updated: 2026-10-16

> Source: [rhisam](https://github.com/parmstro/rhisam) by Paul Armstrong
> and Mike Savage. This document consolidates the RHISAM content into the
> architecture documentation.

---

## RHIS Ecosystem Taxonomy

| Term | What It Is |
|------|-----------|
| **RHIS** (Red Hat Infrastructure Standard) | The thing that we build |
| **RHISAM** (Adoption Model) | The process to get to and use the thing we build |
| **rhis-builder-\*** | The toolset we use to build the thing |
| **rhis-provisioner-container** | How we deliver the toolset |

---

## What Is RHIS

The Red Hat Infrastructure Standard is a framework for using integrated
Red Hat technologies to build, manage, automate, optimize, and maintain
Red Hat Enterprise Linux at scale in a hybrid multicloud environment.

RHIS involves the deployment, configuration, and use of:

- **Red Hat Identity Management** — identity, DNS, certificates, Kerberos
- **Red Hat Satellite** — provisioning, content management, lifecycle
- **Red Hat Ansible Automation Platform** — automation, orchestration, CI/CD

RHIS leverages the [Red Hat Hybrid Cloud Console](https://console.redhat.com)
to deploy, patch, maintain, secure, automate, and ensure compliance of
Red Hat Enterprise Linux systems across a hybrid multicloud environment.

---

## What Is a Standard Operating Environment

A Standard Operating Environment (SOE) is a **model** for the **conditions**
under which we **control** our machines, systems, and processes.

Value is created for IT infrastructure when we define a short, discrete list
of SOEs that use selected tools designed to work together in well-defined
processes.

### Why SOEs Matter

- **SOEs enable automation.** Without an SOE, automation adds more work to
  creating a snowflake implementation.
- **With an SOE, standardization creates a path to sustainable automation.**
- The SOE allows delivery of proven design patterns in automation.
- Automation then evolves beyond configuration to systems generation and
  event-driven response.

---

## What Is the Adoption Model

The Red Hat Infrastructure Standard Adoption Model (RHISAM) is the process
customers use when designing, configuring, and implementing RHIS within
their organization.

### Fundamental Principles

1. **Everything-as-Code** — repeatability, consistency, and stability through
   GitOps practices
2. **Identity-First** — IdM as the foundational identity layer; all services
   integrate with it
3. **Satellite-Driven** — universal provisioner for all infrastructure after
   bootstrap
4. **Hermetic Delivery** — complete platform packaged in a signed, scannable
   container
5. **Configuration Separation** — same container, different deployments via
   inventory mounts

### GitOps Practices

GitOps practices define desired states and conduct tests on management
infrastructure and managed systems through an infrastructure-as-code
pipeline. The model delivers these capabilities for bare-metal, virtual,
and container host instances to:

- Increase service quality
- Reduce operator burden
- Scale to deliver the capacity necessary for modern business IT

### Cloud-Native Alignment

The most important outcome of the adoption model is positioning an
organization to take full advantage of cloud-native patterns across
datacenter and cloud footprint. The methodologies used in RHISAM dovetail
with methodologies for managing cloud-native architectures that leverage
container development platforms like Red Hat OpenShift.

Implementing RHISAM ensures alignment between traditional and cloud-native
services and eases application transitions.

---

## Adoption Phases

### Phase 1: Assessment

- Inventory existing infrastructure and tooling
- Identify Red Hat product entitlements
- Map current SOEs and gaps
- Select initial deployment platform (bare metal, KVM, cloud)

### Phase 2: Foundation

- Deploy IdM as identity foundation
- Deploy Satellite as universal provisioner
- Establish GitOps workflow for configuration management
- Create initial SOE definitions

### Phase 3: Automation

- Deploy Ansible Automation Platform
- Create job templates for infrastructure operations
- Integrate with Satellite for inventory and provisioning
- Implement CI/CD pipelines for infrastructure changes

### Phase 4: Expansion

- Deploy additional infrastructure services (NBDE, Keycloak, etc.)
- Extend to additional locations and compute resources
- Implement day-2 operations automation
- Integrate compliance scanning and remediation

### Phase 5: Optimization

- Implement event-driven automation (EDA)
- Automated CVE response and patching
- Drift detection and remediation
- Performance optimization and capacity planning

---

## Relationship to RHIS Tooling

The adoption model is platform-agnostic in principle but is implemented
through the rhis-builder toolset:

```
RHISAM (process)
  └── defines WHAT to build and WHY
      └── rhis-builder-inventory (configuration)
          └── defines HOW it is configured
              └── rhis-provisioner-container (execution)
                  └── delivers the automation
                      └── rhis-builder-* (components)
                          └── implement each service
```

The `rhis-builder-inventory` repository is the bridge between the adoption
model (organizational decisions about SOEs, platforms, and services) and
the toolset (automation that implements those decisions).

---

## Further Reading

- [Architecture Overview](ARCHITECTURE.md) — technical architecture of RHIS
- [Deployment Guide](DEPLOYMENT.md) — step-by-step deployment instructions
- [Repository Inventory](REPOSITORIES.md) — complete catalog of all components

---

**Document Version**: 2.0
**Last Updated**: 2026-10-16
**Original Authors**: Paul Armstrong, Mike Savage
