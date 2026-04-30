---
layout: default
title: RHIS Architecture
description: >-
  Red Hat Infrastructure Standard - Multi-cloud enterprise infrastructure
  deployment platform with hermetic packaging, identity-first design, and
  complete lifecycle automation across AWS, Azure, GCP, KVM, and bare metal.
---

RHIS (Red Hat Infrastructure Standard) is a comprehensive enterprise
infrastructure deployment platform. It treats Red Hat Identity Management as
the foundational identity layer, Red Hat Satellite as the universal provisioner,
and packages the entire deployment stack into a hermetic container for
validation, signing, and air-gap deployment.

Current architecture version: `1.0`  
Total repositories: `25`

## Start Here

Pick the lane that matches your need:

<table>
  <thead>
    <tr>
      <th>Problem</th>
      <th>Start here</th>
      <th>Why this page first</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Understanding the complete system</td>
      <td><a href="ARCHITECTURE.html"><kbd>ARCHITECTURE OVERVIEW</kbd></a></td>
      <td>Explains design principles, layers, and integration patterns.</td>
    </tr>
    <tr>
      <td>Deploying RHIS from scratch</td>
      <td><a href="DEPLOYMENT.html"><kbd>DEPLOYMENT GUIDE</kbd></a></td>
      <td>Step-by-step deployment from landing zone through all services.</td>
    </tr>
    <tr>
      <td>Finding which repository does what</td>
      <td><a href="REPOSITORIES.html"><kbd>REPOSITORY INVENTORY</kbd></a></td>
      <td>Complete catalog of all 25 components with status and dependencies.</td>
    </tr>
    <tr>
      <td>Understanding component relationships</td>
      <td><a href="DEPENDENCIES.html"><kbd>DEPENDENCY GRAPH</kbd></a></td>
      <td>Shows deploy order, integration points, and critical path.</td>
    </tr>
    <tr>
      <td>Contributing code or improvements</td>
      <td><a href="CONTRIBUTING.html"><kbd>CONTRIBUTING GUIDE</kbd></a></td>
      <td>Standards, workflow, and testing requirements.</td>
    </tr>
    <tr>
      <td>Visual architecture overview</td>
      <td><a href="diagrams/"><kbd>ARCHITECTURE DIAGRAMS</kbd></a></td>
      <td>Five detailed Mermaid diagrams showing flows and relationships.</td>
    </tr>
  </tbody>
</table>

## How The Docs Work

The documentation follows a layered approach:

- **Architecture** pages for system design, patterns, and technical decisions
- **Repository** pages for component inventory and capabilities
- **Deployment** pages for operational procedures and workflows
- **Diagram** pages for visual representations and data flows

This separation keeps reference material precise while providing operational
guidance and architectural context separately.

## Core Deployment Flow

The critical deployment path that must be followed in order:

| Phase | Component | Purpose | Duration |
| --- | --- | --- | --- |
| 0 | Preparation | Generate config, set up credentials, obtain subscriptions | 1-4 hours |
| 1 | Landing Zone | Create minimal RHEL 9 hosts for IdM and Satellite | 15-30 min |
| 2 | IdM Primary | Deploy identity, DNS, CA, Kerberos - **FIRST SERVICE** | 15-30 min |
| 3 | Satellite | Deploy universal provisioner - **SECOND SERVICE** | 30-60 min |
| 4+ | Services | Deploy all other infrastructure (can parallelize) | 10-20 min each |

After Satellite is deployed, all other services provision in parallel through Satellite.

## Platform Support

RHIS deploys across five platform types with unified workflow:

<table>
  <thead>
    <tr>
      <th>Platform</th>
      <th>Landing Zone Repo</th>
      <th>Status</th>
      <th>Use When</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>AWS</td>
      <td><a href="https://github.com/parmstro/rhis-builder-aws-lz">rhis-builder-aws-lz</a></td>
      <td>✅ Active</td>
      <td>Deploying to Amazon Web Services</td>
    </tr>
    <tr>
      <td>Azure</td>
      <td><a href="https://github.com/parmstro/rhis-builder-azure-lz">rhis-builder-azure-lz</a></td>
      <td>✅ Active</td>
      <td>Deploying to Microsoft Azure</td>
    </tr>
    <tr>
      <td>GCP</td>
      <td><a href="https://github.com/parmstro/rhis-builder-google-lz">rhis-builder-google-lz</a></td>
      <td>✅ Active</td>
      <td>Deploying to Google Cloud Platform</td>
    </tr>
    <tr>
      <td>KVM</td>
      <td><a href="https://github.com/parmstro/rhis-builder-kvm-lz">rhis-builder-kvm-lz</a></td>
      <td>✅ Active</td>
      <td>On-premise libvirt/KVM hypervisors</td>
    </tr>
    <tr>
      <td>Bare Metal</td>
      <td><a href="https://github.com/parmstro/rhis-builder-baremetal-init">rhis-builder-baremetal-init</a></td>
      <td>✅ Active</td>
      <td>Physical servers with IPMI/BMC</td>
    </tr>
  </tbody>
</table>

## Repository Categories

All 25 RHIS repositories organized by function:

<table>
  <thead>
    <tr>
      <th>Category</th>
      <th>Count</th>
      <th>Purpose</th>
      <th>Documentation</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Core Foundation</td>
      <td>2</td>
      <td>Configuration repository and execution container</td>
      <td><a href="REPOSITORIES.html#core-foundation-2-repositories">Details</a></td>
    </tr>
    <tr>
      <td>Landing Zones</td>
      <td>5</td>
      <td>Bootstrap minimal RHEL hosts on each platform</td>
      <td><a href="REPOSITORIES.html#landing-zones-5-repositories">Details</a></td>
    </tr>
    <tr>
      <td>Bootstrap Infrastructure</td>
      <td>6</td>
      <td>IdM and Satellite deployment (deploy FIRST)</td>
      <td><a href="REPOSITORIES.html#core-infrastructure-services-6-repositories">Details</a></td>
    </tr>
    <tr>
      <td>Automation Platform</td>
      <td>3</td>
      <td>AAP deployment and operational pipelines</td>
      <td><a href="REPOSITORIES.html#automation-platform-3-repositories">Details</a></td>
    </tr>
    <tr>
      <td>Security & Identity</td>
      <td>4</td>
      <td>NBDE, Keycloak, YubiKey, OSCAP</td>
      <td><a href="REPOSITORIES.html#security--identity-4-repositories">Details</a></td>
    </tr>
    <tr>
      <td>Lifecycle Management</td>
      <td>4</td>
      <td>Convert2RHEL, upgrades, imaging, day-2 ops</td>
      <td><a href="REPOSITORIES.html#lifecycle-management-4-repositories">Details</a></td>
    </tr>
    <tr>
      <td>Development Tools</td>
      <td>3</td>
      <td>Templates and utilities for new components</td>
      <td><a href="REPOSITORIES.html#development-tools--templates-3-repositories">Details</a></td>
    </tr>
  </tbody>
</table>

## Key Architecture Patterns

### Identity-First Design

Red Hat IdM is deployed **first** and provides:

- Central authentication (Kerberos, LDAP)
- DNS services for entire infrastructure
- Certificate authority (PKI)
- Authorization and policy

All subsequent services integrate with IdM for identity.

### Satellite-Driven Provisioning

After IdM, Satellite is deployed **second** and becomes the universal provisioner:

- Provisions all infrastructure via hostgroups
- Manages content (RPMs, containers)
- Handles subscription lifecycle
- Integrates with IdM for automated enrollment

### Hermetic Container Packaging

The `rhis-provisioner-container` bundles all 25 repositories for:

- Validation and signing of complete stack
- Air-gap deployment to disconnected environments
- Reproducible deployments (no runtime fetches)
- Version-locked component sets

### Configuration as Code

`rhis-builder-inventory` serves as single source of truth:

- Declarative infrastructure definitions
- Template-based deployment generation
- Ansible Vault for secrets
- Version-controlled configurations

## Architecture Diagrams

Five detailed Mermaid diagrams showing system architecture and flows:

<table>
  <thead>
    <tr>
      <th>Diagram</th>
      <th>Shows</th>
      <th>Use For</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="diagrams/01-high-level-architecture.html">High-Level Architecture</a></td>
      <td>Complete platform layers and component relationships</td>
      <td>Understanding overall system design</td>
    </tr>
    <tr>
      <td><a href="diagrams/02-deployment-flow.html">Deployment Flow</a></td>
      <td>Step-by-step deployment sequence with timeline</td>
      <td>Planning and executing deployments</td>
    </tr>
    <tr>
      <td><a href="diagrams/03-dependency-graph.html">Dependency Graph</a></td>
      <td>All 25 repositories with deploy order</td>
      <td>Understanding component relationships</td>
    </tr>
    <tr>
      <td><a href="diagrams/04-container-architecture.html">Container Architecture</a></td>
      <td>Hermetic packaging and layer breakdown</td>
      <td>Understanding air-gap deployment</td>
    </tr>
    <tr>
      <td><a href="diagrams/05-integration-dataflow.html">Integration & Data Flow</a></td>
      <td>Service integrations and communication patterns</td>
      <td>Understanding how services interact</td>
    </tr>
  </tbody>
</table>

## When RHIS Fits Best

RHIS delivers strongest value when:

- IdM will be the identity source of truth
- Satellite will manage the infrastructure lifecycle
- Multi-cloud or hybrid deployment is needed
- Air-gap capability is required
- Standardized, reproducible deployments are critical
- Complete platform lifecycle automation is desired

## Getting Started

1. **Plan**: Review [Architecture](ARCHITECTURE.html) and choose your [platform](DEPLOYMENT.html#phase-1-landing-zone)
2. **Prepare**: Set up credentials, obtain subscriptions, generate [configuration](DEPLOYMENT.html#phase-0-preparation)
3. **Deploy**: Follow [deployment guide](DEPLOYMENT.html) in order: Landing Zone → IdM → Satellite → Services
4. **Validate**: Verify each phase before proceeding to next
5. **Operate**: Use [day-2 operations](https://github.com/parmstro/rhis-builder-day-2-ops) for ongoing management

## Community

- **Issues**: [Report issues](https://github.com/parmstro/rhis-architecture/issues) in appropriate repository
- **Contributing**: Follow [contribution guidelines](CONTRIBUTING.html)
- **Author**: parmstro
- **License**: GPL-3.0 (see individual repositories)

---

**Current Documentation Version**: 1.0  
**Last Updated**: 2026-04-29  
**Platform Status**: Production-Ready
