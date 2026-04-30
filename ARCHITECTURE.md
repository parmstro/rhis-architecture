# RHIS Architecture

**Red Hat Infrastructure Standard - System Architecture**

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

---

## Overview

RHIS is a comprehensive enterprise infrastructure deployment platform designed for multi-cloud and on-premise deployments with air-gap capability. The architecture follows a layered approach with strong separation of concerns and identity-first design.

### Key Characteristics

- **Hermetic Packaging**: All components bundled for validation and air-gap deployment
- **Identity-Driven**: IdM integration throughout the stack
- **Declarative**: Configuration as code via rhis-builder-inventory
- **Multi-Cloud Native**: Abstracts cloud and on-premise differences
- **Lifecycle Aware**: Covers provision, configure, secure, upgrade, and day-2 operations

---

## Design Principles

### 1. Hermetic Deployment

**Principle**: All dependencies must be packaged within the deployment container.

**Rationale**:
- Enable validation and signing of complete stack
- Support air-gap (disconnected) environments
- Ensure reproducible deployments
- Eliminate runtime external dependencies

**Implementation**:
- `rhis-provisioner-container` clones all component repos at build time
- All binary, Python, and Ansible dependencies baked into base image
- No runtime fetching of code or dependencies

### 2. Identity-First Architecture

**Principle**: Red Hat Identity Management is the first service deployed and all components integrate with it.

**Rationale**:
- Central authentication and authorization
- Unified DNS management
- Certificate authority for TLS/SSL
- Kerberos for secure service communication
- LDAP for user/group management

**Implementation**:
- IdM deployed immediately after landing zone
- Satellite registered as IdM client with realm integration
- All subsequent services use IdM for identity

### 3. Configuration as Code

**Principle**: All infrastructure defined declaratively in version-controlled configuration.

**Rationale**:
- Reproducible deployments
- Audit trail for changes
- Template-based customization
- Environment-specific overrides

**Implementation**:
- `rhis-builder-inventory` as single source of truth
- Ansible variable hierarchy (group_vars, host_vars)
- Template-based deployment generation
- Vault-encrypted secrets

### 4. Satellite-Driven Provisioning

**Principle**: After bootstrap, Satellite provisions all infrastructure.

**Rationale**:
- Unified provisioning workflow
- Multi-platform support (KVM, VMware, clouds)
- Lifecycle management integration
- Content management (RPMs, containers)

**Implementation**:
- Hostgroups for each system type
- Compute resources for all platforms
- Provisioning templates in git (GitOps)
- Integration with IdM for automated enrollment

---

## Architecture Layers

```
┌────────────────────────────────────────────────────────────┐
│  Layer 5: Application Infrastructure                      │
│  Customer workloads, applications                          │
└────────────────┬───────────────────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────────────────┐
│  Layer 4: Infrastructure Services                          │
│  AAP, Keycloak, NBDE, ImageBuilder, OSCAP, YubiKey        │
└────────────────┬───────────────────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────────────────┐
│  Layer 3: Universal Provisioner (Satellite)                │
│  - Compute resources (KVM, VMware, AWS, Azure, GCP)       │
│  - Hostgroups for all system types                        │
│  - Content management                                      │
│  - Lifecycle management                                    │
└────────────────┬───────────────────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────────────────┐
│  Layer 2: Identity & DNS (IdM)                            │
│  - Authentication & Authorization                          │
│  - DNS (forward & reverse zones)                          │
│  - Certificate Authority                                   │
│  - Kerberos realm                                         │
└────────────────┬───────────────────────────────────────────┘
                 │
┌────────────────▼───────────────────────────────────────────┐
│  Layer 1: Compute Platform (Landing Zone)                 │
│  AWS, Azure, GCP, KVM, Bare Metal                         │
│  Minimal RHEL 9 hosts for IdM + Satellite                 │
└────────────────────────────────────────────────────────────┘
```

---

## Deployment Flow

### Phase 0: Landing Zone Preparation

**Goal**: Create minimal RHEL 9 environment for IdM and Satellite bootstrap.

**Repositories**:
- `rhis-builder-aws-lz`
- `rhis-builder-azure-lz`
- `rhis-builder-google-lz`
- `rhis-builder-kvm-lz`
- `rhis-builder-baremetal-init`

**Outputs**:
- Minimal RHEL 9 host for IdM primary server
- Minimal RHEL 9 host for Satellite primary server
- Network configuration (VPC/subnet in cloud, VLAN on-prem)
- Initial connectivity and access

### Phase 1: Bootstrap Infrastructure

**Goal**: Deploy foundational identity and provisioning services.

#### Step 1: Deploy IdM Primary

**Repository**: `rhis-builder-idm`

**Actions**:
1. Install IdM server with integrated CA
2. Configure DNS zones (forward and reverse)
3. Create sample users, groups, host groups
4. Configure sudo rules and commands
5. Establish Active Directory trusts (if required)
6. Enable dynamic DNS updates

**Outputs**:
- Functional IdM server providing auth, authz, DNS
- Kerberos realm established
- DNS zones configured
- Initial users and groups created

#### Step 2: Deploy Satellite Primary

**Repository**: `rhis-builder-satellite`

**Actions**:
1. Install Satellite server
2. Register as IdM client
3. Run `foreman-prepare-realm` to create `realm-capsule` user
4. Create HTTP service principal in IdM
5. Generate and install Satellite certificates from IdM CA
6. Configure compute resources (KVM, VMware, AWS, Azure, GCP)
7. Create compute profiles (small, medium, large)
8. Define hostgroups for each rhis-builder-* system type
9. Import provisioning templates from git
10. Configure content views and lifecycle environments

**Outputs**:
- Functional Satellite server integrated with IdM
- Compute resources configured for all platforms
- Hostgroups ready for infrastructure provisioning
- Satellite can provision all other infrastructure

### Phase 2: Infrastructure Services

**Goal**: Deploy operational infrastructure services via Satellite.

**Provisioning Method**: All systems provisioned through Satellite using appropriate hostgroups.

**Components**:
- **Automation**: AAP (Ansible Automation Platform)
- **Security**: NBDE (Tang servers), Keycloak, YubiKey, OSCAP
- **Operations**: ImageBuilder, Day-2 Ops tooling
- **Lifecycle**: Convert2RHEL, RHEL Upgrade automation

**Process**:
1. Select appropriate hostgroup in Satellite
2. Define compute resource and profile
3. Provision via Satellite
4. System auto-enrolls in IdM
5. Configuration applied via Ansible (from AAP or direct)

### Phase 3: Application Infrastructure

**Goal**: Provision customer workloads and applications.

**Method**: Same Satellite-driven workflow with customer-defined hostgroups.

---

## Component Architecture

### rhis-builder-inventory (Configuration Repository)

**Purpose**: Single source of truth for all infrastructure configuration.

**Structure**:
```
rhis-builder-inventory/
├── inventory_template/           # Templates for new deployments
│   ├── group_vars/               # Template group variables
│   ├── host_vars/                # Template host variables
│   └── templates/                # Jinja2 templates
├── inventory_basevars.yml        # Default base variables file
├── inventory_update.sh           # Script to generate deployment config
├── deployments/                  # Generated deployment configs
│   └── <domain>/                 # Per-domain configuration
│       ├── inventory/            # Ansible inventory
│       ├── group_vars/           # Domain-specific group vars
│       ├── host_vars/            # Domain-specific host vars
│       ├── templates/            # Rendered templates
│       ├── vault/                # Encrypted secrets (never regenerated)
│       ├── external_tasks/       # Custom playbooks
│       ├── files/                # Static files (OSCAP, etc.)
│       └── vars/                 # Additional variable files
├── vault_SAMPLES/                # Sample vault files
│   └── rhis_builder_vault_SAMPLE.yml
├── example.ca.24.sh              # Container launch helper (AAP 2.4)
├── example.ca.25.sh              # Container launch helper (AAP 2.5)
└── docs/                         # Documentation
```

**Consumption**:
- Mounted into `rhis-provisioner-container` at runtime
- All rhis-builder-* projects reference these configs via symlinks

### rhis-provisioner-container (Execution Environment)

**Purpose**: Hermetic container aggregating all RHIS components.

**Base Image**: `quay.io/parmstro/rhis-base-9-2.5:latest`
- RHEL UBI 9
- Python dependencies
- Ansible core + collections
- Binary tools (podman, git, etc.)

**Build Process**:
```dockerfile
FROM quay.io/parmstro/rhis-base-9-2.5:latest

# Clone all rhis-builder-* repositories
RUN git clone https://github.com/parmstro/rhis-builder-idm && \
    git clone https://github.com/parmstro/rhis-builder-satellite && \
    git clone https://github.com/parmstro/rhis-builder-nbde && \
    # ... all 25 repositories
    
# Create unified vars structure
RUN mkdir -p /opt/rhis/common_vars/{host_vars,group_vars,templates,vault,inventory}

# Symlink all project vars to common directory
RUN for project in /opt/rhis/rhis-builder-*/; do \
      ln -s /opt/rhis/common_vars/host_vars $project/host_vars; \
      ln -s /opt/rhis/common_vars/group_vars $project/group_vars; \
      # ... etc
    done

# Add helper scripts
COPY scripts/* /usr/local/bin/

ENTRYPOINT ["/bin/bash"]
```

**Runtime**:
```bash
# Generated launch scripts mount your deployment configuration
# Use example.ca.25.sh for AAP 2.5+ or example.ca.24.sh for AAP 2.4
./run_container.sh \
  --secrets-dir ~/rhis/rhis-builder-inventory/deployments/example.ca/vault \
  --external-tasks-dir ~/rhis/rhis-builder-inventory/deployments/example.ca/external_tasks \
  --files-dir ~/rhis/rhis-builder-inventory/deployments/example.ca/files \
  --group-vars-dir ~/rhis/rhis-builder-inventory/deployments/example.ca/group_vars \
  --host-vars-dir ~/rhis/rhis-builder-inventory/deployments/example.ca/host_vars \
  --inventory-dir ~/rhis/rhis-builder-inventory/deployments/example.ca/inventory \
  --templates-dir ~/rhis/rhis-builder-inventory/deployments/example.ca/templates \
  --vars-dir ~/rhis/rhis-builder-inventory/deployments/example.ca/vars \
  --ansible-ver 2.5
```

**Inside Container**:
- All rhis-builder-* repositories available at `/rhis/rhis-builder-*/`
- Inventory mounted at `/rhis/vars/external_inventory/`
- Vault mounted at `/rhis/vars/vault/`
- Helper scripts (build_*.sh, deploy_*.sh) in each repository
- Everything needed for air-gap deployment

---

## Configuration Architecture

### Variable Hierarchy

Ansible variable precedence (highest to lowest):

1. **Extra vars** (`-e` on command line)
2. **Task vars** (in playbooks)
3. **Block vars** (in playbooks)
4. **Role vars** (in role/vars/main.yml)
5. **Include vars** (explicitly loaded)
6. **Set_facts** (registered variables)
7. **Registered vars** (task outputs)
8. **Play vars_files** (loaded at play level)
9. **Play vars** (in playbook)
10. **Host vars** (`host_vars/<hostname>/`)
11. **Group vars** (`group_vars/<group>/`)
12. **Role defaults** (`roles/<role>/defaults/main.yml`)

### RHIS Variable Structure

```
rhis-builder-inventory/
└── deployments/example.ca/
    ├── group_vars/
    │   ├── all/                      # Variables for all hosts
    │   │   ├── main.yml              # General settings
    │   │   └── vault.yml             # Encrypted secrets
    │   ├── containerhosts/           # Container host group
    │   │   └── main.yml
    │   ├── clevishosts/              # NBDE client group
    │   │   └── main.yml
    │   └── idmservers/               # IdM servers group
    │       └── main.yml
    └── host_vars/
        ├── idm1.example.ca/          # IdM primary config
        │   └── main.yml
        ├── satellite1.example.ca/    # Satellite primary config
        │   └── main.yml
        └── tang1.example.ca/         # Tang server config
            └── containers.yml
```

### Configuration Pattern

**Role Variables**: All prefixed with role name to prevent collisions.

```yaml
# roles/tang_container/defaults/main.yml
tang_container_containers: []
tang_container_registry: "registry.redhat.io"

# host_vars/tang1.example.ca/containers.yml
tang_container_containers:
  - name: "tang"
    image: "rhel8/tang"
    registry: "{{ registry_url }}"
    # ...
```

### Secrets Management

**Ansible Vault**: All secrets encrypted.

```yaml
# group_vars/all/vault.yml (encrypted)
vault_registry_username: "service_account"
vault_registry_password: "secret_password"
vault_idm_admin_password: "admin_secret"

# group_vars/all/main.yml (references vault)
registry_username: "{{ vault_registry_username }}"
registry_password: "{{ vault_registry_password }}"
```

---

## Container Architecture

### Hermetic Packaging

**Goal**: Bundle everything needed for deployment in container.

**Benefits**:
1. **Validation**: Test complete stack before deployment
2. **Signing**: Sign validated container image
3. **Air-Gap**: Transfer single container to disconnected environment
4. **Reproducibility**: Identical environment every deployment

### Build-Time vs Runtime

**Build Time** (in connected environment):
- Clone all git repositories
- Install all Python packages
- Install all Ansible collections
- Download all binary dependencies
- Create helper scripts

**Runtime** (potentially disconnected):
- Mount inventory configuration
- Execute deployments
- No external fetches required

### Air-Gap Transfer

```bash
# In connected environment
podman save quay.io/parmstro/rhis-provisioner-9:latest -o rhis-provisioner.tar

# Transfer rhis-provisioner.tar via physical media

# In disconnected environment
podman load -i rhis-provisioner.tar
podman run -it -v /inventory:/opt/rhis/inventory:Z rhis-provisioner-9:latest
```

---

## Security Architecture

### Defense in Depth

**Layer 1: Identity & Access**
- IdM provides central authentication
- Kerberos for service-to-service auth
- LDAP for user/group management
- 2FA with YubiKey (rhis-builder-yubi)

**Layer 2: Network**
- Firewall rules via firewalld
- SELinux enforcement on all systems
- Network segmentation (DMZ, internal, management)

**Layer 3: Encryption**
- NBDE for disk encryption (rhis-builder-nbde)
- TLS/SSL via IdM CA
- Encrypted communication between services

**Layer 4: Compliance**
- OSCAP scanning (rhis-builder-oscap)
- CIS RHEL 9 hardening
- Continuous compliance monitoring

**Layer 5: Secrets Management**
- Ansible Vault for secrets
- No secrets in git (encrypted only)
- Satellite credentials in IdM

### Security Services

**NBDE (Network Bound Disk Encryption)**:
- Tang servers for key escrow
- Clevis clients for automated unlock
- Boot-time decryption without manual intervention

**Keycloak**:
- Identity broker for applications
- SAML/OAuth/OIDC support
- Integration with IdM

**OSCAP**:
- Security compliance scanning
- CIS benchmark implementation
- Remediation automation

**YubiKey**:
- Hardware token authentication
- IdM integration
- 2FA for privileged access

---

## Network Architecture

### DNS Architecture

**Primary DNS**: Red Hat Identity Management

**Zones**:
- Forward zones: `example.ca`, subdomains
- Reverse zones: PTR records for all networks
- Dynamic DNS: Satellite-provisioned hosts auto-register

**Integration**:
- Satellite updates DNS via realm-capsule user
- All hosts resolve via IdM DNS
- External forwarders for internet resolution

### Network Segmentation (Typical)

```
┌─────────────────────────────────────────────────┐
│  DMZ / Public Zone                              │
│  - Web frontends                                │
│  - Public APIs                                  │
└────────────────┬────────────────────────────────┘
                 │ Firewall
┌────────────────▼────────────────────────────────┐
│  Application Zone                               │
│  - Application servers                          │
│  - Keycloak                                     │
└────────────────┬────────────────────────────────┘
                 │ Firewall
┌────────────────▼────────────────────────────────┐
│  Infrastructure Zone                            │
│  - IdM                                          │
│  - Satellite                                    │
│  - AAP                                          │
│  - NBDE Tang servers                           │
└────────────────┬────────────────────────────────┘
                 │ Firewall
┌────────────────▼────────────────────────────────┐
│  Management Zone                                │
│  - Provisioner access                           │
│  - Bastion hosts                                │
└─────────────────────────────────────────────────┘
```

### Firewall Configuration

**Default Deny**: All zones start with deny-all, explicit allows only.

**Example** (Tang server):
```yaml
firewall:
  - port: "8080/tcp"
    zone: "public"
    state: enabled
    permanent: true
```

---

## Data Flow

### Provisioning Flow

```
┌──────────────────┐
│  Admin launches  │
│  rhis-provisioner│
│  container       │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Container reads │
│  inventory from  │
│  mounted volume  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Ansible playbook│
│  targets Satellite│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Satellite       │
│  provisions host │
│  via compute     │
│  resource        │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  New host boots  │
│  runs kickstart  │
│  auto-enrolls in │
│  IdM             │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Configuration   │
│  applied via     │
│  Ansible (AAP)   │
└──────────────────┘
```

### Identity Flow

```
┌──────────────────┐
│  User attempts   │
│  to access       │
│  service         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Service checks  │
│  IdM for auth    │
│  (Kerberos/LDAP) │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  IdM validates   │
│  credentials     │
│  (+ 2FA if req)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Service checks  │
│  authorization   │
│  (groups, sudo)  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Access granted  │
│  or denied       │
└──────────────────┘
```

---

## Scalability

### Horizontal Scaling

**IdM Replicas**:
- Deploy additional IdM servers as replicas
- Multi-master replication
- Geographic distribution

**Satellite Capsules**:
- Deploy Satellite Capsules for remote sites
- Content caching and proxying
- Load distribution

**AAP**:
- Automation mesh for distributed execution
- Execution nodes for capacity

### Vertical Scaling

**Compute Profiles**:
- Small: 2 vCPU, 4GB RAM
- Medium: 4 vCPU, 8GB RAM
- Large: 8 vCPU, 16GB RAM
- Custom: As needed

---

## Disaster Recovery

### Backup Strategy

**IdM**:
- `ipa-backup` for full backup
- Database dumps
- Replica promotion capability

**Satellite**:
- `satellite-maintain backup`
- Content on separate volumes
- Database backups

**Configuration**:
- Git repository backups (rhis-builder-inventory)
- Vault password secure storage

### Recovery Strategy

**IdM Loss**:
- Restore from backup, or
- Promote replica to primary

**Satellite Loss**:
- Restore from backup
- Capsules can continue operations temporarily

**Complete Site Loss**:
- Rebuild from landing zone
- Restore configs from git
- Restore backups

---

## Monitoring & Observability

### Integration Points

- **Satellite**: Built-in reporting and metrics
- **IdM**: Healthcheck and monitoring
- **AAP**: Job execution tracking
- **Infrastructure**: Can integrate Prometheus, Grafana, etc.

### Logging

- Centralized logging (optional integration)
- Audit logs in IdM
- Satellite provisioning logs
- AAP job logs

---

## Future Considerations

### Potential Enhancements

1. **Service Mesh**: Istio/OpenShift Service Mesh integration
2. **GitOps**: ArgoCD/FluxCD for continuous deployment
3. **Observability**: Full Prometheus/Grafana/Loki stack
4. **Multi-Region**: Geographic distribution patterns
5. **Collection Format**: Migrate to Ansible Collections

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-29  
**Author**: Claude Sonnet 4.5 (with parmstro)
