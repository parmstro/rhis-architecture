---
layout: default
title: RHIS Integration and Data Flow
---

# RHIS Integration and Data Flow

## Identity and Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant Service as Application/Service
    participant KC as Keycloak
    participant IDM as Red Hat IdM
    participant LDAP as LDAP Directory
    participant KRB as Kerberos KDC

    User->>Service: 1. Access application
    Service->>KC: 2. Redirect to Keycloak
    KC->>User: 3. Show login page
    User->>KC: 4. Enter credentials
    KC->>IDM: 5. Authenticate via LDAP/Kerberos
    
    alt Kerberos Auth
        IDM->>KRB: Validate credentials
        KRB-->>IDM: TGT issued
    else LDAP Auth
        IDM->>LDAP: Bind with credentials
        LDAP-->>IDM: Bind successful
    end
    
    IDM-->>KC: 6. Authentication successful
    KC->>IDM: 7. Query user groups/roles
    IDM-->>KC: 8. Return user attributes
    KC->>KC: 9. Generate JWT token
    KC-->>Service: 10. Redirect with token
    Service->>Service: 11. Validate token
    Service-->>User: 12. Grant access
```

## Provisioning Flow

```mermaid
graph TB
    subgraph "Provisioning Request"
        ADMIN[Administrator]
        SAT_UI[Satellite Web UI<br/>or Hammer CLI]
    end

    subgraph "Satellite Orchestration"
        SAT[Satellite Server]
        TFTP[TFTP Server]
        TMPL[Provisioning Templates<br/>from Git]
        DNS[Dynamic DNS<br/>via realm-capsule]
    end

    subgraph "Red Hat IdM"
        IDM_DNS[DNS Service]
        IDM_HOST[Host Entry]
        IDM_REALM[Realm Service]
    end

    subgraph "Compute Resource"
        CR[Compute Resource<br/>KVM/VMware/AWS/Azure]
        VM[New VM/Instance]
    end

    subgraph "New System Boot"
        PXE[PXE Boot]
        KS[Kickstart]
        OS[RHEL Installation]
        REG[Satellite Registration]
        IPA[IdM Enrollment]
        CFG[Ansible Configuration]
    end

    %% Flow
    ADMIN-->|1. Create host| SAT_UI
    SAT_UI-->|2. Submit| SAT
    SAT-->|3. Request DNS entry| DNS
    DNS-->|4. Create A/PTR record| IDM_DNS
    SAT-->|5. Create host entry| IDM_HOST
    SAT-->|6. Provision VM| CR
    CR-->|7. Create| VM
    VM-->|8. Boot| PXE
    PXE-->|9. Request boot image| TFTP
    TFTP-->|10. Provide kickstart| KS
    KS-->|11. Render template| TMPL
    KS-->|12. Install RHEL| OS
    OS-->|13. Register| REG
    REG-->|14. Subscription| SAT
    OS-->|15. Join realm| IPA
    IPA-->|16. Authenticate| IDM_REALM
    IDM_REALM-->|17. Create host principal| IDM_HOST
    SAT-->|18. Apply configuration| CFG
    CFG-->|19. Ansible run| OS

    %% Styling
    classDef admin fill:#e3f2fd,stroke:#01579b,stroke-width:2px
    classDef satellite fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    classDef idm fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef compute fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef boot fill:#fff3e0,stroke:#f57c00,stroke-width:2px

    class ADMIN,SAT_UI admin
    class SAT,TFTP,TMPL,DNS satellite
    class IDM_DNS,IDM_HOST,IDM_REALM idm
    class CR,VM compute
    class PXE,KS,OS,REG,IPA,CFG boot
```

## AAP TLS Certificate Flow

```mermaid
sequenceDiagram
    participant IdM as Red Hat IdM CA
    participant Node as AAP Node
    participant Installer as AAP Installer Node
    participant AAP as AAP Installer

    Note over Node: platform_node_pre role
    Node->>IdM: ipa service-add HTTP/<fqdn>
    Node->>IdM: ipa-getcert request
    IdM-->>Node: Certificate issued to<br/>platform_ssl_certs_base_dir/<fqdn>/

    Note over Installer: fetch_node_crts.yml
    Node->>Installer: SCP certificates to installer
    Note over Installer: All node certs now at<br/>base_dir/<fqdn>/<fqdn>.crt|key

    Note over Installer: platform_installer_config
    Installer->>Installer: Generate installer inventory<br/>with per-component cert paths

    Installer->>AAP: Launch installer
    AAP->>AAP: Install with IdM TLS certs
```

## Service Integration Map

```mermaid
graph TB
    subgraph "Identity Layer"
        IDM[Red Hat IdM]
        KC[Keycloak]
        YUBI[YubiKey]
    end

    subgraph "Management Layer"
        SAT[Satellite]
        AAP[Automation Platform]
    end

    subgraph "Security Layer"
        NBDE[NBDE/Tang]
    end

    subgraph "Application Layer"
        APP1[Application 1]
        APP2[Application 2]
    end

    subgraph "Infrastructure Layer"
        HOST1[Host 1]
        HOST2[Host 2]
        HOST3[Host 3]
    end

    %% Identity integrations
    IDM -->|LDAP/Kerberos| SAT
    IDM -->|Identity Backend| KC
    IDM -->|2FA Integration| YUBI
    IDM -->|DNS Resolution| SAT
    IDM -->|DNS Resolution| AAP
    IDM -->|Certificates| SAT
    IDM -->|Certificates| AAP

    %% Management integrations
    SAT -->|Provisions| HOST1
    SAT -->|Provisions| HOST2
    SAT -->|Provisions| HOST3
    SAT -->|Content/Patches| HOST1
    SAT -->|Content/Patches| HOST2
    SAT -->|Content/Patches| HOST3
    
    AAP -->|Configures| HOST1
    AAP -->|Configures| HOST2
    AAP -->|Configures| HOST3
    AAP -->|Deploys| APP1
    AAP -->|Deploys| APP2

    %% Security integrations
    NBDE -->|Encrypts Disks| HOST1
    NBDE -->|Encrypts Disks| HOST2
    NBDE -->|Encrypts Disks| HOST3

    %% Application integrations
    KC -->|SSO| APP1
    KC -->|SSO| APP2
    
    APP1 -->|Runs on| HOST1
    APP2 -->|Runs on| HOST2

    %% Host identity
    HOST1 -->|Enrolled in| IDM
    HOST2 -->|Enrolled in| IDM
    HOST3 -->|Enrolled in| IDM

    %% Styling
    classDef identity fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef management fill:#ffe0b2,stroke:#e65100,stroke-width:2px
    classDef security fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef application fill:#e3f2fd,stroke:#01579b,stroke-width:2px
    classDef infrastructure fill:#fff3e0,stroke:#f57c00,stroke-width:2px

    class IDM,KC,YUBI identity
    class SAT,AAP management
    class NBDE security
    class APP1,APP2 application
    class HOST1,HOST2,HOST3 infrastructure
```

## Data Persistence

### Configuration Data
```
rhis-builder-inventory (Git)
  ├── inventory_template/    -> Source of truth templates
  ├── deployments/<domain>/  -> Rendered output (never edit directly)
  │   ├── host_vars/
  │   ├── group_vars/
  │   ├── inventory/
  │   ├── templates/
  │   ├── vars/
  │   ├── files/
  │   ├── external_tasks/
  │   └── vault/             -> Encrypted secrets (never regenerated)
  └── inventory_update.sh    -> Renders templates to deployments

Mounted into container at /rhis/vars/
```

### Identity Data
```
Red Hat IdM (389 Directory Server)
  ├── Users and Groups     -> LDAP directory
  ├── DNS Zones            -> BIND backend
  ├── Certificates         -> Dogtag CA
  ├── Kerberos Principals  -> KDC database
  └── Sudo Rules           -> LDAP entries

Replicated to: IdM replicas (multi-master)
Backed up via: ipa-backup
```

### Infrastructure Data
```
Red Hat Satellite (PostgreSQL)
  ├── Hosts                -> Inventory
  ├── Content Views        -> Package metadata
  ├── Activation Keys      -> Subscription data
  ├── Provisioning Config  -> Templates, profiles
  └── Reports              -> Audit logs

Backed up via: satellite-maintain backup
Content stored: /var/lib/pulp (separate volume recommended)
```

### Automation Data
```
Ansible Automation Platform (PostgreSQL)
  ├── Job Templates        -> Automation definitions
  ├── Inventories          -> Host lists (synced from Satellite)
  ├── Credentials          -> Encrypted secrets
  ├── Projects             -> Git repo references
  └── Job History          -> Execution logs
```

## Network Communication Patterns

### Management Traffic
```
Administrator -> Satellite (443/tcp)
Administrator -> IdM (443/tcp)
Administrator -> AAP (443/tcp via Gateway)
```

### Provisioning Traffic
```
New Host -> Satellite TFTP (69/udp)
New Host -> Satellite HTTP (80/tcp)
New Host -> Satellite HTTPS (443/tcp)
```

### Identity Traffic
```
Service -> IdM LDAP (389/tcp, 636/tcp)
Service -> IdM Kerberos (88/tcp, 88/udp)
Service -> IdM DNS (53/tcp, 53/udp)
```

### Automation Traffic
```
AAP -> Target Hosts SSH (22/tcp)
Satellite -> Target Hosts SSH (22/tcp)
```

### Security Traffic
```
Clevis Client -> Tang Server (8080/tcp)
```

---

**Document Version**: 2.0
**Last Updated**: 2026-10-16
