# Local values for processing and transforming LDAP data
locals {
  # Common LDAP configuration
  ldap_uri = var.use_tls ? "ldaps://${var.ldap_host}:${var.ldap_port}" : "ldap://${var.ldap_host}:${var.ldap_port}"
  
  # Parse group data into structured format (using individual data sources)
  groups_data = {
    administrators = {
      name         = data.external.administrators_group.result.name
      description  = data.external.administrators_group.result.description
      members      = split(",", data.external.administrators_group.result.members)
      member_count = tonumber(data.external.administrators_group.result.member_count)
    }
    developers = {
      name         = data.external.developers_group.result.name
      description  = data.external.developers_group.result.description
      members      = split(",", data.external.developers_group.result.members)
      member_count = tonumber(data.external.developers_group.result.member_count)
    }
    users = {
      name         = data.external.users_group.result.name
      description  = data.external.users_group.result.description
      members      = split(",", data.external.users_group.result.members)
      member_count = tonumber(data.external.users_group.result.member_count)
    }
  }

  # Alternative: Parse group data using for_each results
  groups_data_dynamic = {
    for group_name, group_data in data.external.groups : group_name => {
      name         = group_data.result.name
      description  = group_data.result.description
      members      = split(",", group_data.result.members)
      member_count = tonumber(group_data.result.member_count)
    }
  }

  # Flatten all members across all groups (with duplicates)
  all_members_flat = flatten([
    for group_name, group_data in local.groups_data : group_data.members
  ])

  # Get unique members across all groups
  unique_members = toset(local.all_members_flat)

  # Create user-to-groups mapping
  user_groups_mapping = {
    for member in local.unique_members : member => [
      for group_name, group_data in local.groups_data : group_name
      if contains(group_data.members, member)
    ]
  }

  # Summary statistics
  summary_stats = {
    total_groups        = length(local.groups_data)
    total_unique_users  = length(local.unique_members)
    total_memberships   = length(local.all_members_flat)
    avg_members_per_group = length(local.all_members_flat) / length(local.groups_data)
  }

  # Terraform Cloud team mappings
  tfe_team_mappings = var.create_tfe_teams ? {
    for group_name in var.ldap_groups : group_name => {
      team_name    = "${var.team_prefix}${group_name}"
      ldap_group   = group_name
      members      = try(local.groups_data_dynamic[group_name].members, [])
      member_count = try(local.groups_data_dynamic[group_name].member_count, 0)
      team_id      = try(tfe_team.ldap_teams[group_name].id, null)
    }
  } : {}

  # Team creation status - TFE_TOKEN is checked via environment variable
  tfe_enabled = var.create_tfe_teams && var.tfe_organization != null
}
