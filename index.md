---
layout: default
title: RHIS Architecture
description: >-
  Red Hat Infrastructure Standard - Enterprise infrastructure deployment
  platform with hermetic packaging, identity-first design, and complete
  lifecycle automation across bare metal, KVM, AWS, Azure, and more.
---

<div class="project-eyebrow">Red Hat Infrastructure Standard Documentation</div>

# RHIS Architecture

<div class="project-tagline">Enterprise infrastructure deployment platform with hermetic packaging, identity-first design, and lifecycle automation.</div>

The Red Hat Infrastructure Standard (RHIS) is an enterprise infrastructure
deployment platform. It treats Red Hat Identity Management as the foundational
identity layer, Red Hat Satellite as the universal provisioner, and Red Hat
Ansible Automation Platform as the universal automation layer, packaging the
entire deployment stack into a hermetic container for validation, signing, and
air-gap deployment. RHIS integrates your Red Hat products into an integrated
solution to deliver on the promise of Open Hybrid Cloud.

Current architecture version: `2.0`  
Total repositories: `28`

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
      <td>Complete catalog of all 28 repositories with status and dependencies.</td>
    </tr>
    <tr>
      <td>Understanding component relationships</td>
      <td><a href="DEPENDENCIES.html"><kbd>DEPENDENCY GRAPH</kbd></a></td>
      <td>Shows deploy order, integration points, and critical path.</td>
    </tr>
    <tr>
      <td>Adopting RHIS in your organization</td>
      <td><a href="ADOPTION_MODEL.html"><kbd>ADOPTION MODEL</kbd></a></td>
      <td>SOE principles, adoption phases, and organizational alignment.</td>
    </tr>
    <tr>
      <td>Contributing code or improvements</td>
      <td><a href="CONTRIBUTING.html"><kbd>CONTRIBUTING GUIDE</kbd></a></td>
      <td>Standards, workflow, and testing requirements.</td>
    </tr>
    <tr>
      <td>Visual architecture overview</td>
      <td><a href="diagrams/"><kbd>ARCHITECTURE DIAGRAMS</kbd></a></td>
      <td>Mermaid diagrams showing flows and relationships.</td>
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
| 1 | Bootstrap | Create provisioner, IdM primary, Satellite primary | Varies |
| 2 | Registration | Register IdM and provisioner to Satellite | 15-30 min |
| 3 | Validation | Test compute resources, verify provisioning | 30-60 min |
| 4 | AAP | Deploy and configure Ansible Automation Platform | 30-60 min |
| 5 | Infrastructure | IdM replicas, security services, capsules (per location) | 10-20 min each |
| 6 | Workloads | Application deployments via AAP job templates | Varies |

Satellite synchronization time depends on selected content, hardware, and
network bandwidth. It can range from 30 minutes on a high-spec server with
fast storage and 100Gb networking, to 10+ hours on a NUC with 1Gb connection.

## Platform Support

RHIS targets every compute resource Red Hat Satellite supports. Current
implementation status:

<table>
  <thead>
    <tr>
      <th>Platform</th>
      <th>Landing Zone Repo</th>
      <th>Status</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Bare Metal</td>
      <td><a href="https://github.com/parmstro/rhis-builder-bootstrap-init">rhis-builder-bootstrap-init</a></td>
      <td>Active</td>
    </tr>
    <tr>
      <td>KVM / libvirt</td>
      <td><a href="https://github.com/parmstro/rhis-builder-kvm-lz">rhis-builder-kvm-lz</a></td>
      <td>Active</td>
    </tr>
    <tr>
      <td>AWS</td>
      <td><a href="https://github.com/parmstro/rhis-builder-aws-lz">rhis-builder-aws-lz</a></td>
      <td>Active (not in container build)</td>
    </tr>
    <tr>
      <td>Azure</td>
      <td><a href="https://github.com/parmstro/rhis-builder-azure-lz">rhis-builder-azure-lz</a></td>
      <td>Active</td>
    </tr>
    <tr>
      <td>VMware, GCP, Hyper-V, Proxmox, OpenStack, OCP Virt, Azure Local</td>
      <td>—</td>
      <td>Planned</td>
    </tr>
  </tbody>
</table>

## Repository Categories

All 28 RHIS repositories organized by function:

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
      <td><a href="REPOSITORIES.html#core-foundation">Details</a></td>
    </tr>
    <tr>
      <td>Landing Zones</td>
      <td>4</td>
      <td>Bootstrap minimal RHEL hosts (3 cloud/hypervisor + 1 bare metal)</td>
      <td><a href="REPOSITORIES.html#landing-zones">Details</a></td>
    </tr>
    <tr>
      <td>Core Infrastructure</td>
      <td>3</td>
      <td>IdM, Satellite, Satellite templates</td>
      <td><a href="REPOSITORIES.html#core-infrastructure-services">Details</a></td>
    </tr>
    <tr>
      <td>Automation Platform</td>
      <td>2</td>
      <td>AAP deployment and operational pipelines</td>
      <td><a href="REPOSITORIES.html#automation-platform">Details</a></td>
    </tr>
    <tr>
      <td>Infrastructure Services</td>
      <td>7</td>
      <td>NBDE, Keycloak, YubiKey, Quay, Quadlet, KVM, OCP</td>
      <td><a href="REPOSITORIES.html#infrastructure-services">Details</a></td>
    </tr>
    <tr>
      <td>Lifecycle Management</td>
      <td>3</td>
      <td>convert2rhel, imagebuilder, day-2-ops</td>
      <td><a href="REPOSITORIES.html#lifecycle-management">Details</a></td>
    </tr>
    <tr>
      <td>Supporting</td>
      <td>6</td>
      <td>EE testbed, vault sample, UI, maintenance, architecture, MCP</td>
      <td><a href="REPOSITORIES.html#supporting-repositories">Details</a></td>
    </tr>
    <tr>
      <td>Adoption Model</td>
      <td>1</td>
      <td>RHISAM adoption model documentation</td>
      <td><a href="REPOSITORIES.html#rhisam">Details</a></td>
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

- Complete configuration of all Satellite components
- Installation and certificate creation
- Manifest creation and installation
- Content selection including custom content
- Standard Operating Environment (SOE) definition, including:
  - Content Lifecycle, views, publication and promotion
  - Activation key and system purpose definition
  - Hostgroup definition
  - Provisioning configuration for any compute resource
  - Discovery configuration and rule generation
  - Compliance role import and SCAP scanning configuration
- Infrastructure Management and Network assignment
- Integrates with IdM for automated enrollment

### Hermetic Container Packaging

The `rhis-provisioner-container` bundles all repositories for:

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
- Air-gapped deployment pulls together content, container, and configuration export

## Architecture Diagrams

Mermaid diagrams showing system architecture and flows:

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
      <td>Step-by-step deployment sequence</td>
      <td>Planning and executing deployments</td>
    </tr>
    <tr>
      <td><a href="diagrams/03-dependency-graph.html">Dependency Graph</a></td>
      <td>All repositories with deploy order</td>
      <td>Understanding component relationships</td>
    </tr>
    <tr>
      <td><a href="diagrams/04-container-architecture.html">Container Architecture</a></td>
      <td>Hermetic packaging and layer breakdown</td>
      <td>Understanding air-gap deployment</td>
    </tr>
    <tr>
      <td><a href="diagrams/05-integration-dataflow.html">Integration and Data Flow</a></td>
      <td>Service integrations and communication patterns</td>
      <td>Understanding how services interact</td>
    </tr>
  </tbody>
</table>

## When RHIS Fits Best

RHIS delivers strongest value when:

- IdM will be the identity source of truth
- Satellite will manage the infrastructure lifecycle
- Ansible Automation Platform delivers workflow/pipeline automation
- Multi-cloud or hybrid deployment is needed
- Air-gap capability is required
- Standardized, reproducible deployments are critical
- Complete platform lifecycle automation is desired

## Getting Started

1. **Plan**: Review [Architecture](ARCHITECTURE.html) and choose your platform
2. **Prepare**: Set up credentials, obtain subscriptions, generate [configuration](DEPLOYMENT.html#quick-start)
3. **Deploy**: Follow [deployment guide](DEPLOYMENT.html) in order
4. **Validate**: Verify each phase before proceeding to next
5. **Operate**: Use [day-2 operations](https://github.com/parmstro/rhis-builder-day-2-ops) for ongoing management

## Community

- **Issues**: [Report issues](https://github.com/parmstro/rhis-architecture/issues) in appropriate repository
- **Contributing**: Follow [contribution guidelines](CONTRIBUTING.html)
- **Author**: parmstro
- **License**: GPL-3.0 (see individual repositories)

---

**Current Documentation Version**: 2.0  
**Last Updated**: 2026-10-16
