#!/bin/bash

# Terraform LDAP Management Script
# This script helps with running Terraform operations against the LDAP server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[TERRAFORM]${NC} $1"
}

# Check if LDAP server is running
check_ldap_server() {
    print_info "Checking if LDAP server is running..."
    if ! docker compose ps | grep -q "openldap-server.*Up"; then
        print_error "LDAP server is not running. Please start it first with: docker compose up -d"
        exit 1
    fi
    print_info "LDAP server is running"
}

# Initialize Terraform
terraform_init() {
    print_header "Initializing Terraform..."
    terraform init
}

# Plan Terraform changes
terraform_plan() {
    print_header "Planning Terraform changes..."
    terraform plan
}

# Apply Terraform configuration
terraform_apply() {
    print_header "Applying Terraform configuration..."
    terraform apply -auto-approve
}

# Show Terraform outputs
terraform_outputs() {
    print_header "Showing Terraform outputs..."
    echo
    print_info "All Groups:"
    terraform output -json all_groups | jq '.'
    echo
    print_info "All Users:"
    terraform output -json all_users | jq '.'
    echo
    print_info "Group Membership Summary:"
    terraform output -json group_membership_summary | jq '.'
    echo
    print_info "User to Group Mapping:"
    terraform output -json user_group_mapping | jq '.'
    echo
    print_info "Terraform Cloud Status:"
    terraform output -json terraform_cloud_status | jq '.'
}

# Show Terraform Cloud teams
show_tfe_teams() {
    print_header "Showing Terraform Cloud teams..."
    echo
    print_info "Created Teams:"
    terraform output -json terraform_cloud_teams | jq '.'
    echo
    print_info "Team Mappings:"
    terraform output -json tfe_team_mappings | jq '.'
}

# Enable Terraform Cloud integration
enable_tfe() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        print_error "Usage: $0 enable-tfe <organization> <token>"
        exit 1
    fi
    
    ORG_NAME=$1
    TFE_TOKEN=$2
    
    print_info "Enabling Terraform Cloud integration..."
    print_info "Organization: ${ORG_NAME}"
    
    # Set environment variable for current session
    export TFE_TOKEN="${TFE_TOKEN}"
    
    # Update terraform.tfvars (no longer setting tfe_token variable)
    sed -i.bak "s/create_tfe_teams = false/create_tfe_teams = true/" terraform.tfvars
    sed -i.bak "s/# tfe_organization = .*/tfe_organization = \"${ORG_NAME}\"/" terraform.tfvars
    
    print_info "Set TFE_TOKEN environment variable and updated terraform.tfvars"
    print_info "Note: TFE_TOKEN is set for this session only. For persistent usage, add to your shell profile:"
    print_info "  export TFE_TOKEN=\"${TFE_TOKEN}\""
    print_info "Applying changes..."
    terraform_apply
    show_tfe_teams
}

# Disable Terraform Cloud integration
disable_tfe() {
    print_info "Disabling Terraform Cloud integration..."
    
    # Update terraform.tfvars
    sed -i.bak "s/create_tfe_teams = true/create_tfe_teams = false/" terraform.tfvars
    sed -i.bak "s/tfe_organization = .*/# tfe_organization = \"your-org-name\"/" terraform.tfvars
    
    print_info "Updated terraform.tfvars - applying changes..."
    print_info "Note: TFE_TOKEN environment variable is still set. Unset with: unset TFE_TOKEN"
    terraform_apply
}

# Show specific group information
show_group() {
    if [ -z "$1" ]; then
        print_error "Usage: $0 show-group <group_name>"
        echo "Available groups: administrators, developers, users"
        exit 1
    fi
    
    GROUP_NAME=$1
    print_header "Showing ${GROUP_NAME} group information..."
    terraform output -json "${GROUP_NAME}_group" | jq '.'
}

# Destroy Terraform resources (data sources don't need destruction, but for completeness)
terraform_destroy() {
    print_header "Destroying Terraform resources..."
    terraform destroy -auto-approve
}

# Wait for LDAP server to be ready
wait_for_ldap() {
    print_info "Waiting for LDAP server to be ready..."
    
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ldapsearch -x -H ldap://localhost:389 -D "cn=admin,dc=example,dc=org" -w "admin" -b "dc=example,dc=org" "(objectClass=*)" dn &>/dev/null; then
            print_info "LDAP server is ready!"
            return 0
        fi
        
        print_info "Attempt $attempt/$max_attempts: LDAP server not ready yet, waiting 2 seconds..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "LDAP server failed to become ready after $max_attempts attempts"
    exit 1
}

# Full setup and query
full_setup() {
    check_ldap_server
    wait_for_ldap
    terraform_init
    terraform_apply
    terraform_outputs
}

# Main script logic
case "$1" in
    "check")
        check_ldap_server
        ;;
    "wait")
        wait_for_ldap
        ;;
    "init")
        terraform_init
        ;;
    "plan")
        terraform_plan
        ;;
    "apply")
        terraform_apply
        ;;
    "outputs")
        terraform_outputs
        ;;
    "show-group")
        show_group "$2"
        ;;
    "show-tfe-teams")
        show_tfe_teams
        ;;
    "enable-tfe")
        enable_tfe "$2" "$3"
        ;;
    "disable-tfe")
        disable_tfe
        ;;
    "destroy")
        terraform_destroy
        ;;
    "setup")
        full_setup
        ;;
    *)
        echo "Terraform LDAP Management Script"
        echo "Usage: $0 {check|wait|init|plan|apply|outputs|show-group <name>|show-tfe-teams|enable-tfe <org> <token>|disable-tfe|destroy|setup}"
        echo ""
        echo "Commands:"
        echo "  check                 - Check if LDAP server is running"
        echo "  wait                  - Wait for LDAP server to be ready"
        echo "  init                  - Initialize Terraform"
        echo "  plan                  - Plan Terraform changes"
        echo "  apply                 - Apply Terraform configuration"
        echo "  outputs               - Show all Terraform outputs"
        echo "  show-group <name>     - Show specific group details"
        echo "  show-tfe-teams        - Show Terraform Cloud teams"
        echo "  enable-tfe <org> <token> - Enable Terraform Cloud integration"
        echo "  disable-tfe           - Disable Terraform Cloud integration"
        echo "  destroy               - Destroy Terraform resources"
        echo "  setup                 - Full setup (check, wait, init, apply, outputs)"
        echo ""
        echo "Examples:"
        echo "  $0 setup"
        echo "  $0 outputs"
        echo "  $0 show-group administrators"
        echo "  $0 enable-tfe my-org xxxxxxxxxxxxxxxx.atlasv1.xxxxxxxxxxxxxxxxx"
        echo "  $0 show-tfe-teams"
        exit 1
        ;;
esac
