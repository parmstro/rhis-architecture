# RHIS Dependency Graph

## Repository Dependencies

```mermaid
graph LR
    subgraph "Configuration"
        INV[rhis-builder-inventory<br/>📦 Config Repository]
    end

    subgraph "Execution Environment"
        PROV[rhis-provisioner-container<br/>🚀 Hermetic Container]
    end

    subgraph "Landing Zones - Deploy Order: 1"
        AWS[rhis-builder-aws-lz<br/>☁️ AWS]
        AZURE[rhis-builder-azure-lz<br/>☁️ Azure]
        GCP[rhis-builder-google-lz<br/>☁️ GCP]
        KVM[rhis-builder-kvm-lz<br/>💻 KVM]
        BARE[rhis-builder-baremetal-init<br/>🖥️ Bare Metal]
    end

    subgraph "Bootstrap - Deploy Order: 2-3"
        IDM[rhis-builder-idm<br/>🔐 Identity Management<br/>Deploy: #2]
        SAT[rhis-builder-satellite<br/>📡 Satellite<br/>Deploy: #3]
        SATTPL[rhis-builder-satellite-templates<br/>📄 Templates]
    end

    subgraph "Infrastructure Services - Deploy Order: 4+"
        AAP[rhis-builder-aap<br/>🤖 Automation Platform]
        NBDE[rhis-builder-nbde<br/>🔒 Disk Encryption]
        KC[rhis-builder-keycloak<br/>🎫 Identity Broker]
        IB[rhis-builder-imagebuilder<br/>💿 Image Builder]
        OSCAP[rhis-builder-oscap<br/>✅ Compliance]
        YUBI[rhis-builder-yubi<br/>🔑 YubiKey]
    end

    subgraph "Operational Services - Deploy Order: 5+"
        PIPE[rhis-builder-pipelines<br/>⚙️ CI/CD]
        DAY2[rhis-builder-day-2-ops<br/>🔧 Day-2 Operations]
    end

    subgraph "Lifecycle Management - Deploy Order: 4+"
        C2R[rhis-builder-convert2rhel<br/>🔄 Convert to RHEL]
        UPG[rhis-builder-rhelupgrade<br/>⬆️ RHEL Upgrades]
    end

    %% Configuration dependencies
    INV -->|Mounted at runtime| PROV
    PROV -->|Contains all repos| AWS
    PROV -->|Contains all repos| AZURE
    PROV -->|Contains all repos| GCP
    PROV -->|Contains all repos| KVM
    PROV -->|Contains all repos| BARE

    %% Bootstrap flow
    AWS -->|Creates hosts| IDM
    AZURE -->|Creates hosts| IDM
    GCP -->|Creates hosts| IDM
    KVM -->|Creates hosts| IDM
    BARE -->|Creates hosts| IDM
    
    IDM -->|Auth, DNS, Certs| SAT
    SAT -->|Template sync| SATTPL

    %% Satellite provisions all services
    SAT -->|Provisions| AAP
    SAT -->|Provisions| NBDE
    SAT -->|Provisions| KC
    SAT -->|Provisions| IB
    SAT -->|Provisions| OSCAP
    SAT -->|Provisions| C2R
    SAT -->|Provisions| UPG

    %% Service-to-service dependencies
    IDM -->|2FA integration| YUBI
    IDM -->|Identity backend| KC
    AAP -->|Execution platform| PIPE
    PIPE -->|Uses roles from| DAY2

    %% Styling
    classDef config fill:#fce4ec,stroke:#880e4f,stroke-width:3px
    classDef execution fill:#e3f2fd,stroke:#01579b,stroke-width:3px
    classDef landing fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef bootstrap fill:#ffe0b2,stroke:#e65100,stroke-width:3px
    classDef infrastructure fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef operational fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef lifecycle fill:#fff3e0,stroke:#e65100,stroke-width:2px

    class INV config
    class PROV execution
    class AWS,AZURE,GCP,KVM,BARE landing
    class IDM,SAT,SATTPL bootstrap
    class AAP,NBDE,KC,IB,OSCAP,YUBI infrastructure
    class PIPE,DAY2 operational
    class C2R,UPG lifecycle
```

## Dependency Types

### Build-Time Dependencies
- **rhis-provisioner-container** clones all 25 repositories during build
- No runtime fetching of code

### Runtime Dependencies
- **rhis-builder-inventory** mounted into container at runtime
- All playbooks reference inventory via symlinked common vars

### External Dependencies

#### Ansible Collections
```yaml
# Core
- ansible.posix
- ansible.utils
- community.general

# Red Hat
- redhat.rhel_idm
- redhat.satellite
- redhat.rhel_system_roles

# Containers
- containers.podman

# Cloud
- amazon.aws
- azure.azcollection
- google.cloud
- community.vmware
```

#### Red Hat Products
- Red Hat Identity Management (IdM)
- Red Hat Satellite
- Red Hat Ansible Automation Platform
- Red Hat Enterprise Linux 8.x, 9.x

## Critical Path

The critical deployment path (cannot be parallelized):

```
Landing Zone → IdM → Satellite → Services
```

**Minimum deployment time**: ~1-2 hours for critical path

After Satellite is deployed, all other services can be provisioned in parallel.

---

**Last Updated**: 2026-04-29
