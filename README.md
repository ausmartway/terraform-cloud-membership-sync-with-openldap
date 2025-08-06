# OpenLDAP to Terraform Cloud Sync

A complete solution for synchronizing LDAP groups with Terraform Cloud teams using Docker, Terraform, and shell automation.

This project provides an OpenLDAP server with phpLDAPadmin for web-based administration, plus Terraform integration to read LDAP data and create corresponding teams in Terraform Cloud.

## WOrkflow

```text
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   OpenLDAP      │───▶│    Terraform     │───▶│  Terraform Cloud    │
│   - Groups      │    │    - Data        │    │  - Teams            │
│   - Users       │    │    - External    │    │  - Permissions      │
│   - Membership  │    │    - Scripts     │    │  - Workspaces       │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

## Quick Start

### set up TFE related credentials

```bash
# 1. Set your TFC credentials securely
export TFE_TOKEN="your-api-token"
export TFE_ORGANIZATION="your-org-name"

# 2. Start LDAP containers
docker compose up -d

# 3. Apply configuration (TFC integration enabled by default)
terraform apply

# 4. View created teams

```bash
terraform output terraform_cloud_teams
```

## Components

### LDAP Groups (Preconfigured)

- **administrators**: IT administrators and system managers
- **developers**: Software developers and engineers
- **users**: General organization users

### Sample Users (Preconfigured)

- **john.doe**: Member of administrators and developers
- **jane.smith**: Member of developers and users
- **bob.wilson**: Member of users only

## Management Commands

### Container Operations

```bash
./terraform-ldap.sh start          # Start LDAP containers
./terraform-ldap.sh stop           # Stop containers
./terraform-ldap.sh restart        # Restart containers
./terraform-ldap.sh logs           # View container logs
```

## Prerequisites & Requirements

### Terraform Cloud Setup

- A Terraform Cloud organization
- An API token with team management permissions
- Access to create and manage teams

### Required Permissions

The API token needs the following permissions:

- `Manage Teams` - To create and modify teams
- `Read Organization` - To access organization details

### Local Requirements

- Terraform installed
- `jq` installed (for JSON output formatting)
- `ldap-utils` installed (for LDAP connectivity testing)
- Docker and Docker Compose

## Default Configuration

- **LDAP Server**: `localhost:389` (LDAP) / `localhost:636` (LDAPS)
- **Base DN**: `dc=example,dc=org`
- **Admin DN**: `cn=admin,dc=example,dc=org`
- **Admin Password**: `admin`
- **phpLDAPadmin**: `http://localhost:6443`

## Customization

Edit the `.env` file to customize the LDAP configuration:

```env
LDAP_ORGANISATION=Your Company Name
LDAP_DOMAIN=yourdomain.com
LDAP_ADMIN_PASSWORD=your_secure_password
```

## Terraform Files & Structure

- `main.tf` - Provider configuration
- `data.tf` - Data sources for reading LDAP information
- `outputs.tf` - Output definitions for group and user data
- `variables.tf` - Variable definitions
- `locals.tf` - Local value processing
- `terraform.tfvars` - Configuration values
- `terraform-ldap.sh` - Management script

## Available Terraform Outputs

- `all_groups` - All LDAP groups with members
- `all_users` - All LDAP users with details
- `administrators_group` - Administrators group details
- `developers_group` - Developers group details
- `users_group` - Users group details
- `group_membership_summary` - Summary of memberships
- `user_group_mapping` - Users mapped to their groups
- `terraform_cloud_teams` - Created TFC teams information
- `tfe_team_mappings` - Team mapping details

## Troubleshooting

### Stopping the Services

```bash
docker-compose down
```

To remove all data (destructive):

```bash
docker-compose down -v
```

### Logs

View OpenLDAP logs:

```bash
docker compose logs openldap
```

View phpLDAPadmin logs:

```bash
docker compose logs phpldapadmin
```

### Management Script Usage

```bash
# Full setup and display results
./terraform-ldap.sh setup

# Show all outputs
./terraform-ldap.sh outputs

# Show specific group
./terraform-ldap.sh show-group administrators
./terraform-ldap.sh show-group developers
./terraform-ldap.sh show-group users

# Check LDAP server status
./terraform-ldap.sh check
```
