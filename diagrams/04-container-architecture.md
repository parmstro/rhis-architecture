# RHIS Container Architecture

## Hermetic Packaging Strategy

```mermaid
graph TB
    subgraph "Build Environment (Connected)"
        BASE[quay.io/parmstro/rhis-base-9-2.5:latest<br/>RHEL UBI 9 + Ansible + Python + Tools]
        
        subgraph "Containerfile Build Process"
            CLONE[Clone all 25 rhis-builder-* repos]
            SYMLINK[Create unified vars structure<br/>Symlink all project vars to common directory]
            HELPERS[Add helper scripts]
        end
        
        BUILD[Container Build]
    end

    subgraph "rhis-provisioner-container"
        ROLES[All rhis-builder-* repositories<br/>- rhis-builder-idm<br/>- rhis-builder-satellite<br/>- rhis-builder-nbde<br/>- ... (all 25)]
        COMMON[Common vars directory<br/>├── host_vars/ → symlinked<br/>├── group_vars/ → symlinked<br/>├── templates/ → symlinked<br/>├── vault/ → symlinked<br/>└── inventory/ → symlinked]
        SCRIPTS[Helper scripts<br/>- deploy-landing-zone.sh<br/>- deploy-idm.sh<br/>- deploy-satellite.sh<br/>- etc.]
    end

    subgraph "Runtime Environment (Potentially Disconnected)"
        MOUNT[rhis-builder-inventory<br/>mounted at /opt/rhis/inventory]
        EXEC[Ansible Execution<br/>All dependencies available<br/>No external fetches needed]
    end

    subgraph "Air-Gap Transfer"
        SAVE[podman save → tar file]
        SNEAKER[Physical media transfer<br/>USB drive, DVD, etc.]
        LOAD[podman load from tar]
    end

    %% Build flow
    BASE --> BUILD
    BUILD --> CLONE
    CLONE --> SYMLINK
    SYMLINK --> HELPERS
    HELPERS --> ROLES
    HELPERS --> COMMON
    HELPERS --> SCRIPTS

    %% Runtime flow
    ROLES --> EXEC
    COMMON --> EXEC
    SCRIPTS --> EXEC
    MOUNT --> COMMON
    MOUNT --> EXEC

    %% Air-gap flow
    ROLES --> SAVE
    COMMON --> SAVE
    SCRIPTS --> SAVE
    SAVE --> SNEAKER
    SNEAKER --> LOAD
    LOAD --> EXEC

    %% Styling
    classDef build fill:#e3f2fd,stroke:#01579b,stroke-width:2px
    classDef container fill:#f3e5f5,stroke:#4a148c,stroke-width:3px
    classDef runtime fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef airgap fill:#ffe0b2,stroke:#e65100,stroke-width:2px

    class BASE,CLONE,SYMLINK,HELPERS,BUILD build
    class ROLES,COMMON,SCRIPTS container
    class MOUNT,EXEC runtime
    class SAVE,SNEAKER,LOAD airgap
```

## Container Layers

### Layer 1: Base Image
```dockerfile
FROM quay.io/parmstro/rhis-base-9-2.5:latest
```

**Contains:**
- RHEL UBI 9 minimal
- Python 3.9+
- Ansible core 2.14+
- All required Python packages (boto3, azure-cli, google-auth, etc.)
- Binary tools (git, podman, ssh, etc.)
- All Ansible collections

**Size**: ~2-3 GB

### Layer 2: RHIS Repositories
```dockerfile
# Clone all rhis-builder-* repositories
RUN git clone --depth 1 https://github.com/parmstro/rhis-builder-idm && \
    git clone --depth 1 https://github.com/parmstro/rhis-builder-satellite && \
    # ... all 25 repos
```

**Contains:**
- All rhis-builder-* git repositories
- Roles, playbooks, tasks
- Documentation

**Additional Size**: ~500 MB

### Layer 3: Unified Configuration
```dockerfile
# Create common vars structure and symlinks
RUN mkdir -p /opt/rhis/common_vars/{host_vars,group_vars,templates,vault,inventory} && \
    for project in /opt/rhis/rhis-builder-*/; do \
        ln -sf /opt/rhis/common_vars/host_vars $project/host_vars; \
        ln -sf /opt/rhis/common_vars/group_vars $project/group_vars; \
        # ... etc
    done
```

**Purpose:**
- All projects see the same configuration
- Inventory mounted at runtime maps to all projects
- No duplication of variables

### Layer 4: Helper Scripts
```dockerfile
COPY scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh
```

**Contains:**
- Deployment helper scripts
- Validation utilities
- Common operations

**Additional Size**: ~10 MB

### Final Container Size
**Total**: ~3-4 GB (compressed: ~1-2 GB)

## Runtime Execution

### Launch Container
```bash
podman run -it \
  -v /path/to/rhis-builder-inventory/generated/example.ca:/opt/rhis/inventory:Z \
  --name rhis-provisioner \
  quay.io/parmstro/rhis-provisioner-9:latest
```

### Inside Container
```bash
# All roles available
ls /opt/rhis/rhis-builder-*/

# Inventory mounted
ls /opt/rhis/inventory/
# host_vars/  group_vars/  templates/  vault/  inventory/

# Helper scripts available
deploy-idm.sh
deploy-satellite.sh
```

### Environment Variables
```bash
ANSIBLE_CONFIG=/opt/rhis/ansible.cfg
ANSIBLE_INVENTORY=/opt/rhis/inventory/inventory/hosts.yml
ANSIBLE_VAULT_PASSWORD_FILE=/opt/rhis/inventory/vault/.vault-pass
```

## Hermetic Packaging Benefits

### 1. Validation & Signing
```
Build container → Test complete stack → Sign image → Distribute
```

All components tested together as a unit.

### 2. Air-Gap Deployment
```
Connected environment:
  podman save rhis-provisioner-9:latest -o rhis.tar

Transfer via physical media

Disconnected environment:
  podman load -i rhis.tar
  podman run ...
```

No runtime dependencies on external networks.

### 3. Reproducible Deployments
- Exact same code versions every time
- No "works on my machine" issues
- Consistent across all environments

### 4. Version Management
```
quay.io/parmstro/rhis-provisioner-9:2.5.0  ← Specific tested version
quay.io/parmstro/rhis-provisioner-9:latest  ← Rolling latest
```

Version tags include:
- Base OS version (9)
- RHIS version (2.5.0)
- Git commit hash (optional)

## Update Strategy

### Minor Updates (Code Changes)
```bash
# Rebuild container with new code
git pull  # Update rhis-builder-* repos
podman build -t rhis-provisioner-9:2.5.1 .
```

### Major Updates (Base Image)
```bash
# Update base image first
podman build -f Containerfile.base -t rhis-base-9-3.0 .
# Then rebuild provisioner
podman build -t rhis-provisioner-9:3.0.0 .
```

### Configuration Updates
```bash
# No container rebuild needed!
# Just update rhis-builder-inventory and remount
vim /path/to/rhis-builder-inventory/generated/example.ca/...
podman run -v /path/to/updated/inventory:/opt/rhis/inventory:Z ...
```

## Security Considerations

### Image Scanning
```bash
# Scan for vulnerabilities
podman scan rhis-provisioner-9:latest

# Sign image after validation
podman sign rhis-provisioner-9:2.5.0
```

### Minimal Attack Surface
- Based on RHEL UBI 9 (minimal)
- Only necessary packages installed
- No unnecessary services running
- Regular security updates to base image

### Secrets Management
- Secrets in rhis-builder-inventory (not in container)
- Ansible Vault for encryption
- Mounted at runtime (not baked in)
- No secrets in container image

---

**Last Updated**: 2026-04-29
