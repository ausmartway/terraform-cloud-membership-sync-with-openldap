#!/bin/bash

# LDAP User Management CLI
# Script to add users to OpenLDAP server

set -e

# LDAP Configuration (from your docker-compose.yml)
LDAP_HOST="localhost"
LDAP_PORT="389"
BASE_DN="dc=example,dc=org"
ADMIN_DN="cn=admin,dc=example,dc=org"
ADMIN_PASSWORD="admin"
USERS_OU="ou=users,dc=example,dc=org"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to check if ldap-utils is installed
check_dependencies() {
    if ! command -v ldapadd &> /dev/null; then
        print_error "ldap-utils not found. Please install it:"
        echo "  macOS: brew install openldap"
        echo "  Ubuntu/Debian: sudo apt-get install ldap-utils"
        echo "  RHEL/CentOS: sudo yum install openldap-clients"
        exit 1
    fi
}

# Function to test LDAP connection
test_connection() {
    print_info "Testing LDAP connection..."
    if ldapsearch -x -H "ldap://$LDAP_HOST:$LDAP_PORT" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -b "$BASE_DN" -s base > /dev/null 2>&1; then
        print_success "LDAP connection successful"
        return 0
    else
        print_error "Cannot connect to LDAP server at $LDAP_HOST:$LDAP_PORT"
        print_info "Make sure OpenLDAP container is running: docker compose ps"
        return 1
    fi
}

# Function to check if user exists
user_exists() {
    local username="$1"
    local user_dn="cn=$username,$USERS_OU"
    
    if ldapsearch -x -H "ldap://$LDAP_HOST:$LDAP_PORT" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" -b "$user_dn" -s base > /dev/null 2>&1; then
        return 0  # User exists
    else
        return 1  # User doesn't exist
    fi
}

# Function to generate SSHA password hash
generate_password_hash() {
    local password="$1"
    # Simple base64 encoding for demo - in production use proper SSHA
    echo "{SSHA}$(echo -n "$password" | base64)"
}

# Function to add a new user
add_user() {
    local username="$1"
    local first_name="$2"
    local last_name="$3"
    local email="$4"
    local password="$5"
    
    # Validate inputs
    if [[ -z "$username" || -z "$first_name" || -z "$last_name" || -z "$email" || -z "$password" ]]; then
        print_error "All fields are required: username, first_name, last_name, email, password"
        return 1
    fi
    
    # Check if user already exists
    if user_exists "$username"; then
        print_error "User '$username' already exists"
        return 1
    fi
    
    # Generate password hash
    local password_hash=$(generate_password_hash "$password")
    
    # Create LDIF content
    local ldif_content="dn: cn=$username,$USERS_OU
objectClass: inetOrgPerson
cn: $username
sn: $last_name
givenName: $first_name
mail: $email
userPassword: $password_hash
uid: $username"
    
    print_info "Adding user '$username' to LDAP..."
    
    # Add user to LDAP
    if echo "$ldif_content" | ldapadd -x -H "ldap://$LDAP_HOST:$LDAP_PORT" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD"; then
        print_success "User '$username' added successfully"
        print_info "User Details:"
        echo "  DN: cn=$username,$USERS_OU"
        echo "  Name: $first_name $last_name"
        echo "  Email: $email"
        echo "  UID: $username"
        return 0
    else
        print_error "Failed to add user '$username'"
        return 1
    fi
}

# Function to add user to group
add_user_to_group() {
    local username="$1"
    local groupname="$2"
    
    if [[ -z "$username" || -z "$groupname" ]]; then
        print_error "Username and group name are required"
        return 1
    fi
    
    local user_dn="cn=$username,$USERS_OU"
    local group_dn="cn=$groupname,ou=groups,$BASE_DN"
    
    # Check if user exists
    if ! user_exists "$username"; then
        print_error "User '$username' does not exist"
        return 1
    fi
    
    # Create LDIF to add user to group
    local ldif_content="dn: $group_dn
changetype: modify
add: member
member: $user_dn"
    
    print_info "Adding user '$username' to group '$groupname'..."
    
    if echo "$ldif_content" | ldapmodify -x -H "ldap://$LDAP_HOST:$LDAP_PORT" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD"; then
        print_success "User '$username' added to group '$groupname'"
        return 0
    else
        print_error "Failed to add user '$username' to group '$groupname'"
        return 1
    fi
}

# Function to list all users
list_users() {
    print_info "Listing all users..."
    ldapsearch -x -H "ldap://$LDAP_HOST:$LDAP_PORT" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" \
        -b "$USERS_OU" -s one "(objectClass=inetOrgPerson)" cn givenName sn mail uid | \
        grep -E "^(dn:|cn:|givenName:|sn:|mail:|uid:)" | \
        sed 's/^/  /'
}

# Function to show user details
show_user() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        print_error "Username is required"
        return 1
    fi
    
    local user_dn="cn=$username,$USERS_OU"
    
    print_info "User details for '$username':"
    ldapsearch -x -H "ldap://$LDAP_HOST:$LDAP_PORT" -D "$ADMIN_DN" -w "$ADMIN_PASSWORD" \
        -b "$user_dn" -s base | grep -E "^(dn:|cn:|givenName:|sn:|mail:|uid:)" | sed 's/^/  /'
}

# Function to show usage
show_usage() {
    echo "LDAP User Management CLI"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  add-user <username> <first_name> <last_name> <email> <password>"
    echo "      Add a new user to LDAP"
    echo
    echo "  add-to-group <username> <groupname>"
    echo "      Add existing user to a group (administrators, developers, users)"
    echo
    echo "  list-users"
    echo "      List all users in LDAP"
    echo
    echo "  show-user <username>"
    echo "      Show details for a specific user"
    echo
    echo "  test-connection"
    echo "      Test connection to LDAP server"
    echo
    echo "Examples:"
    echo "  $0 add-user alice.johnson Alice Johnson alice.johnson@example.org password123"
    echo "  $0 add-to-group alice.johnson developers"
    echo "  $0 list-users"
    echo "  $0 show-user alice.johnson"
    echo
}

# Main script logic
main() {
    local command="$1"
    
    # Check dependencies
    check_dependencies
    
    case "$command" in
        "add-user")
            if ! test_connection; then exit 1; fi
            add_user "$2" "$3" "$4" "$5" "$6"
            ;;
        "add-to-group")
            if ! test_connection; then exit 1; fi
            add_user_to_group "$2" "$3"
            ;;
        "list-users")
            if ! test_connection; then exit 1; fi
            list_users
            ;;
        "show-user")
            if ! test_connection; then exit 1; fi
            show_user "$2"
            ;;
        "test-connection")
            test_connection
            ;;
        "help"|"--help"|"-h"|"")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            echo
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
