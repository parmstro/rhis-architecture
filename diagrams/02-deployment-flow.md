---
layout: default
title: RHIS Deployment Flow
---

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

    Admin->>Inv: 1. Download ZIP, init as own repo
    Admin->>Inv: 2. Edit basevars, run inventory_update.sh
    Inv-->>Admin: Deployment generated in deployments/<domain>/

    Admin->>Inv: 3. Populate vault secrets
    
    Admin->>Cont: 4. Launch provisioner container (.25.sh)
    Note over Cont: Container has all rhis-builder-* repos<br/>Mounts deployment from rhis-builder-inventory
    
    Admin->>Cont: 5. Deploy landing zone (bootstrap-init/kvm-lz/aws-lz/azure-lz)
    Cont->>LZ: Execute landing zone playbook
    LZ-->>Cont: Minimal RHEL hosts created
    
    Admin->>Cont: 6. build_idm_primary.sh
    Cont->>IdM: Execute rhis-builder-idm main.yml
    IdM->>IdM: Install IdM server
    IdM->>IdM: Configure CA, DNS, Kerberos
    IdM->>IdM: Create zones, users, groups
    IdM-->>Cont: IdM deployed (Auth, DNS, Certs)
    
    Admin->>Cont: 7. build_sat_primary.sh
    Cont->>Sat: Execute rhis-builder-satellite main.yml
    Sat->>Sat: Install Satellite
    Sat->>IdM: Register as IdM client
    IdM-->>Sat: Realm enrollment complete
    Sat->>IdM: Create realm-capsule user
    Sat->>IdM: Request HTTP service cert
    IdM-->>Sat: Certificate issued
    Sat->>Sat: Configure compute resources, hostgroups, sync content
    Sat-->>Cont: Satellite deployed, ready to provision

    Admin->>Cont: 8. Register IdM + provisioner to Satellite

    Admin->>Cont: 9. Validate compute resources
    
    Admin->>Cont: 10. deploy_aap_hosts.sh + build_aap_controller.sh
    
    Admin->>Cont: 11. Deploy infrastructure (per location)
    
    loop For each location
        Note over Svc: IdM replicas first
        Admin->>Sat: deploy_idm_replica_hosts.sh
        Sat->>Svc: Provision + kickstart + IdM enroll
        Admin->>Cont: build_idm_replicas.sh
        
        Note over Svc: Security infrastructure
        Admin->>Sat: deploy_quadlet_hosts.sh
        Admin->>Cont: build_quadlets.sh
        
        Note over Svc: Satellite capsules
        Admin->>Sat: deploy_sat_capsule_hosts.sh
        Admin->>Cont: build_sat_1/2/3_capsules.sh
    end
    
    Admin->>Admin: 12. Deploy workloads via AAP
```

## Phase Breakdown

### Phase 1: Bootstrap
- Create provisioner, IdM primary, Satellite primary
- Bare metal: use `rhis-builder-bootstrap-init`
- VM/cloud: use appropriate landing zone

### Phase 2: Registration
- Register IdM primary and provisioner to Satellite
- Enables content management and patching for bootstrap hosts

### Phase 3: Validation
- Test bare metal and VM compute resource provisioning
- Verify IdM enrollment, DNS, content access
- Destroy test machines

### Phase 4: AAP
- Deploy AAP hosts via Satellite (`deploy_aap_hosts.sh`)
- Build AAP controller (`build_aap_controller.sh`)
- Post-install: job templates, credentials, EE configuration

### Phase 5: Infrastructure (per location)
- IdM replicas in local datacenter first
- Security infrastructure (NBDE Tang servers, log aggregation)
- Satellite capsules
- Additional AAP nodes

### Phase 6: Workloads
- Application deployments via AAP job templates
- Operational automation via `rhis-builder-pipelines`

## Total Deployment Time

- **Minimum** (small environment, experienced admin): 2-3 hours
- **Typical** (standard environment): 4-6 hours
- **Large** (multiple sites, many services): 1-2 days

Satellite content sync is the biggest variable — from 30 minutes on high-spec
hardware with fast networking to 10+ hours on NUC-class hardware with 1Gb
connection.

## Success Criteria

After deployment:
- IdM web UI accessible
- Satellite web UI accessible
- DNS resolution working via IdM
- Kerberos authentication functional
- Satellite can provision new hosts via all configured compute resources
- All services registered in IdM
- All services managed by Satellite
- AAP controller operational with job templates configured

---

**Document Version**: 2.0
**Last Updated**: 2026-10-16
