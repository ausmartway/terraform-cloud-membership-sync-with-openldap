# OpenLDAP to Terraform Cloud Sync

## Problem Statement

Terraform Clould/Enterprise (TFC/TFE) only support SAML and does not natively support SCIM for user and team management, making it challenging to manage lifecycle of users and teams within TFC/E. Below are some of the limitations:

- **Manual user provisioning** - Admins must manually invite every user
- **No auto-deprovisioning** - Former employees retain access until manually removed
- **Team sync gaps** - Group memberships must be managed manually
- **Scale limitations** - Doesn't work for hundreds/thousands of users

## Solution Overview

While SCIM support is on the roadmap, this project addresses this gap by providing a solution to automate the synchronization of LDAP users/groups with Terraform Cloud users/teams.

The solution demonstrates syncing LDAP users/groups with Terraform Cloud users/teams using Terraform. Some example data is provided to get started quickly.

## Workflow

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

Before running the setup, ensure you have your Terraform Cloud credentials set up in your environment. This is crucial for creating teams and managing memberships.

```bash
export TFE_TOKEN="your-api-token"
export TFE_ORGANIZATION="your-org-name"
```

start the OpenLDAP server and phpLDAPadmin, with preconfigured LDAP groups and users.

```bash
docker compose up -d
```

Apply configuration (TFC integration enabled by default)

```bash
# Ensure you have the latest Terraform version installed
terraform init && terraform plan && terraform apply -auto-approve
```

View created teams

```bash
terraform output terraform_cloud_teams
```

Go to Terraform Cloud and verify the teams are created under your organization.

add an LDAP user to the OpenLDAP server and add it to the `administrators` and `developers` groups:

```bash
./ldap-user-cli.sh add-user alice.johnson Alice Johnson alice.johnson@example.org password123
./ldap-user-cli.sh add-to-group alice.johnson developers
./ldap-user-cli.sh add-to-group alice.johnson administrators
```

Run the Terraform plan and apply command again to sync the new user with Terraform Cloud:

```bash
terraform plan && terraform apply -auto-approve
```

Go to Terraform Cloud and verify the new user is added to the `administrators` and `developers` teams.

Remove a user from 'developers' group:

```bash
./ldap-user-cli.sh remove-from-group alice.johnson developers
```

Run the Terraform plan and apply command again to sync the changes:

```bash
terraform plan && terraform apply -auto-approve
```

Go to Terraform Cloud and verify the user is removed from the `developers` team.

## Components

### LDAP Groups (Preconfigured)

- **administrators**: IT administrators and system managers
- **developers**: Software developers and engineers
- **users**: General organization users

### Sample Users (Preconfigured)

- **john.doe**: Member of administrators and developers
- **jane.smith**: Member of developers and users
- **bob.wilson**: Member of users only

### additional Users

- **alice.johnson**: New user added to administrators and developers

## Management Commands

### Container Operations

```bash
docker compose up -d          # Start OpenLDAP and phpLDAPadmin
docker compose down           # Stop services
docker compose down -v        # Stop and remove containers, networks, and volumes
```

## Prerequisites & Requirements

### Terraform Cloud Setup

- A Terraform Cloud organization
- An API token with team management permissions

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

### Logs

View OpenLDAP logs:

```bash
docker compose logs openldap
```

View phpLDAPadmin logs:

```bash
docker compose logs phpldapadmin
```
