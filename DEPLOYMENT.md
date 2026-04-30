# RHIS Deployment Guide

**Complete end-to-end deployment guide for Red Hat Infrastructure Standard**

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Deployment](#detailed-deployment)
- [Phase 0: Preparation](#phase-0-preparation)
- [Phase 1: Landing Zone](#phase-1-landing-zone)
- [Phase 2: Deploy IdM](#phase-2-deploy-idm)
- [Phase 3: Deploy Satellite](#phase-3-deploy-satellite)
- [Phase 4: Infrastructure Services](#phase-4-infrastructure-services)
- [Validation](#validation)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Access

- Red Hat Customer Portal account
- Red Hat subscriptions for:
  - RHEL (enough for all systems)
  - Satellite
  - Ansible Automation Platform (recommended)
- Cloud credentials (if deploying to AWS/Azure/GCP):
  - AWS: IAM user with appropriate permissions
  - Azure: Service principal
  - GCP: Service account
- On-premise access (if deploying to KVM/bare metal):
  - Hypervisor access
  - Network configuration capability
  - Storage provisioning

### Required Systems

- a workstation or "provisioner" node
  - 16GB RAM, 256GB disk, 2 cores
  - RHEL 9 or equivalent
  - a persistent provisioner is recommended for enterprise deployments
  - VSCode remoting can be used to connect from your workstation

- you can provision these manually or use one of the LZ projects to 
  provision the landing zone components and two bootstrap VMs
HINT: for POCs, labs, trials, use rhis-builder-baremetal-init. Super simple.

- an IdM Primary node
  - 16GB RAM, 256GB disk, 2 cores
  - RHEL 9 or equivalent - minimal installation
- an Satellite Primary node
  - 32GB RAM, 1TB fast disk, 4 cores
  - larger ecosystems require larger satellites
  - for a disconnected satellite, you will need 3x the space of your library export from your connected satellite
  - RHEL 9 or equivalent - minimal installation

### Required Tools

On your workstation or provision:
```bash
# Required
- git
- podman or docker
- SSH client
- Text editor (VS Code recommended)

# Recommended
- ansible (for local testing)
- gh (GitHub CLI)
```

### Network Requirements

- DNS domain you control (e.g., `example.ca`)
- IP address ranges for:
  - Management network
  - Infrastructure services
  - Application workloads
- Firewall rules configured (or ability to configure)

### Knowledge Requirements

- Basic Linux administration
- Ansible fundamentals
- RHEL subscription management
- Cloud platform basics (if deploying to cloud)

---

## Quick Start

For experienced users who want to get started immediately:

### 1. Get inventory repository
You do not want to clone the repository, you want to take a copy
so that your repository is separate and no one sees the changes but your 
organization.
```bash
wget https://github.com/parmstro/rhis-builder-inventory/archive/refs/heads/main.zip
unzip main.zip
mv rhis-builder-inventory-main rhis-builder-inventory   # rename it for convenience
cd rhis-builder-inventory
git init -b main                                        # you should ensure that the branch is main
git add * --all
git commit -m "Initial commit"
git remote add origin https://github.com/<your_org_or_login>/rhis-builder-inventory.git  # or whatever your url is
git remote -v
git push -u origin main
```

### 2. Modify the base vars file and then generate your deployment
Edit `inventory_basevars.yml` directly or make a copy (e.g., `yourdomain_basevars.yml`) to create your deployment. 
Each domain will get its own deployment under the `deployments/` directory.
```bash
# Create a custom basevars file for your domain
cp inventory_basevars.yml example_ca_basevars.yml

# Edit the basevars file to customize your deployment
vim example_ca_basevars.yml

# Generate deployment from basevars file
./inventory_update.sh --basevars-file example_ca_basevars.yml
```

**Important**: The `inventory_update.sh` script runs a containerized Ansible playbook that:
- Processes your basevars file
- Generates a complete deployment configuration in `deployments/<yourdomain>/`
- Creates helper scripts for launching the provisioner container

### 3. Your configuration will be in the deployments directory
```bash
cd deployments/example.ca
ls -la
# You'll see:
#   external_tasks/   - Custom tasks to extend RHIS
#   files/            - Files for playbook consumption (e.g., OSCAP content)
#   group_vars/       - Group-level Ansible variables
#   host_vars/        - Host-specific Ansible variables
#   inventory/        - Ansible inventory file
#   templates/        - Jinja2 templates for Satellite provisioning
#   vars/             - Additional variable files
#   vault/            - Ansible vault files (empty by default, add your secrets)
```

**Configuration philosophy**:
- For testing: Modify files directly in `deployments/<yourdomain>/`
- For production GitOps: Edit templates in `inventory_template/` to ensure changes persist across regenerations
- The `inventory_update.sh` script will regenerate everything except the `vault/` directory
- Your deployment directory should become your source of truth when working in a GitOps fashion


### 4. Encrypt secrets with Ansible Vault

An empty `vault/` directory is created when your deployment is generated. This directory is **never touched** by `inventory_update.sh` regeneration.

**Create your vault file**:
```bash
cd deployments/example.ca/vault

# Copy the sample vault file
cp ../../../vault_SAMPLES/rhis_builder_vault_SAMPLE.yml rhis_builder_vault.yml

# Edit the vault file and populate your secrets
vim rhis_builder_vault.yml
```

**The sample vault file is organized into sections**:
- **Landing Zone**: Cloud credentials (AWS keys, Azure service principal, GCP service account)
- **Registry**: Red Hat registry credentials, Quay.io credentials
- **IdM**: Admin password, Directory Manager password, DNS forwarder settings
- **Satellite**: Admin password, manifest path, organization settings
- **AAP**: Admin password, registry credentials, automation hub token
- **Infrastructure Services**: Container registry credentials, database passwords, etc.

**Encrypt the vault file**:
```bash
# Create a vault password file (DO NOT commit this to git)
echo "YourSecureVaultPassword" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# Encrypt the vault file
ansible-vault encrypt rhis_builder_vault.yml --vault-password-file ~/.vault_pass.txt

# Verify encryption
cat rhis_builder_vault.yml
# Should show: $ANSIBLE_VAULT;1.1;AES256...
```

**Alternative vaulting solutions**:
- HashiCorp Vault integration
- CyberArk integration
- External secrets management via AAP credentials
- The current default uses Ansible Vault for simplicity

**Important**: The default `.gitignore` excludes `vault/*.yml` to prevent accidental commits of secrets. 

### 5. Ensure you have the latest containers and launch provisioner container
Helper scripts ensure you have up-to-date containers fetched from quay.io. The `inventory_update` script generates helper scripts to launch the container:
- `<yourdomain>.24.sh` - Launches container with RHIS dependencies for **AAP 2.4 or earlier**
- `<yourdomain>.25.sh` - Launches container with RHIS dependencies for **AAP 2.5 or later**

**Recommended**: Use the 2.5 container. The default configuration templates target the latest stable Ansible Automation Platform (currently 2.6.x).

**AAP Version Differences**:
- AAP 2.4: Uses older controller collection (`awx.awx` or early `ansible.controller`)
- AAP 2.5+: Requires `ansible.controller` >= 4.6 with API changes

```bash
# Ensure you have the latest containers
./update_containers.sh

# Launch the AAP 2.5 provisioner container
./example.ca.25.sh
```

This launches the rhis-provisioner container, mounts your deployment configuration from `deployments/example.ca/`, and presents a command prompt inside the container.

**Expected output**:
```
[ansiblerunner@provisioner rhis-builder-inventory]$ ./example.ca.25.sh 

Launching the rhis-provisioner container with the following parameters:
external-tasks-dir: /home/ansiblerunner/rhis/rhis-builder-inventory/deployments/example.ca/external_tasks
files-dir: /home/ansiblerunner/rhis/rhis-builder-inventory/deployments/example.ca/files
group-vars-dir: /home/ansiblerunner/rhis/rhis-builder-inventory/deployments/example.ca/group_vars
host-vars-dir: /home/ansiblerunner/rhis/rhis-builder-inventory/deployments/example.ca/host_vars
inventory-dir: /home/ansiblerunner/rhis/rhis-builder-inventory/deployments/example.ca/inventory
secrets-dir: /home/ansiblerunner/rhis/rhis-builder-inventory/deployments/example.ca/vault
templates-dir: /home/ansiblerunner/rhis/rhis-builder-inventory/deployments/example.ca/templates
vars-dir: /home/ansiblerunner/rhis/rhis-builder-inventory/deployments/example.ca/vars
ansible-ver: 2.5
registry: quay.io
repo: parmstro
Mounting custom configuration
##########################################
Welcome to the RHIS Provisioner container!
RHIS Build: aniyu
Provisioner Version: 1.0.91
From Base Version: 1.0.13
For AAP Version: 2.5
RHIS Schema Version: 1.0.0
[root@provisioner rhis]# 
```

**What the container mounts**:
- `/rhis/vars/external_inventory/` - Your deployment configuration
- `/rhis/vars/vault/` - Your encrypted secrets
- `/rhis/rhis-builder-*` - All RHIS component repositories with helper scripts
- All deployment directories are bind-mounted from your local system
- Changes made inside the container persist to your local deployment files

### 6. Inside container - Deploy in order

**Understanding helper scripts**:
- `deploy_*.sh` - Create systems (via Satellite provisioning or cloud APIs)
- `build_*.sh` - Install and configure software on provisioned systems

All helper scripts accept these optional parameters:
- `-u | --sshuser <user>` - SSH user (default: `ansiblerunner`)
- `-i | --inventory <path>` - Inventory path (default: `/rhis/vars/external_inventory/inventory`)
- You will be prompted for SSH password and vault password

#### a) Landing Zone (creates IdM and Satellite hosts)
```bash
# Navigate to your platform's landing zone repository
cd /rhis/rhis-builder-aws-lz      # For AWS
cd /rhis/rhis-builder-azure-lz    # For Azure
cd /rhis/rhis-builder-google-lz   # For GCP
cd /rhis/rhis-builder-kvm-lz      # For KVM
cd /rhis/rhis-builder-baremetal-init  # For bare metal

# Deploy landing zone (creates minimal RHEL hosts for IdM and Satellite)
ansible-playbook -i /rhis/vars/external_inventory/inventory \
  --ask-vault-pass \
  --extra-vars "vault_dir=/rhis/vars/vault" \
  main.yml
```

#### b) IdM Primary (identity and DNS) - **FIRST SERVICE**
```bash
cd /rhis/rhis-builder-idm
./build_idm_primary.sh
```
This installs and configures the IdM Primary server with DNS, CA, Kerberos.
**All subsequent services will integrate with IdM for identity**.

#### c) Satellite Primary (universal provisioner) - **SECOND SERVICE**
```bash
cd /rhis/rhis-builder-satellite
./build_sat_primary_connected.sh
```
This installs and configures Satellite including:
- Manifest installation
- Content synchronization (can take 30min to 10h+ depending on hardware and content)
- Lifecycle environments
- Activation keys
- Hostgroups for provisioning
- Compute resource integration
- Discovery configuration

**After Satellite is deployed, all remaining services provision through Satellite**.

#### d) Deploy additional service nodes (via Satellite)
Use `deploy_*.sh` scripts from `/rhis/rhis-builder-pipelines` to create hosts via Satellite:
```bash
cd /rhis/rhis-builder-pipelines

# Deploy IdM replica hosts
./deploy_idm_replica_hosts.sh

# Deploy AAP controller and hub hosts
./deploy_aap_hosts.sh           # For AAP 2.5+
# OR
./deploy_aap24_hosts.sh         # For AAP 2.4

# Deploy container hosts (for Quadlet/Podman services)
./deploy_quadlet_hosts.sh

# Deploy test RHEL hosts
./deploy_rhel9_test_hosts.sh
./deploy_rhel10_test_hosts.sh
```

Each `deploy_*.sh` script:
- Reads host definitions from `/rhis/vars/external_inventory/group_vars/provisioner/`
- Uses Satellite to create hosts based on hostgroups
- Performs automated discovery and provisioning
- Integrates with IdM for DNS and enrollment

#### e) Build additional infrastructure services
Use `build_*.sh` scripts to install and configure software:
```bash
# Build IdM replicas
cd /rhis/rhis-builder-idm
./build_idm_replicas.sh

# Build AAP controller
cd /rhis/rhis-builder-aap
./build_aap_controller.sh       # For AAP 2.5+
# OR
./build_aap24_controller.sh     # For AAP 2.4

# Build AAP standalone hub
./build_aap_standalone_hub.sh

# Build Satellite capsules (multi-stage process)
cd /rhis/rhis-builder-satellite
./build_sat_1_capsules_satellite_pre.sh   # Prepare Satellite for capsules
./deploy_sat_capsule_hosts.sh              # Create capsule hosts via Satellite
./build_sat_2_capsules.sh                  # Install capsule software
./build_sat_3_capsules_satellite_post.sh   # Complete Satellite capsule integration
```

See [Detailed Deployment](#detailed-deployment) for step-by-step instructions.

---

## Detailed Deployment

---

## Phase 0: Preparation

### Step 1: Obtain RHEL Subscriptions

1. Log in to [Red Hat Customer Portal](https://access.redhat.com)
2. Navigate to Subscriptions
3. Ensure you have entitlements for:
   - RHEL Server (quantity: # of systems)
   - Satellite (minimum: 1)
   - AAP (optional, minimum: 1)

### Step 2: Obtain Satellite Manifest

1. In Customer Portal, navigate to Subscriptions → Subscription Allocations
2. Create new allocation: "RHIS Production" (or your naming)
3. Add subscriptions to allocation:
   - RHEL Server
   - Satellite
   - Any additional products
4. Download manifest ZIP file
5. Save for later use during Satellite configuration

### Step 3: Set Up Cloud Credentials (If Using Cloud)

#### AWS

```bash
# Create IAM user with programmatic access
aws iam create-user --user-name rhis-provisioner

# Attach policies (adjust as needed)
aws iam attach-user-policy \
  --user-name rhis-provisioner \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# Create access keys
aws iam create-access-key --user-name rhis-provisioner
# Save: Access Key ID and Secret Access Key
```

#### Azure

```bash
# Create service principal
az ad sp create-for-rbac \
  --name rhis-provisioner \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>

# Save output: appId, password, tenant
```

#### GCP

```bash
# Create service account
gcloud iam service-accounts create rhis-provisioner \
  --display-name="RHIS Provisioner"

# Grant roles
gcloud projects add-iam-policy-binding <project-id> \
  --member="serviceAccount:rhis-provisioner@<project-id>.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Create key
gcloud iam service-accounts keys create rhis-provisioner-key.json \
  --iam-account=rhis-provisioner@<project-id>.iam.gserviceaccount.com
```

### Step 4: Download Inventory Repository

**Important**: Do NOT clone the repository. Download it as a ZIP and re-initialize as your own repository to keep your configuration separate.

```bash
# Download the latest inventory repository
wget https://github.com/parmstro/rhis-builder-inventory/archive/refs/heads/main.zip
unzip main.zip
mv rhis-builder-inventory-main rhis-builder-inventory
cd rhis-builder-inventory

# Re-initialize as a new git repository
git init -b main
git add . --all
git commit -m "Initial commit"

# Add your remote repository (replace with your URL)
git remote add origin https://github.com/<your_org_or_login>/rhis-builder-inventory.git
git remote -v
git push -u origin main
```

**Why download instead of clone?**
- Your configuration will contain secrets (even when vaulted)
- You want complete control over your deployment configurations
- RHIS updates should be pulled selectively, not automatically
- Your organization's infrastructure becomes version-controlled independently

### Step 5: Generate Deployment Configuration

```bash
# Option 1: Edit the default basevars file
vim inventory_basevars.yml
./inventory_update.sh

# Option 2: Create a custom basevars file (recommended)
cp inventory_basevars.yml example_ca_basevars.yml
vim example_ca_basevars.yml
./inventory_update.sh --basevars-file example_ca_basevars.yml

# This creates:
# deployments/example.ca/
#   ├── external_tasks/    - Custom playbooks to extend RHIS
#   ├── files/             - Files (OSCAP content, certificates, etc.)
#   ├── group_vars/        - Group-level variables
#   ├── host_vars/         - Host-specific variables
#   ├── inventory/         - Ansible inventory file
#   ├── templates/         - Satellite provisioning templates
#   ├── vars/              - Additional variable files
#   └── vault/             - Ansible vault files (empty, populate manually)
```

**What `inventory_update.sh` does**:
- Runs a containerized Ansible playbook
- Processes your basevars YAML file
- Generates all deployment directories from templates
- Creates helper scripts `<yourdomain>.24.sh` and `<yourdomain>.25.sh`
- Does NOT touch the `vault/` directory (preserves your secrets)
- Can be re-run to regenerate configuration (vault/ is never overwritten)

### Step 6: Customize Configuration

```bash
cd deployments/example.ca
```

**Configuration directories**:
- `inventory/` - Ansible inventory defining hosts and groups
- `host_vars/` - Host-specific variables
- `group_vars/` - Group-level variables
- `vault/` - Encrypted secrets (Ansible Vault)
- `templates/` - Satellite provisioning templates (Jinja2)
- `vars/` - Additional variable files
- `files/` - Static files (OSCAP content, certificates)
- `external_tasks/` - Custom playbooks to extend RHIS

#### Edit Inventory

```bash
vim inventory/inventory
```

**Note**: The inventory is auto-generated from your basevars file but can be manually edited for testing. For production GitOps, edit the templates in `inventory_template/` instead.

```yaml
---
all:
  children:
    # IdM servers
    idmservers:
      hosts:
        idm1.example.ca:
          ansible_host: 10.0.1.10
    
    # Satellite servers
    satelliteservers:
      hosts:
        satellite1.example.ca:
          ansible_host: 10.0.1.20
    
    # Container hosts (for Tang, etc.)
    containerhosts:
      hosts:
        tang1.example.ca:
          ansible_host: 10.0.2.10
    
    # Clevis clients (NBDE)
    clevishosts:
      hosts:
        client1.example.ca:
          ansible_host: 10.0.3.10
```

#### Edit Group Variables

```bash
vim group_vars/all/main.yml
```

```yaml
---
# Domain configuration
domain: "example.ca"
realm: "EXAMPLE.CA"

# DNS configuration
dns_forwarders:
  - 8.8.8.8
  - 8.8.4.4

# Container registry
registry_url: "registry.redhat.io"
registry_username: "{{ vault_registry_username }}"
registry_password: "{{ vault_registry_password }}"

# IdM configuration
idm_admin_password: "{{ vault_idm_admin_password }}"
idm_dm_password: "{{ vault_idm_dm_password }}"

# Satellite configuration
satellite_organization: "Example Org"
satellite_location: "Primary DC"
satellite_admin_username: "admin"
satellite_admin_password: "{{ vault_satellite_admin_password }}"
```

#### Create Vault File

```bash
ansible-vault create vault/credentials.yml
```

```yaml
---
# Red Hat registry credentials
vault_registry_username: "your-service-account"
vault_registry_password: "your-registry-token"

# IdM passwords
vault_idm_admin_password: "SecureIdMAdminPassword123!"
vault_idm_dm_password: "SecureDMPassword123!"

# Satellite passwords
vault_satellite_admin_password: "SecureSatellitePassword123!"

# Cloud credentials (if using cloud)
vault_aws_access_key: "AKIA..."
vault_aws_secret_key: "..."
vault_azure_client_id: "..."
vault_azure_secret: "..."
vault_azure_tenant: "..."
vault_gcp_service_account_json: |
  {
    "type": "service_account",
    ...
  }
```

Save vault password in a secure location (DO NOT commit to git).

#### Edit Host Variables

```bash
# IdM primary server
vim host_vars/idm1.example.ca/main.yml
```

```yaml
---
idm_role: primary
idm_setup_dns: true
idm_setup_ca: true
idm_setup_adtrust: false  # Set true if integrating with Active Directory

# DNS zones
dns_forward_zones:
  - name: "example.ca"
    zone_type: master
  - name: "apps.example.ca"
    zone_type: master

dns_reverse_zones:
  - name: "1.0.10.in-addr.arpa"
    zone_type: master
```

```bash
# Satellite primary server
vim host_vars/satellite1.example.ca/main.yml
```

```yaml
---
satellite_scenario: satellite
satellite_version: "6.14"

# Compute resources to configure
satellite_compute_resources:
  - name: "AWS US-East-1"
    provider: ec2
    region: us-east-1
    access_key: "{{ vault_aws_access_key }}"
    secret_key: "{{ vault_aws_secret_key }}"
  
  - name: "KVM Hypervisor 1"
    provider: libvirt
    url: "qemu+ssh://root@kvm1.example.ca/system"

# Compute profiles
satellite_compute_profiles:
  - name: "Small"
    cpus: 2
    memory: 4096
  - name: "Medium"
    cpus: 4
    memory: 8192
  - name: "Large"
    cpus: 8
    memory: 16384
```

---

## Phase 1: Landing Zone

The landing zone creates minimal RHEL 9 hosts for IdM and Satellite.

### Step 1: Choose Platform

Select one landing zone based on your target platform:
- AWS: `rhis-builder-aws-lz`
- Azure: `rhis-builder-azure-lz`
- GCP: `rhis-builder-google-lz`
- KVM: `rhis-builder-kvm-lz`
- Bare Metal: `rhis-builder-baremetal-init`

### Step 2: Launch Provisioner Container

```bash
cd /path/to/rhis-builder-inventory
./example.ca.25.sh      # For AAP 2.5+
# OR
./example.ca.24.sh      # For AAP 2.4
```

This launches the rhis-provisioner container with your deployment mounted at `/rhis/vars/external_inventory/`.

**Container environment**:
- Working directory: `/rhis/`
- All RHIS repositories: `/rhis/rhis-builder-*/`
- Your inventory: `/rhis/vars/external_inventory/`
- Your vault: `/rhis/vars/vault/`
- Helper scripts: Available in each repository directory

### Step 3: Deploy Landing Zone

Inside the container:

#### AWS Example

```bash
cd /rhis/rhis-builder-aws-lz

# Verify AWS credentials
aws sts get-caller-identity

# Deploy landing zone
ansible-playbook -i /rhis/vars/external_inventory/inventory \
  --ask-vault-pass \
  --extra-vars "vault_dir=/rhis/vars/vault" \
  main.yml

# Expected output:
# - VPC created
# - Subnets created
# - Security groups configured
# - EC2 instances: idm1.example.ca, satellite1.example.ca
# - Instances accessible via SSH
```

#### KVM Example

```bash
cd /rhis/rhis-builder-kvm-lz

# Verify KVM connection (if using remote hypervisor)
virsh -c qemu+ssh://root@kvm-host.example.ca/system list

# Deploy landing zone
ansible-playbook -i /rhis/vars/external_inventory/inventory \
  --ask-vault-pass \
  --extra-vars "vault_dir=/rhis/vars/vault" \
  main.yml

# Expected output:
# - libvirt network configured
# - Storage pool created
# - VMs created: idm1.example.ca, satellite1.example.ca
# - VMs running and accessible
```

#### Bare Metal Example (Recommended for POC/Lab)

```bash
cd /rhis/rhis-builder-baremetal-init

# This is the simplest method for POC, lab, or trial deployments
# Requires: Physical servers with IPMI/BMC interfaces

ansible-playbook -i /rhis/vars/external_inventory/inventory \
  --ask-vault-pass \
  --extra-vars "vault_dir=/rhis/vars/vault" \
  main.yml

# Expected output:
# - IPMI power on
# - Network boot configuration
# - RHEL installation via Kickstart
# - Systems accessible via SSH
```

### Step 4: Verify Landing Zone

```bash
# Test SSH access to new hosts
ssh root@idm1.example.ca "hostnamectl"
ssh root@satellite1.example.ca "hostnamectl"

# Verify RHEL version
ssh root@idm1.example.ca "cat /etc/redhat-release"
# Expected: Red Hat Enterprise Linux release 9.x

# Verify network connectivity
ssh root@idm1.example.ca "ping -c 3 8.8.8.8"
```

### Step 5: Register Hosts (If Not Auto-Registered)

```bash
# If landing zone didn't auto-register with Subscription Manager
ssh root@idm1.example.ca
subscription-manager register \
  --username <customer-portal-username> \
  --password <password> \
  --auto-attach
```

---

## Phase 2: Deploy IdM

IdM provides identity, DNS, and certificates for the entire RHIS platform.

### Step 1: Pre-Deployment Checks

Inside the provisioner container:

```bash
# Verify IdM host is accessible
ansible -i /rhis/vars/external_inventory/inventory \
  --user ansiblerunner \
  --ask-pass \
  idm_primary \
  -m ping

# Verify hostname resolution
ssh ansiblerunner@idm1.example.ca "hostname -f"
# Should return: idm1.example.ca

# Verify time sync
ssh ansiblerunner@idm1.example.ca "timedatectl"
# Time should be synchronized

# Verify subscriptions
ssh ansiblerunner@idm1.example.ca "sudo subscription-manager status"
```

### Step 2: Deploy IdM Primary

**Using the helper script (recommended)**:
```bash
cd /rhis/rhis-builder-idm
./build_idm_primary.sh

# The script will:
# - Prompt for SSH password (for ansiblerunner user)
# - Prompt for vault password
# - Run the IdM primary installation playbook
# - Default inventory: /rhis/vars/external_inventory/inventory
# - Default vault: /rhis/vars/vault
```

**Custom parameters**:
```bash
# Use a different SSH user
./build_idm_primary.sh --sshuser root

# Use a different inventory
./build_idm_primary.sh --inventory /path/to/custom/inventory
```

**Manual execution (for debugging)**:
```bash
cd /rhis/rhis-builder-idm
ansible-playbook -i /rhis/vars/external_inventory/inventory \
  --user ansiblerunner \
  --ask-pass \
  --ask-vault-pass \
  --extra-vars "vault_dir=/rhis/vars/vault" \
  --limit=idm_primary \
  main.yml
```

**What this does**:
1. Installs IdM server packages on idm1.example.ca
2. Runs `ipa-server-install` with CA and DNS
3. Configures firewall rules for IdM services
4. Creates initial DNS zones from your configuration
5. Configures Kerberos realm (EXAMPLE.CA)
6. Integrates with Red Hat Subscription Manager

**Duration**: ~15-30 minutes (depending on hardware)

### Step 3: Verify IdM Deployment

```bash
# Get Kerberos ticket
ssh root@idm1.example.ca
kinit admin
# Password: <vault_idm_admin_password>

# Verify IdM status
ipactl status
# All services should be "RUNNING"

# Verify DNS
dig idm1.example.ca @localhost
dig -x 10.0.1.10 @localhost  # Reverse lookup

# Verify CA
ipa ca-find

# List users
ipa user-find

# Check web UI
# Open browser: https://idm1.example.ca
# Login: admin / <vault_idm_admin_password>
```

### Step 4: Configure IdM (Optional)

```bash
# Create additional DNS zones
ansible-playbook /opt/rhis/rhis-builder-idm/configure_dns_zones.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml

# Create sample users and groups
ansible-playbook /opt/rhis/rhis-builder-idm/configure_users.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml

# Create sudo rules
ansible-playbook /opt/rhis/rhis-builder-idm/configure_sudo.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml
```

---

## Phase 3: Deploy Satellite

Satellite becomes the universal provisioner for all infrastructure.

### Step 1: Pre-Deployment Checks

```bash
# Verify Satellite host
ansible -i /opt/rhis/inventory/inventory/hosts.yml satelliteservers -m ping

# Verify DNS from Satellite host
ssh root@satellite1.example.ca "dig idm1.example.ca"
# Should resolve to IdM IP

# Verify IdM is reachable
ssh root@satellite1.example.ca "ping -c 3 idm1.example.ca"
```

### Step 2: Deploy Satellite

```bash
ansible-playbook /opt/rhis/rhis-builder-satellite/deploy_satellite.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml \
  --vault-password-file /opt/rhis/inventory/vault/.vault-pass

# This will:
# 1. Install Satellite packages
# 2. Run satellite-installer
# 3. Register as IdM client (ipa-client-install)
# 4. Run foreman-prepare-realm
# 5. Create HTTP service principal in IdM
# 6. Request certificates from IdM CA
# 7. Configure initial settings
#
# Duration: ~30-60 minutes
```

### Step 3: Upload Satellite Manifest

```bash
# Copy manifest to Satellite server
scp ~/Downloads/rhis-production-manifest.zip root@satellite1.example.ca:/tmp/

# Upload via hammer CLI
ssh root@satellite1.example.ca
hammer subscription upload \
  --file /tmp/rhis-production-manifest.zip \
  --organization "Example Org"

# Verify subscriptions
hammer subscription list --organization "Example Org"
```

### Step 4: Configure Satellite

```bash
# Sync RHEL repositories
ansible-playbook /opt/rhis/rhis-builder-satellite/configure_repos.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml

# Create content views and lifecycle environments
ansible-playbook /opt/rhis/rhis-builder-satellite/configure_content.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml

# Configure compute resources
ansible-playbook /opt/rhis/rhis-builder-satellite/configure_compute.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml

# Create compute profiles
ansible-playbook /opt/rhis/rhis-builder-satellite/configure_profiles.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml

# Create hostgroups
ansible-playbook /opt/rhis/rhis-builder-satellite/configure_hostgroups.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml

# Sync provisioning templates from git
ansible-playbook /opt/rhis/rhis-builder-satellite-templates/sync_templates.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml
```

### Step 5: Verify Satellite

```bash
# Check Satellite health
ssh root@satellite1.example.ca
hammer ping

# Verify IdM integration
hammer realm list
# Should show: EXAMPLE.CA realm

# Verify compute resources
hammer compute-resource list

# Verify hostgroups
hammer hostgroup list

# Check web UI
# Open browser: https://satellite1.example.ca
# Login: admin / <vault_satellite_admin_password>
```

---

## Phase 4: Infrastructure Services

Deploy infrastructure services via Satellite.

### General Provisioning Pattern

All services follow this pattern:

```bash
# 1. Provision host via Satellite
hammer host create \
  --name tang1.example.ca \
  --hostgroup "RHIS NBDE Server" \
  --compute-resource "AWS US-East-1" \
  --compute-profile "Small" \
  --organization "Example Org" \
  --location "Primary DC"

# 2. Wait for provisioning to complete
# Host will:
# - Boot from kickstart
# - Install RHEL
# - Register to Satellite
# - Join IdM realm
# - Run configuration

# 3. Apply service-specific configuration
ansible-playbook /opt/rhis/rhis-builder-nbde/deploy.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml \
  --limit tang1.example.ca
```

### Deploy NBDE (Tang Servers)

```bash
# Configure Tang container specification
# Already in: host_vars/tang1.example.ca/containers.yml

# Provision Tang server via Satellite
hammer host create \
  --name tang1.example.ca \
  --hostgroup "RHIS NBDE Server" \
  --compute-resource "AWS US-East-1" \
  --compute-profile "Small"

# Deploy Tang container
ansible-playbook /opt/rhis/rhis-builder-nbde/containerhost_tang.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml \
  --limit tang1.example.ca

# Verify Tang deployment
curl http://tang1.example.ca:8080/adv
```

### Deploy Ansible Automation Platform

```bash
# Provision AAP server
hammer host create \
  --name aap1.example.ca \
  --hostgroup "RHIS AAP Controller" \
  --compute-resource "AWS US-East-1" \
  --compute-profile "Large"

# Deploy AAP
ansible-playbook /opt/rhis/rhis-builder-aap/deploy.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml \
  --limit aap1.example.ca

# Access AAP UI
# https://aap1.example.ca
```

### Deploy Keycloak

```bash
# Provision Keycloak server
hammer host create \
  --name keycloak1.example.ca \
  --hostgroup "RHIS Keycloak Server" \
  --compute-resource "AWS US-East-1" \
  --compute-profile "Medium"

# Deploy Keycloak
ansible-playbook /opt/rhis/rhis-builder-keycloak/deploy.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml \
  --limit keycloak1.example.ca
```

### Deploy Additional Services

Follow the same pattern for:
- ImageBuilder
- OSCAP scanning servers
- Day-2 ops tooling

---

## Validation

### IdM Validation

```bash
# DNS resolution
dig @idm1.example.ca satellite1.example.ca
dig @idm1.example.ca -x 10.0.1.20

# Kerberos
ssh admin@idm1.example.ca
kinit admin
klist

# LDAP
ldapsearch -x -H ldap://idm1.example.ca -b "dc=example,dc=ca"

# Web UI
curl -k https://idm1.example.ca/ipa/ui/
```

### Satellite Validation

```bash
# Hammer ping
ssh root@satellite1.example.ca "hammer ping"

# Content sync
hammer repository list --organization "Example Org" | grep "Success"

# Compute resources
hammer compute-resource list

# Realm integration
hammer realm list | grep "EXAMPLE.CA"

# Recent provisioned hosts
hammer host list --search "created_at > \"7 days ago\""
```

### Service Validation

```bash
# NBDE
curl http://tang1.example.ca:8080/adv
clevis encrypt tang '{"url":"http://tang1.example.ca:8080"}' <<< "test"

# AAP
curl -k https://aap1.example.ca/api/v2/ping/

# Keycloak
curl -k https://keycloak1.example.ca
```

---

## Troubleshooting

### IdM Issues

#### Issue: IdM installation fails

```bash
# Check logs
ssh root@idm1.example.ca
tail -f /var/log/ipaserver-install.log

# Common causes:
# - Hostname not FQDN
# - Time not synchronized
# - Firewall blocking ports
# - Insufficient memory/disk

# Uninstall and retry
ipa-server-install --uninstall
# Fix issue
# Retry installation
```

#### Issue: DNS not resolving

```bash
# Check named service
ssh root@idm1.example.ca
systemctl status named-pkcs11

# Check zones
ipa dnszone-find

# Check forwarders
ipa dnsforwardzone-find

# Test resolution
dig @localhost example.ca SOA
```

### Satellite Issues

#### Issue: Satellite installation fails

```bash
# Check logs
ssh root@satellite1.example.ca
tail -f /var/log/foreman-installer/satellite.log

# Check services
satellite-maintain service status

# Common causes:
# - Insufficient disk space
# - Memory constraints
# - Network connectivity to IdM
```

#### Issue: Realm enrollment not working

```bash
# Verify realm-capsule user in IdM
ssh root@idm1.example.ca
ipa user-show realm-capsule

# Verify service principal
ipa service-show HTTP/satellite1.example.ca

# Re-run foreman-prepare-realm
ssh root@satellite1.example.ca
foreman-prepare-realm admin realm-capsule
```

### Network Issues

```bash
# Verify firewall ports
# IdM
firewall-cmd --list-all

# Required ports:
# - 80/tcp (HTTP)
# - 443/tcp (HTTPS)
# - 389/tcp (LDAP)
# - 636/tcp (LDAPS)
# - 88/tcp,udp (Kerberos)
# - 464/tcp,udp (Kerberos change password)
# - 53/tcp,udp (DNS)

# Satellite
# - 80/tcp (HTTP)
# - 443/tcp (HTTPS)
# - 5647/tcp (katello-agent)
# - 8000/tcp (provisioning templates)
# - 8140/tcp (Puppet)
# - 9090/tcp (Cockpit)
```

### Getting Help

1. Check logs in `/var/log/`
2. Review [RHIS Architecture Documentation](ARCHITECTURE.md)
3. Review [Dependencies](DEPENDENCIES.md)
4. Open issue in appropriate GitHub repository

---

## Post-Deployment

### Security Hardening

```bash
# Apply OSCAP hardening
ansible-playbook /opt/rhis/rhis-builder-oscap/apply_cis.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml

# Enable YubiKey 2FA for admins
ansible-playbook /opt/rhis/rhis-builder-yubi/configure.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml
```

### Backup Configuration

```bash
# IdM backup
ssh root@idm1.example.ca
ipa-backup

# Satellite backup
ssh root@satellite1.example.ca
satellite-maintain backup offline /var/satellite-backup

# Configuration backup
cd /path/to/rhis-builder-inventory
git add deployments/example.ca/
git commit -m "Production deployment configuration"
git push

# Note: vault/ directory is excluded by .gitignore
# Ensure vault files are backed up separately to secure location
```

### Monitoring

```bash
# Set up monitoring (if using monitoring solution)
# Configure Satellite reports
# Set up AAP job notifications
```

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-29  
**Author**: Claude Sonnet 4.5 (with parmstro)
