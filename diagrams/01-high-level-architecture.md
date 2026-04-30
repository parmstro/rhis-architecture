# RHIS High-Level Architecture

## Overview Diagram

```mermaid
graph TB
    subgraph "Layer 0: Deployment Platform"
        AWS[AWS]
        AZURE[Azure]
        GCP[GCP]
        KVM[KVM/libvirt]
        BARE[Bare Metal]
    end

    subgraph "Layer 1: Bootstrap Infrastructure"
        IDM[Red Hat Identity Management<br/>Auth • DNS • CA • Kerberos]
        SAT[Red Hat Satellite<br/>Universal Provisioner • Content Management]
    end

    subgraph "Layer 2: Infrastructure Services"
        AAP[Ansible Automation Platform<br/>Centralized Automation]
        NBDE[NBDE<br/>Disk Encryption]
        KC[Keycloak<br/>Identity Broker]
        IB[ImageBuilder<br/>Custom Images]
    end

    subgraph "Layer 3: Operational Services"
        OSCAP[OSCAP<br/>Compliance]
        YUBI[YubiKey<br/>2FA]
        DAY2[Day-2 Ops<br/>Ongoing Management]
        PIPE[Pipelines<br/>CI/CD]
    end

    subgraph "Layer 4: Lifecycle Management"
        C2R[Convert2RHEL<br/>Migration]
        UPG[RHEL Upgrade<br/>Version Updates]
    end

    subgraph "Configuration & Execution"
        INV[rhis-builder-inventory<br/>Configuration as Code]
        PROV[rhis-provisioner-container<br/>Hermetic Execution Environment]
    end

    %% Configuration flow
    INV --> PROV
    PROV --> AWS
    PROV --> AZURE
    PROV --> GCP
    PROV --> KVM
    PROV --> BARE

    %% Bootstrap flow
    AWS --> IDM
    AZURE --> IDM
    GCP --> IDM
    KVM --> IDM
    BARE --> IDM
    
    IDM --> SAT

    %% Satellite provisions everything
    SAT --> AAP
    SAT --> NBDE
    SAT --> KC
    SAT --> IB
    SAT --> OSCAP
    SAT --> DAY2
    SAT --> C2R
    SAT --> UPG

    %% Service dependencies
    IDM --> KC
    IDM --> YUBI
    AAP --> PIPE
    PIPE --> DAY2

    %% Styling
    classDef platform fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef bootstrap fill:#ffe0b2,stroke:#e65100,stroke-width:3px
    classDef infrastructure fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef operational fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef lifecycle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef config fill:#fce4ec,stroke:#880e4f,stroke-width:3px

    class AWS,AZURE,GCP,KVM,BARE platform
    class IDM,SAT bootstrap
    class AAP,NBDE,KC,IB infrastructure
    class OSCAP,YUBI,DAY2,PIPE operational
    class C2R,UPG lifecycle
    class INV,PROV config
```

## Key Characteristics

- **Multi-Cloud Native**: Single platform for AWS, Azure, GCP, KVM, Bare Metal
- **Identity-First**: All services integrate with IdM for auth, DNS, certificates
- **Satellite-Driven**: Universal provisioner for all infrastructure after bootstrap
- **Hermetic Packaging**: Complete platform in one container for air-gap deployment
- **Configuration as Code**: Single source of truth in rhis-builder-inventory

## Deployment Order

1. **Landing Zone** (Layer 0) → Creates minimal RHEL hosts
2. **IdM** (Layer 1) → Identity, DNS, CA - **FIRST SERVICE**
3. **Satellite** (Layer 1) → Universal provisioner - **SECOND SERVICE**
4. **All Other Services** (Layers 2-4) → Provisioned via Satellite

---

**Last Updated**: 2026-04-29
