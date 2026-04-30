# RHIS Deployment Flow

## Complete Deployment Sequence

```mermaid
sequenceDiagram
    participant Admin as Administrator
    participant Inv as rhis-builder-inventory
    participant Cont as rhis-provisioner-container
    participant LZ as Landing Zone
    participant IdM as Red Hat IdM
    participant Sat as Red Hat Satellite
    participant Svc as Infrastructure Services

    Admin->>Inv: 1. Generate deployment config for domain
    Inv-->>Admin: Configuration generated

    Admin->>Inv: 2. Customize host_vars, group_vars, vault
    
    Admin->>Cont: 3. Launch provisioner container
    Note over Cont: Container has all rhis-builder-* repos<br/>Mounts inventory from rhis-builder-inventory
    
    Admin->>Cont: 4. Deploy landing zone (AWS/Azure/GCP/KVM/Bare Metal)
    Cont->>LZ: Execute landing zone playbook
    LZ-->>Cont: ✓ Minimal RHEL hosts created:<br/>- idm1.example.ca<br/>- satellite1.example.ca
    
    Admin->>Cont: 5. Deploy IdM Primary
    Cont->>IdM: Execute rhis-builder-idm playbook
    IdM->>IdM: Install IdM server
    IdM->>IdM: Configure CA, DNS, Kerberos
    IdM->>IdM: Create zones, users, groups
    IdM-->>Cont: ✓ IdM deployed<br/>Provides: Auth, DNS, Certs
    
    Admin->>Cont: 6. Deploy Satellite Primary
    Cont->>Sat: Execute rhis-builder-satellite playbook
    Sat->>Sat: Install Satellite
    Sat->>IdM: Register as IdM client
    IdM-->>Sat: ✓ Realm enrollment complete
    Sat->>IdM: Create realm-capsule user
    Sat->>IdM: Request HTTP service cert
    IdM-->>Sat: ✓ Certificate issued
    Sat->>Sat: Configure compute resources<br/>Create hostgroups<br/>Sync content
    Sat-->>Cont: ✓ Satellite deployed<br/>Ready to provision
    
    Admin->>Cont: 7. Deploy infrastructure services
    
    loop For each service (NBDE, AAP, Keycloak, etc.)
        Admin->>Sat: Create host via Satellite
        Sat->>Svc: Provision host (kickstart)
        Svc->>Svc: Install RHEL
        Svc->>Sat: Register to Satellite
        Svc->>IdM: Auto-enroll in IdM realm
        IdM-->>Svc: ✓ Realm joined
        Sat->>Svc: Apply configuration (Ansible)
        Svc-->>Admin: ✓ Service deployed
    end
    
    Admin->>Admin: 8. Validation & verification
```

## Phase Breakdown

### Phase 0: Preparation (Manual)
- Obtain RHEL subscriptions
- Obtain Satellite manifest
- Set up cloud credentials (if needed)
- Clone rhis-builder-inventory
- Generate domain configuration
- Customize variables and vault

**Duration**: 1-4 hours

### Phase 1: Landing Zone (Automated)
- Create VPC/network (cloud) or configure network (on-prem)
- Provision minimal RHEL 9 hosts for IdM and Satellite
- Configure initial access (SSH keys, security groups)

**Duration**: 15-30 minutes

### Phase 2: Deploy IdM (Automated)
- Install IdM server packages
- Run ipa-server-install with CA and DNS
- Configure firewall and SELinux
- Create DNS zones (forward and reverse)
- Set up initial users, groups, sudo rules

**Duration**: 15-30 minutes

### Phase 3: Deploy Satellite (Automated)
- Install Satellite server
- Register as IdM client
- Configure realm integration (foreman-prepare-realm)
- Request certificates from IdM CA
- Configure compute resources for all platforms
- Create compute profiles (Small, Medium, Large)
- Define hostgroups for each system type
- Import provisioning templates from git
- Upload manifest and sync content

**Duration**: 30-60 minutes

### Phase 4: Deploy Services (Automated, Parallel)
For each service:
1. Select hostgroup in Satellite
2. Choose compute resource and profile
3. Provision (Satellite handles kickstart, registration, enrollment)
4. Apply configuration via Ansible

**Duration**: 10-20 minutes per service (can run in parallel)

## Total Deployment Time

- **Minimum** (small environment, experienced admin): 2-3 hours
- **Typical** (standard environment): 4-6 hours
- **Large** (multiple sites, many services): 1-2 days

## Success Criteria

After deployment:
- ✅ IdM web UI accessible (https://idm1.example.ca)
- ✅ Satellite web UI accessible (https://satellite1.example.ca)
- ✅ DNS resolution working via IdM
- ✅ Kerberos authentication functional
- ✅ Satellite can provision new hosts
- ✅ All services registered in IdM
- ✅ All services managed by Satellite

---

**Last Updated**: 2026-04-29
