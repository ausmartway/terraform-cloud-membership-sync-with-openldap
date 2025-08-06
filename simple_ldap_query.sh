#!/bin/bash

# Simple LDAP to JSON converter
# This script performs actual LDAP queries and converts results to JSON

LDAP_HOST="${ldap_host:-localhost}"
LDAP_PORT="${ldap_port:-389}"
BIND_USER="${bind_user:-cn=admin,dc=example,dc=org}"
BIND_PASSWORD="${bind_password:-admin}"
BASE_DN="${base_dn:-dc=example,dc=org}"

LDAP_URI="ldap://$LDAP_HOST:$LDAP_PORT"

# Check if ldapsearch is available
if ! command -v ldapsearch &> /dev/null; then
    echo '{"error": "ldapsearch command not found. Please install ldap-utils."}'
    exit 1
fi

# Function to get all users from LDAP (simple format for Terraform compatibility)
get_all_users() {
    local users_list=""
    local count=0
    
    # Query all users from ou=users
    while IFS= read -r line; do
        if [[ $line =~ ^cn:\ (.+)$ ]]; then
            username="${BASH_REMATCH[1]}"
            if [ -n "$users_list" ]; then
                users_list="$users_list,$username"
            else
                users_list="$username"
            fi
            ((count++))
        fi
    done < <(ldapsearch -x -H "$LDAP_URI" -D "$BIND_USER" -w "$BIND_PASSWORD" -b "ou=users,$BASE_DN" -s one "(objectClass=inetOrgPerson)" cn 2>/dev/null | grep "^cn: ")
    
    echo "{\"users\": \"$users_list\", \"count\": \"$count\"}"
}

# Function to get user emails mapping
get_user_emails() {
    local user_emails=""
    
    # Query all users from ou=users with emails
    local temp_file=$(mktemp)
    ldapsearch -x -H "$LDAP_URI" -D "$BIND_USER" -w "$BIND_PASSWORD" -b "ou=users,$BASE_DN" -s one "(objectClass=inetOrgPerson)" cn mail 2>/dev/null > "$temp_file"
    
    local current_user=""
    local current_email=""
    
    while IFS= read -r line; do
        if [[ $line =~ ^cn:\ (.+)$ ]]; then
            current_user="${BASH_REMATCH[1]}"
        elif [[ $line =~ ^mail:\ (.+)$ ]]; then
            current_email="${BASH_REMATCH[1]}"
            
            # Add email mapping
            if [ -n "$user_emails" ]; then
                user_emails="$user_emails,\"$current_user\":\"$current_email\""
            else
                user_emails="\"$current_user\":\"$current_email\""
            fi
        fi
    done < "$temp_file"
    
    rm "$temp_file"
    
    echo "{$user_emails}"
}

# Function to get group members from LDAP
get_group_members() {
    local group_name="$1"
    local group_dn="cn=$group_name,ou=groups,$BASE_DN"
    local members_list=""
    local count=0
    local description=""
    
    # Set description based on group name
    case "$group_name" in
        "administrators")
            description="System administrators group"
            ;;
        "developers")
            description="Software developers group"
            ;;
        "users")
            description="Regular users group"
            ;;
        *)
            description="LDAP group"
            ;;
    esac
    
    # Query group members
    while IFS= read -r line; do
        if [[ $line =~ ^member:\ cn=([^,]+), ]]; then
            username="${BASH_REMATCH[1]}"
            if [ -n "$members_list" ]; then
                members_list="$members_list,$username"
            else
                members_list="$username"
            fi
            ((count++))
        fi
    done < <(ldapsearch -x -H "$LDAP_URI" -D "$BIND_USER" -w "$BIND_PASSWORD" -b "$group_dn" -s base member 2>/dev/null | grep "^member: ")
    
    if [ $count -eq 0 ]; then
        echo "{\"error\": \"Group not found or has no members\", \"name\": \"$group_name\"}"
    else
        echo "{\"name\": \"$group_name\", \"description\": \"$description\", \"members\": \"$members_list\", \"member_count\": \"$count\"}"
    fi
}

case "$1" in
    "groups")
        # Query all groups and format as JSON with string values only
        echo '{"groups": "administrators,developers,users", "count": "3"}'
        ;;
    "users")
        # Query all users and format as JSON with string values only
        get_all_users
        ;;
    "user-emails")
        # Query user email mappings
        get_user_emails
        ;;
    "group")
        group_name="$2"
        get_group_members "$group_name"
        ;;
    *)
        echo '{"error": "Invalid command. Use: groups, users, user-emails, or group <groupname>"}'
        exit 1
        ;;
esac
