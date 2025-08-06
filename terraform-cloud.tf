# Terraform Cloud Resources
# This file contains resources for creating teams and memberships in Terraform Cloud based on LDAP groups

# Create teams in Terraform Cloud using for_each
resource "tfe_team" "ldap_teams" {
  for_each = var.create_tfe_teams && var.tfe_organization != null ? toset(var.ldap_groups) : toset([])

  name         = "${var.team_prefix}${each.key}"
  organization = var.tfe_organization
  visibility   = var.team_visibility

  # Use LDAP group description if available
  lifecycle {
    ignore_changes = [
      # Ignore changes to members as they might be managed externally
      # sso_team_id,
    ]
  }

  depends_on = [
    data.external.groups
  ]
}

# Create organization memberships for LDAP users
resource "tfe_organization_membership" "ldap_users" {
  for_each = var.create_tfe_teams && var.create_user_memberships ? var.user_email_mapping : {}

  organization = var.tfe_organization
  email        = each.value

  # Lifecycle to handle cases where users might already exist
  lifecycle {
    ignore_changes = [
      # Ignore changes if user already exists in organization
    ]
  }
}

# Create team memberships for LDAP users
resource "tfe_team_organization_members" "ldap_team_memberships" {
  for_each = var.create_tfe_teams && var.create_user_memberships ? toset(var.ldap_groups) : toset([])

  team_id = tfe_team.ldap_teams[each.key].id
  
  # Get organization membership IDs for users in this LDAP group
  # Note: data.external.groups[each.key].result.members is a comma-separated string
  organization_membership_ids = [
    for username in split(",", data.external.groups[each.key].result.members) : 
    tfe_organization_membership.ldap_users[username].id
    if contains(keys(var.user_email_mapping), username)
  ]

  depends_on = [
    tfe_organization_membership.ldap_users,
    tfe_team.ldap_teams
  ]
}

# Optional: Create team access to workspaces
# This is commented out as it requires workspace configuration
/*
resource "tfe_team_access" "ldap_team_access" {
  for_each = var.create_tfe_teams ? toset(var.ldap_groups) : toset([])

  team_id      = tfe_team.ldap_teams[each.key].id
  workspace_id = var.workspace_id  # This would need to be defined
  access       = "read"  # or "plan", "write", "admin"
}
*/

# Data source to get organization information
data "tfe_organization" "main" {
  count = var.tfe_organization != null ? 1 : 0
  name  = var.tfe_organization
}
