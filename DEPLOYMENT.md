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
  - Ansible Automation Platform (optional)
- Cloud credentials (if deploying to AWS/Azure/GCP):
  - AWS: IAM user with appropriate permissions
  - Azure: Service principal
  - GCP: Service account
- On-premise access (if deploying to KVM/bare metal):
  - Hypervisor access
  - Network configuration capability
  - Storage provisioning

### Required Tools

On your workstation:
```bash
# Required
- git
- podman or docker
- SSH client
- Text editor (VS Code recommended)

# Optional but helpful
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

```bash
# 1. Clone inventory repository
git clone https://github.com/parmstro/rhis-builder-inventory
cd rhis-builder-inventory

# 2. Generate deployment for your domain
cd inventory_template
./generate_deployment.sh yourdomain.com

# 3. Edit generated configuration
cd ../generated/yourdomain.com
# Edit host_vars/, group_vars/, inventory/ with your settings

# 4. Encrypt secrets with Ansible Vault
ansible-vault create vault/credentials.yml
# Add: registry credentials, admin passwords, cloud credentials

# 5. Launch provisioner container
./launch-container.sh

# 6. Inside container - Deploy in order:
# a) Landing zone (creates hosts)
./deploy-landing-zone.sh aws  # or azure, gcp, kvm, baremetal

# b) IdM (identity and DNS)
./deploy-idm.sh

# c) Satellite (universal provisioner)
./deploy-satellite.sh

# d) Infrastructure services
./deploy-nbde.sh
./deploy-aap.sh
# ... etc
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

### Step 4: Clone Inventory Repository

```bash
git clone https://github.com/parmstro/rhis-builder-inventory
cd rhis-builder-inventory
```

### Step 5: Generate Deployment Configuration

```bash
cd inventory_template

# Generate configuration for your domain
./generate_deployment.sh example.ca

# This creates:
# ../generated/example.ca/
#   ├── inventory/
#   ├── host_vars/
#   ├── group_vars/
#   ├── templates/
#   ├── vault/
#   └── launch-container.sh
```

### Step 6: Customize Configuration

```bash
cd ../generated/example.ca
```

#### Edit Inventory

```bash
vim inventory/hosts.yml
```

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
cd /path/to/rhis-builder-inventory/generated/example.ca
./launch-container.sh
```

This launches the rhis-provisioner container with your inventory mounted.

### Step 3: Deploy Landing Zone

Inside the container:

#### AWS Example

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Deploy landing zone
ansible-playbook /opt/rhis/rhis-builder-aws-lz/deploy.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml \
  --vault-password-file /opt/rhis/inventory/vault/.vault-pass

# Expected output:
# - VPC created
# - Subnets created
# - Security groups configured
# - EC2 instances: idm1.example.ca, satellite1.example.ca
# - Instances accessible via SSH
```

#### KVM Example

```bash
# Verify KVM connection
virsh -c qemu+ssh://root@kvm-host.example.ca/system list

# Deploy landing zone
ansible-playbook /opt/rhis/rhis-builder-kvm-lz/deploy.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml \
  --vault-password-file /opt/rhis/inventory/vault/.vault-pass

# Expected output:
# - libvirt network configured
# - Storage pool created
# - VMs created: idm1.example.ca, satellite1.example.ca
# - VMs running and accessible
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

```bash
# Verify IdM host is accessible
ansible -i /opt/rhis/inventory/inventory/hosts.yml idmservers -m ping

# Verify hostname resolution
ssh root@idm1.example.ca "hostname -f"
# Should return: idm1.example.ca

# Verify time sync
ssh root@idm1.example.ca "timedatectl"
# Time should be synchronized
```

### Step 2: Deploy IdM Primary

```bash
ansible-playbook /opt/rhis/rhis-builder-idm/deploy_idm_primary.yml \
  -i /opt/rhis/inventory/inventory/hosts.yml \
  --vault-password-file /opt/rhis/inventory/vault/.vault-pass \
  -e "idm_admin_password={{ vault_idm_admin_password }}" \
  -e "idm_dm_password={{ vault_idm_dm_password }}"

# This will:
# 1. Install IdM server packages
# 2. Run ipa-server-install with CA and DNS
# 3. Configure firewall rules
# 4. Create initial DNS zones
# 5. Configure Kerberos realm
#
# Duration: ~15-30 minutes
```

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
git add generated/example.ca/
git commit -m "Production deployment configuration"
git push
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
