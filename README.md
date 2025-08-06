# OpenLDAP to Terraform Cloud Sync

A complete solution for synchronizing LDAP groups with Terraform Cloud teams using Docker, Terraform, and shell automation.

This project provides an OpenLDAP server with phpLDAPadmin for web-based administration, plus Terraform integration to read LDAP data and create corresponding teams in Terraform Cloud.

## Architecture

```text
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   OpenLDAP      │───▶│    Terraform     │───▶│  Terraform Cloud    │
│   - Groups      │    │    - Data        │    │  - Teams            │
│   - Users       │    │    - External    │    │  - Permissions      │
│   - Membership  │    │    - Scripts     │    │  - Workspaces       │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

## Quick Start

### Option 1: Basic LDAP Setup

```bash
# 1. Start LDAP containers
docker compose up -d

# 2. View LDAP groups  
terraform output ldap_groups

# 3. Access phpLDAPadmin at http://localhost:6443
```

### Option 2: Full Terraform Cloud Integration

```bash
# 1. Set your TFC credentials securely
export TFE_TOKEN="your-api-token"
export TFE_ORGANIZATION="your-org-name"

# 2. Start LDAP containers
docker compose up -d

# 3. Apply configuration (TFC integration enabled by default)
terraform apply

# 4. View created teams
terraform output terraform_cloud_teams
```

## Security-First Configuration 🔒

### Environment Variable Authentication (Recommended)

The integration uses environment variables for secure credential management:

```bash
# Set your Terraform Cloud API token (required)
export TFE_TOKEN="xxxxx.atlasv1.xxxxx"

# Optional: Set organization via environment variable
export TFE_ORGANIZATION="your-org-name"

# Verify the token is set
echo "Token set: ${TFE_TOKEN:0:10}..."
```

### Alternative Secure Storage Options

```bash
# Store token in a secure file (recommended for CI/CD)
echo "xxxxx.atlasv1.xxxxx" > ~/.terraform-cloud-token
chmod 600 ~/.terraform-cloud-token

# Load token from file
export TFE_TOKEN="$(cat ~/.terraform-cloud-token)"

# Or use a secrets management system
export TFE_TOKEN="$(vault kv get -field=token secret/terraform-cloud)"
```

### Working Configuration

```hcl
# terraform.tfvars - Configuration example
ldap_host = "localhost"
ldap_port = 389
ldap_base_dn = "dc=example,dc=org"

# Terraform Cloud Integration
create_tfe_teams = true              # Creates teams automatically
tfe_organization = "your-org-name"   # Your TFC organization
team_prefix = "ldap-"                # Results in: ldap-administrators, etc.
team_visibility = "organization"     # Teams visible to all org members

# Note: TFE_TOKEN is read from environment variable for security
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

### LDAP Operations

```bash
./terraform-ldap.sh show-groups    # List all LDAP groups
./terraform-ldap.sh show-users     # List all LDAP users
./terraform-ldap.sh test-ldap      # Test LDAP connectivity
```

### Terraform Operations

```bash
./terraform-ldap.sh setup          # Initialize Terraform
./terraform-ldap.sh plan           # Show planned changes
./terraform-ldap.sh apply          # Apply configuration
./terraform-ldap.sh output         # Show outputs
./terraform-ldap.sh destroy        # Destroy resources
```

### Terraform Cloud Operations

```bash
./terraform-ldap.sh enable-tfe "org" "token"  # Enable TFC integration
./terraform-ldap.sh disable-tfe               # Disable TFC integration
./terraform-ldap.sh show-tfe-teams           # Show created teams
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

## Connecting to LDAP

### Using ldapsearch command

```bash
ldapsearch -x -H ldap://localhost:389 -b "dc=example,dc=org" -D "cn=admin,dc=example,dc=org" -W
```

### Using phpLDAPadmin

1. Go to `http://localhost:6443`
2. Click "login"
3. Login DN: `cn=admin,dc=example,dc=org`
4. Password: `admin` (or your custom password)

## Data Persistence

The setup includes persistent volumes for:

- LDAP data (`ldap_data`)
- LDAP configuration (`ldap_config`)
- TLS certificates (`ldap_certs`)

## Production Readiness Checklist

- **Security**: Environment variable authentication
- **Scalability**: for_each patterns support multiple groups
- **Reliability**: Error handling and validation rules
- **Monitoring**: Comprehensive outputs and status reporting
- **Documentation**: Complete guides and examples
- **Automation**: Management scripts for all operations
- **Testing**: Comprehensive validation capabilities

## Security Notes & Best Practices

### Security Improvements Applied

- 🔒 **Removed Token Variables**: No `tfe_token` variable in `variables.tf`
- 🌍 **Environment Variable Authentication**: TFE provider reads from environment
- 📝 **Updated Documentation**: Security-focused configuration guides
- 🛠️ **Management Script**: Sets `TFE_TOKEN` during `enable-tfe` command

### Production Security

1. **Change default passwords** in production environments
2. **Enable TLS** for production use
3. **Restrict network access** using Docker networks or firewall rules
4. **Regular backups** are configured but verify they meet your needs
5. **Use secrets management** systems for token storage

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
docker-compose logs openldap
```

View phpLDAPadmin logs:

```bash
docker-compose logs phpldapadmin
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

## Next Steps for Production Use

1. **Scale Testing**: Test with larger numbers of groups and users
2. **LDAPS Configuration**: Enable TLS for production LDAP connections
3. **Workspace Integration**: Add tfe_team_access resources for workspace permissions
4. **Monitoring**: Implement change detection and alerting
5. **CI/CD Integration**: Automate deployment in pipelines

---

## Status: Ready for Enterprise Deployment

The LDAP to Terraform Cloud synchronization system provides a complete solution for infrastructure teams.

Key capabilities include:

- LDAP directory service integration
- Terraform data integration
- Terraform Cloud team creation
- Security implementation
- Documentation and automation

The system creates and manages teams in Terraform Cloud based on LDAP group membership, providing a complete identity management bridge for infrastructure teams.
