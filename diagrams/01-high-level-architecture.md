---
layout: default
title: RHIS High-Level Architecture
---

# RHIS High-Level Architecture

## Overview Diagram

```mermaid
graph TB
    subgraph "Layer 0: Deployment Platform"
        BARE[Bare Metal]
        KVM[KVM/libvirt]
        AWS[AWS]
        AZURE[Azure]
        PLANNED[VMware • GCP • Hyper-V<br/>Proxmox • OpenStack • OCP Virt]
    end

    subgraph "Layer 1: Bootstrap Infrastructure"
        IDM[Red Hat Identity Management<br/>Auth • DNS • CA • Kerberos]
        SAT[Red Hat Satellite<br/>Universal Provisioner • Content Management]
    end

    subgraph "Layer 2: Automation Platform"
        AAP[Ansible Automation Platform<br/>Centralized Automation]
        PIPE[Pipelines<br/>CI/CD + Operations]
    end

    subgraph "Layer 3: Infrastructure Services"
        NBDE[NBDE<br/>Disk Encryption]
        KC[Keycloak<br/>Identity Broker]
        YUBI[YubiKey<br/>2FA]
        KVM_H[KVM Hypervisors]
        QUAD[Quadlet Services<br/>Quay, Loki, etc.]
        OCP[OpenShift<br/>Certs + UPI]
    end

    subgraph "Layer 4: Lifecycle Management"
        C2R[Convert2RHEL<br/>Migration]
        IB[ImageBuilder<br/>Custom Images]
        DAY2[Day-2 Ops<br/>Ongoing Management]
    end

    subgraph "Configuration & Execution"
        INV[rhis-builder-inventory<br/>Configuration as Code]
        PROV[rhis-provisioner-container<br/>Hermetic Execution Environment]
    end

    %% Configuration flow
    INV --> PROV
    PROV --> BARE
    PROV --> KVM
    PROV --> AWS
    PROV --> AZURE

    %% Bootstrap flow
    BARE --> IDM
    KVM --> IDM
    AWS --> IDM
    AZURE --> IDM
    
    IDM --> SAT

    %% Satellite provisions everything
    SAT --> AAP
    SAT --> NBDE
    SAT --> KC
    SAT --> KVM_H
    SAT --> QUAD
    SAT --> OCP
    SAT --> C2R
    SAT --> IB

    %% Service dependencies
    IDM --> KC
    IDM --> YUBI
    IDM --> AAP
    AAP --> PIPE
    PIPE --> DAY2

    %% Styling
    classDef platform fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef planned fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px,stroke-dasharray: 5 5
    classDef bootstrap fill:#ffe0b2,stroke:#e65100,stroke-width:3px
    classDef automation fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef infrastructure fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef lifecycle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef config fill:#fce4ec,stroke:#880e4f,stroke-width:3px

    class BARE,KVM,AWS,AZURE platform
    class PLANNED planned
    class IDM,SAT bootstrap
    class AAP,PIPE automation
    class NBDE,KC,YUBI,KVM_H,QUAD,OCP infrastructure
    class C2R,IB,DAY2 lifecycle
    class INV,PROV config
```

## Key Characteristics

- **Multi-Platform**: Bare metal, KVM, AWS, Azure today — every Satellite compute resource planned
- **Identity-First**: All services integrate with IdM for auth, DNS, certificates
- **Satellite-Driven**: Universal provisioner for all infrastructure after bootstrap
- **Hermetic Packaging**: Complete platform in one container for air-gap deployment
- **Configuration as Code**: Single source of truth in rhis-builder-inventory

## Deployment Order

1. **Landing Zone** (Layer 0) — Creates minimal RHEL hosts
2. **IdM** (Layer 1) — Identity, DNS, CA — **FIRST SERVICE**
3. **Satellite** (Layer 1) — Universal provisioner — **SECOND SERVICE**
4. **AAP** (Layer 2) — Automation platform
5. **All Other Services** (Layers 3-4) — Provisioned via Satellite, location by location

---

**Document Version**: 2.0
**Last Updated**: 2026-10-16
