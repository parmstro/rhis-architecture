# RHIS Repository Inventory

**Complete inventory of all RHIS (Red Hat Infrastructure Standard) repositories**

Last Updated: 2026-04-29

---

## Repository Count: 25

---

## Core Foundation (2 repositories)

### rhis-builder-inventory 🔑

- **GitHub**: `https://github.com/parmstro/rhis-builder-inventory`
- **Purpose**: Central configuration repository and single source of truth
- **Technology**: Ansible (configuration as code)
- **Status**: ✅ Active
- **Dependencies**: None (keystone repository)
- **Key Features**:
  - `inventory_template/` for generating domain-specific deployments
  - group_vars, host_vars, templates, vault files
  - Deployment generation script
  - Reference configurations
- **Consumed By**: All other rhis-builder-* projects
- **Documentation**: README.md

### rhis-provisioner / rhis-provisioner-container 🚀

- **GitHub**: `https://github.com/parmstro/rhis-provisioner-container`
- **Purpose**: Unified execution environment containing all RHIS components
- **Technology**: Containers (RHEL UBI 9), Ansible, Python
- **Status**: ✅ Active
- **Dependencies**: All rhis-builder-* projects (cloned at build time)
- **Base Image**: `quay.io/parmstro/rhis-base-9-2.5:latest`
- **Key Features**:
  - Hermetic packaging (all dependencies baked in)
  - Air-gap deployment ready
  - Symlinked vars for unified configuration
  - Helper scripts for deployment
  - Mounts rhis-builder-inventory at runtime
- **Build Process**: Clones all rhis-builder-* repos at build time
- **Documentation**: README.md

---

## Landing Zones (5 repositories)

Create minimal RHEL 9 environments for IdM + Satellite bootstrap.

### rhis-builder-aws-lz

- **GitHub**: `https://github.com/parmstro/rhis-builder-aws-lz`
- **Purpose**: Bootstrap RHIS landing zone in AWS
- **Technology**: Ansible, AWS SDK
- **Status**: ✅ Active
- **Platform**: Amazon Web Services (AWS)
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - VPC creation
  - EC2 instance provisioning
  - Security groups and IAM roles
  - Minimal RHEL 9 for IdM and Satellite
- **Reference**: [AWS Landing Zone Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/strategy-migration/aws-landing-zone.html)
- **Documentation**: README.md

### rhis-builder-azure-lz

- **GitHub**: `https://github.com/parmstro/rhis-builder-azure-lz`
- **Purpose**: Bootstrap RHIS landing zone in Azure
- **Technology**: Ansible, Azure SDK
- **Status**: ✅ Active
- **Platform**: Microsoft Azure
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - Resource group creation
  - Virtual network setup
  - VM provisioning
  - Minimal RHEL 9 for IdM and Satellite
- **Reference**: [Azure Landing Zone](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/)
- **Documentation**: README.md

### rhis-builder-google-lz

- **GitHub**: `https://github.com/parmstro/rhis-builder-google-lz`
- **Purpose**: Bootstrap RHIS landing zone in Google Cloud
- **Technology**: Ansible, GCP SDK
- **Status**: ✅ Active
- **Platform**: Google Cloud Platform (GCP)
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - GCP project setup
  - VPC and subnet creation
  - Compute Engine instance provisioning
  - Minimal RHEL 9 for IdM and Satellite
- **Reference**: [GCP Landing Zone Design](https://cloud.google.com/architecture/landing-zones)
- **Documentation**: README.md

### rhis-builder-kvm-lz

- **GitHub**: `https://github.com/parmstro/rhis-builder-kvm-lz`
- **Purpose**: Bootstrap RHIS landing zone on KVM/libvirt hypervisor
- **Technology**: Ansible, libvirt
- **Status**: ✅ Active
- **Platform**: KVM/libvirt (on-premise)
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - libvirt network configuration
  - VM provisioning via virt-install
  - Storage pool management
  - Minimal RHEL 9 for IdM and Satellite
- **Documentation**: CLAUDE.md, README.md

### rhis-builder-baremetal-init

- **GitHub**: `https://github.com/parmstro/rhis-builder-baremetal-init`
- **Purpose**: Initialize RHIS on bare metal hardware
- **Technology**: Ansible, PXE/kickstart
- **Status**: ✅ Active
- **Platform**: Physical servers (bare metal)
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - IPMI/BMC configuration
  - PXE boot setup
  - Initial RHEL 9 installation
  - Minimal hosts for IdM and Satellite
- **Documentation**: README.md

---

## Core Infrastructure Services (6 repositories)

Bootstrap services - deployed FIRST before all other infrastructure.

### rhis-builder-idm (Deploy 1st) 🔐

- **GitHub**: `https://github.com/parmstro/rhis-builder-idm`
- **Purpose**: Deploy Red Hat Identity Management primary server
- **Technology**: Ansible, Red Hat IdM
- **Status**: ✅ Active
- **Deploy Order**: **#1 - First service deployed**
- **Dependencies**: 
  - `redhat.rhel_idm` Ansible collection
  - `rhis-builder-inventory`
- **Key Features**:
  - Integrated Certificate Authority (CA)
  - Integrated DNS with dynamic updates
  - Active Directory trust relationships
  - User, group, host group management
  - Sudo command/group/rule configuration
  - Forward and reverse DNS zones
  - Kerberos realm
- **Provides**: Authentication, authorization, DNS, certificates for entire RHIS platform
- **Documentation**: README.md

### rhis-builder-satellite (Deploy 2nd) 📡

- **GitHub**: `https://github.com/parmstro/rhis-builder-satellite`
- **Purpose**: Deploy and configure Red Hat Satellite (universal provisioner)
- **Technology**: Ansible, Red Hat Satellite
- **Status**: ✅ Active
- **Deploy Order**: **#2 - Second service deployed (after IdM)**
- **Dependencies**: rhis-builder-inventory, IdM (must be deployed first)
- **Key Features**:
  - Registered as IdM client
  - `realm-capsule` user via `foreman-prepare-realm`
  - HTTP service principal in IdM
  - Certificates from IdM CA
  - Compute resources: KVM, VMware, GCP, Azure, AWS
  - Compute profiles: Small, Medium, Large
  - Hostgroups for each rhis-builder-* system type
  - Content views and lifecycle environments
- **Role**: Universal provisioner for ALL subsequent infrastructure
- **Documentation**: README.md
- **Reference Config**: `host_vars/satellite1.example.ca`

### rhis-builder-satellite-templates

- **GitHub**: `https://github.com/parmstro/rhis-builder-satellite-templates`
- **Purpose**: GitOps for Satellite provisioning templates
- **Technology**: Satellite foreman_templates plugin, ERB templates
- **Status**: ✅ Active
- **Dependencies**: rhis-builder-satellite
- **Key Features**:
  - Template synchronization with git
  - Provisioning templates (kickstart, cloud-init, etc.)
  - Report templates
  - Job templates
  - Template metadata parsing
- **Pattern**: GitOps - templates stored in git, synced to Satellite
- **Future**: Template validator for pre-commit validation
- **Documentation**: README.md

### rhis-builder-satellite-customer

- **GitHub**: Unknown (local only?)
- **Purpose**: Customer-specific Satellite customizations
- **Technology**: Ansible
- **Status**: Unknown
- **Dependencies**: rhis-builder-satellite
- **Documentation**: ❌ None found
- **Note**: Likely customer-specific overrides or extensions

### rhis-builder-satellite-inventory

- **GitHub**: Unknown (local only?)
- **Purpose**: Satellite-specific inventory management
- **Technology**: Ansible
- **Status**: Unknown
- **Dependencies**: rhis-builder-satellite
- **Documentation**: ❌ None found
- **Note**: Possibly Satellite dynamic inventory or host management

---

## Automation Platform (3 repositories)

### rhis-builder-aap

- **GitHub**: `https://github.com/parmstro/rhis-builder-aap`
- **Purpose**: Deploy and configure Ansible Automation Platform
- **Technology**: Ansible, AAP installer
- **Status**: ✅ Active
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - AAP controller deployment
  - Automation mesh configuration
  - Execution environment setup
  - Job template creation
  - Integration with IdM for authentication
- **Provisioned Via**: Satellite
- **Documentation**: README.md

### rhis-builder-pipelines

- **GitHub**: `https://github.com/parmstro/rhis-builder-pipelines`
- **Purpose**: Operational automation workflows and CI/CD
- **Technology**: Ansible
- **Status**: ✅ Active
- **Dependencies**: rhis-builder-inventory, AAP
- **Contains**:
  - Sample application deployment content
  - VMware operations automation
  - Satellite operations automation
  - Node builder role
- **Use Case**: CI/CD pipelines and operational automation
- **Integration**: Uses many roles from rhis-builder-day-2-ops
- **Documentation**: README.md

### rhis-builder-aap.bfg-report

- **Purpose**: BFG Repo-Cleaner report artifact
- **Status**: ⚠️ Artifact (not active code)
- **Note**: Result of git history cleanup (removed sensitive data)
- **Action**: Can likely be deleted

---

## Security & Identity (4 repositories)

### rhis-builder-nbde

- **GitHub**: `https://github.com/parmstro/rhis-builder-nbde`
- **Purpose**: Network Bound Disk Encryption (Tang + Clevis)
- **Technology**: Ansible, Podman containers, Tang, Clevis
- **Status**: ✅ Active (currently being improved)
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - Tang servers in Podman containers
  - Systemd integration
  - Firewall and SELinux configuration
  - Clevis client configuration
  - Automated disk encryption unlock at boot
  - Deployment verification via clevis encrypt/decrypt test
- **Components**:
  - `tang_container` custom role
  - `rhel-system-roles.nbde_client` upstream role
- **Provisioned Via**: Satellite
- **Documentation**: ✅ CLAUDE.md, README.md, BEST_PRACTICES_ANALYSIS.md
- **Current Work**: Implementing Ansible best practices improvements

### rhis-builder-keycloak

- **GitHub**: `https://github.com/parmstro/rhis-builder-keycloak`
- **Purpose**: Deploy Keycloak identity broker for applications
- **Technology**: Ansible, Keycloak
- **Status**: ✅ Active (container deployment in progress)
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - Standalone server deployment
  - Containerized deployment (in development)
  - Identity brokering for RHIS applications
  - SAML/OAuth/OIDC support
  - Integration with IdM
- **Deployment Options**: Standalone VM or containerized
- **Provisioned Via**: Satellite
- **Documentation**: README.md

### rhis-builder-yubi

- **GitHub**: `https://github.com/parmstro/rhis-builder-yubi`
- **Purpose**: YubiKey integration with Red Hat Identity Manager
- **Technology**: Ansible, YubiKey, IdM
- **Status**: ✅ Active
- **Dependencies**: rhis-builder-inventory, rhis-builder-idm
- **Key Features**:
  - YubiKey enrollment in IdM
  - Two-factor authentication (2FA)
  - Hardware token authentication
  - OTP and U2F support
- **Use Case**: Hardware token authentication for privileged access
- **Provisioned Via**: Configuration applied to IdM
- **Documentation**: README.md

### rhis-builder-oscap

- **GitHub**: `https://github.com/parmstro/rhis-builder-oscap`
- **Purpose**: OpenSCAP security compliance scanning and hardening
- **Technology**: Ansible, OpenSCAP
- **Status**: ✅ Active
- **Dependencies**: rhis-builder-inventory
- **Roles**:
  - `rhis-rhel9-cis2` - CIS RHEL 9 Level 2 hardening
- **Key Features**:
  - Security compliance scanning
  - CIS benchmark implementation
  - Automated remediation
  - Compliance reporting
- **Use Case**: Security hardening and compliance validation
- **Provisioned Via**: Applied post-deployment via AAP
- **Documentation**: ❌ Limited (roles directory only)

---

## Lifecycle Management (4 repositories)

### rhis-builder-convert2rhel

- **GitHub**: `https://github.com/parmstro/rhis-builder-convert2rhel`
- **Purpose**: Convert CentOS/Oracle Linux to RHEL
- **Technology**: Ansible, convert2rhel utility
- **Status**: ✅ Active
- **Dependencies**: rhis-builder-inventory, AAP, Satellite
- **Key Features**:
  - Automated conversion from CentOS to RHEL
  - Automated conversion from Oracle Linux to RHEL
  - Pre-conversion analysis
  - Conversion orchestration via AAP
  - Integration with Satellite for subscription management
- **Use Case**: Migration to RHEL from other Enterprise Linux distributions
- **Documentation**: README.md
- **Demo**: Includes AAP and Satellite demo configuration

### rhis-builder-rhelupgrade

- **GitHub**: `https://github.com/parmstro/rhis-builder-rhelupgrade`
- **Purpose**: Upgrade RHEL between major versions
- **Technology**: Ansible, leapp upgrade utility
- **Status**: ✅ Active
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - RHEL 7 → 8 upgrades
  - RHEL 8 → 9 upgrades
  - Pre-upgrade checks
  - Post-upgrade validation
  - Combined with convert2rhel workflows
- **Use Case**: In-place RHEL major version upgrades
- **Documentation**: README.md

### rhis-builder-imagebuilder

- **GitHub**: `https://github.com/parmstro/rhis-builder-imagebuilder`
- **Purpose**: On-premise image building for VMs
- **Technology**: Ansible, Image Builder (composer)
- **Status**: ✅ Active
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - Build custom RHEL images
  - Hypervisor image formats (qcow2, vmdk, vhd)
  - Cloud image formats (AMI, Azure, GCP)
  - Integration with Satellite compute resources
  - Blueprint management
- **Target**: VM images for hypervisors and clouds
- **Distinction**: Different from `infra.osbuild` (which focuses on rpm-ostree)
- **Provisioned Via**: Satellite
- **Documentation**: README.md

### rhis-builder-day-2-ops

- **GitHub**: `https://github.com/parmstro/rhis-builder-day-2-ops`
- **Purpose**: Ongoing operations and management (Day N)
- **Technology**: Ansible
- **Status**: ✅ Active
- **Dependencies**: rhis-builder-inventory
- **Contains**: Playbooks and roles for:
  - Patching and updates
  - Backup and restore
  - Monitoring configuration
  - Log management
  - Operational tasks
- **Integration**: Many roles used in rhis-builder-pipelines
- **Use Case**: Post-deployment operational automation
- **Documentation**: README.md

---

## Development Tools & Templates (3 repositories)

### rhis-builder-project-template-files

- **GitHub**: Unknown (local only?)
- **Purpose**: Template files for creating new rhis-builder-* projects
- **Technology**: Project templates
- **Status**: ✅ Active
- **Dependencies**: None
- **Contains**:
  - Standard project structure
  - Common files (LICENSE, .gitignore, etc.)
  - README template
  - Ansible configuration templates
- **Use Case**: Standardize new repository creation
- **Documentation**: ❌ None found

### rhis-builder-role-template

- **GitHub**: Unknown (local only?)
- **Purpose**: Template for creating new Ansible roles
- **Technology**: Ansible role template
- **Status**: ✅ Active
- **Dependencies**: None
- **Contains**:
  - Standard role directory structure
  - meta/main.yml template
  - meta/argument_specs.yml template
  - README template
- **Use Case**: Standardize Ansible role creation
- **Documentation**: ❌ None found

### rhis-builder-discovery-remaster

- **GitHub**: `https://github.com/parmstro/rhis-builder-discovery-remaster`
- **Purpose**: Customize Foreman discovery images
- **Technology**: Ansible, Foreman Discovery
- **Status**: ⚠️ Partially deprecated (kexec feature)
- **Dependencies**: rhis-builder-inventory
- **Key Features**:
  - Generate custom Foreman discovery images
  - Originally for kexec-based discovery
  - Still works for PXE boot customization
- **Note**: kexec deprecated in future RHEL, but PXE boot customization still valid
- **Documentation**: README.md

---

## Repository Status Summary

| Status | Count | Description |
|--------|-------|-------------|
| ✅ Active | 23 | Production-ready, actively maintained |
| ⚠️ Artifact | 1 | BFG report (cleanup artifact) |
| ⚠️ Deprecated | 1 | Partial (discovery-remaster kexec feature) |
| ❌ Unknown | 3 | Missing documentation (customer, inventory, templates) |

---

## Technology Stack Summary

### Platforms Supported
- **Cloud**: AWS, Azure, GCP
- **On-Premise**: KVM/libvirt, VMware, Bare Metal
- **Operating System**: RHEL 8.x, RHEL 9.x

### Core Technologies
- **Automation**: Ansible 2.9+, Ansible Automation Platform
- **Identity**: Red Hat Identity Management, Kerberos, LDAP
- **Provisioning**: Red Hat Satellite
- **Containers**: Podman, RHEL UBI 9
- **Security**: NBDE (Tang/Clevis), Keycloak, YubiKey, OpenSCAP
- **Configuration**: Ansible Vault, Git

### Ansible Collections Used
- `redhat.rhel_idm`
- `redhat.satellite`
- `redhat.rhel_system_roles`
- `containers.podman`
- `ansible.posix`
- `community.general`
- `amazon.aws`
- `azure.azcollection`
- `google.cloud`

---

## Dependency Graph

```
rhis-builder-inventory (keystone)
    ↓
rhis-provisioner-container (clones all)
    ├── Landing Zones (5)
    │   ├── aws-lz
    │   ├── azure-lz
    │   ├── google-lz
    │   ├── kvm-lz
    │   └── baremetal-init
    │       ↓
    ├── rhis-builder-idm (FIRST deployment)
    │       ↓
    ├── rhis-builder-satellite (SECOND deployment)
    │   ├── satellite-templates
    │   ├── satellite-customer
    │   └── satellite-inventory
    │       ↓ (provisions all below)
    ├── Automation (3)
    │   ├── aap
    │   └── pipelines
    ├── Security (4)
    │   ├── nbde
    │   ├── keycloak
    │   ├── yubi
    │   └── oscap
    ├── Lifecycle (4)
    │   ├── convert2rhel
    │   ├── rhelupgrade
    │   ├── imagebuilder
    │   └── day-2-ops
    └── Dev Tools (3)
        ├── project-template-files
        ├── role-template
        └── discovery-remaster
```

---

## Documentation Status

| Category | README | CLAUDE.md | Best Practices | Argument Specs |
|----------|--------|-----------|----------------|----------------|
| Core (2) | 2/2 | 0/2 | 0/2 | 0/2 |
| Landing Zones (5) | 5/5 | 1/5 | 0/5 | 0/5 |
| Infrastructure (6) | 4/6 | 0/6 | 0/6 | 0/6 |
| Automation (3) | 2/3 | 0/3 | 0/3 | 0/3 |
| Security (4) | 4/4 | 1/4 | 1/4 | 0/4 |
| Lifecycle (4) | 4/4 | 0/4 | 0/4 | 0/4 |
| Dev Tools (3) | 1/3 | 0/3 | 0/3 | 0/3 |

**Totals**: 
- README: 22/27 (81%)
- CLAUDE.md: 2/27 (7%) ← **Improvement opportunity**
- Best Practices Analysis: 1/27 (4%) ← **Improvement opportunity**
- Argument Specs: 0/27 (0%) ← **Improvement opportunity**

---

## Recommended Actions

### High Priority
1. **Add CLAUDE.md** to all repositories (based on nbde pattern)
2. **Run best practices analysis** on each repository
3. **Add meta/argument_specs.yml** to all roles
4. **Document satellite-customer, satellite-inventory, project-template-files**

### Medium Priority
5. **Standardize .ansible-lint** configuration across all repos
6. **Add GitHub Actions CI/CD** for linting and testing
7. **Create role README templates** for consistent documentation

### Low Priority
8. **Remove rhis-builder-aap.bfg-report** (artifact cleanup)
9. **Consider archiving deprecated features** (discovery-remaster kexec)
10. **Migrate to Ansible Collections** (future consideration)

---

**Inventory Maintained By**: parmstro  
**Last Audit**: 2026-04-29  
**Next Review**: Quarterly
