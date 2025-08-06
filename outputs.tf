# Output all groups with their details
output "all_groups" {
  description = "List of all LDAP groups"
  value = {
    groups_list = split(",", data.external.all_groups.result.groups)
    total_count = tonumber(data.external.all_groups.result.count)
  }
}

# Output all users
output "all_users" {
  description = "List of all LDAP users"
  value = {
    users_list  = split(",", data.external.all_users.result.users)
    total_count = tonumber(data.external.all_users.result.count)
  }
}

# Output administrators group details
output "administrators_group" {
  description = "Details of the administrators group"
  value = {
    name         = data.external.administrators_group.result.name
    description  = data.external.administrators_group.result.description
    members      = split(",", data.external.administrators_group.result.members)
    member_count = tonumber(data.external.administrators_group.result.member_count)
  }
}

# Output developers group details
output "developers_group" {
  description = "Details of the developers group"
  value = {
    name         = data.external.developers_group.result.name
    description  = data.external.developers_group.result.description
    members      = split(",", data.external.developers_group.result.members)
    member_count = tonumber(data.external.developers_group.result.member_count)
  }
}

# Output users group details
output "users_group" {
  description = "Details of the users group"
  value = {
    name         = data.external.users_group.result.name
    description  = data.external.users_group.result.description
    members      = split(",", data.external.users_group.result.members)
    member_count = tonumber(data.external.users_group.result.member_count)
  }
}

# Output comprehensive group membership summary
output "group_membership_summary" {
  description = "Comprehensive summary of all group memberships"
  value = {
    total_groups = tonumber(data.external.all_groups.result.count)
    total_users  = tonumber(data.external.all_users.result.count)
    groups = {
      administrators = {
        description  = data.external.administrators_group.result.description
        members      = split(",", data.external.administrators_group.result.members)
        member_count = tonumber(data.external.administrators_group.result.member_count)
      }
      developers = {
        description  = data.external.developers_group.result.description
        members      = split(",", data.external.developers_group.result.members)
        member_count = tonumber(data.external.developers_group.result.member_count)
      }
      users = {
        description  = data.external.users_group.result.description
        members      = split(",", data.external.users_group.result.members)
        member_count = tonumber(data.external.users_group.result.member_count)
      }
    }
  }
}

# Output user-to-groups mapping
output "user_groups_mapping" {
  description = "Mapping of users to their group memberships"
  value       = local.user_groups_mapping
}

# Output summary statistics
output "ldap_statistics" {
  description = "Statistical summary of LDAP data"
  value       = local.summary_stats
}

# Output LDAP connection info (non-sensitive)
output "ldap_connection_info" {
  description = "LDAP connection information"
  value = {
    ldap_uri  = local.ldap_uri
    base_dn   = var.ldap_base_dn
    use_tls   = var.use_tls
    bind_user = var.ldap_bind_user
  }
}

# Output using for_each data sources (dynamic approach)
output "groups_dynamic" {
  description = "All groups queried using for_each (dynamic approach)"
  value = {
    for group_name, group_data in data.external.groups : group_name => {
      name         = group_data.result.name
      description  = group_data.result.description
      members      = split(",", group_data.result.members)
      member_count = tonumber(group_data.result.member_count)
    }
  }
}

# Output group names from for_each
output "dynamic_group_names" {
  description = "Names of groups queried dynamically"
  value       = keys(data.external.groups)
}

# Output comparison showing both approaches
output "groups_comparison" {
  description = "Comparison between static and dynamic approaches"
  value = {
    static_groups  = local.groups_data
    dynamic_groups = local.groups_data_dynamic
    groups_match   = local.groups_data == local.groups_data_dynamic
  }
}

# Terraform Cloud team outputs
output "terraform_cloud_teams" {
  description = "Created Terraform Cloud teams"
  value = var.create_tfe_teams ? {
    for team_name, team_resource in tfe_team.ldap_teams : team_name => {
      id           = team_resource.id
      name         = team_resource.name
      organization = team_resource.organization
      visibility   = team_resource.visibility
      url          = "https://app.terraform.io/app/${team_resource.organization}/teams/${team_resource.id}"
    }
  } : {}
}

output "tfe_team_mappings" {
  description = "Mapping between LDAP groups and Terraform Cloud teams"
  value       = local.tfe_team_mappings
}

output "terraform_cloud_status" {
  description = "Status of Terraform Cloud integration"
  value = {
    enabled             = local.tfe_enabled
    organization        = var.tfe_organization
    teams_created       = var.create_tfe_teams ? length(tfe_team.ldap_teams) : 0
    users_invited       = var.create_user_memberships ? length(tfe_organization_membership.ldap_users) : 0
    team_memberships    = var.create_user_memberships ? length(tfe_team_organization_members.ldap_team_memberships) : 0
    team_prefix         = var.team_prefix
    team_visibility     = var.team_visibility
  }
}

# Organization memberships output
output "tfe_organization_memberships" {
  description = "TFC organization memberships created for LDAP users"
  value = var.create_tfe_teams && var.create_user_memberships ? {
    for username, membership in tfe_organization_membership.ldap_users : username => {
      id           = membership.id
      email        = membership.email
      username     = membership.username
      user_id      = membership.user_id
      organization = membership.organization
    }
  } : {}
}

# Team memberships output  
output "tfe_team_memberships" {
  description = "TFC team memberships for LDAP groups"
  value = var.create_tfe_teams && var.create_user_memberships ? {
    for group_name, team_membership in tfe_team_organization_members.ldap_team_memberships : group_name => {
      team_name    = tfe_team.ldap_teams[group_name].name
      team_id      = team_membership.team_id
      member_count = length(team_membership.organization_membership_ids)
      member_ids   = team_membership.organization_membership_ids
      ldap_members = [
        for username in split(",", data.external.groups[group_name].result.members) :
        username if contains(keys(var.user_email_mapping), username)
      ]
    }
  } : {}
}
