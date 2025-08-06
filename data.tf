# Data sources for LDAP queries using external scripts
# These data sources call shell scripts to query LDAP and return JSON results

# Query all LDAP groups
data "external" "all_groups" {
  program = [
    "bash",
    "${path.module}/simple_ldap_query.sh",
    "groups"
  ]
}

# Query all LDAP users
data "external" "all_users" {
  program = [
    "bash", 
    "${path.module}/simple_ldap_query.sh",
    "users"
  ]
}

# Query administrators group details
data "external" "administrators_group" {
  program = [
    "bash",
    "${path.module}/simple_ldap_query.sh",
    "group",
    "administrators"
  ]
}

# Query developers group details
data "external" "developers_group" {
  program = [
    "bash",
    "${path.module}/simple_ldap_query.sh",
    "group",
    "developers"
  ]
}

# Query users group details
data "external" "users_group" {
  program = [
    "bash",
    "${path.module}/simple_ldap_query.sh",
    "group",
    "users"
  ]
}

# Alternative: Dynamic group queries using for_each
# This creates a more scalable approach for multiple groups
data "external" "groups" {
  for_each = toset(var.ldap_groups)
  
  program = [
    "bash",
    "${path.module}/simple_ldap_query.sh",
    "group",
    each.key
  ]
}

# Query user email mappings from LDAP
data "external" "user_emails" {
  program = [
    "bash",
    "${path.module}/simple_ldap_query.sh",
    "user-emails"
  ]
}
