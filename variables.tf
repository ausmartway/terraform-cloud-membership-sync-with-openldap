variable "ldap_host" {
  description = "LDAP server hostname or IP address"
  type        = string
  default     = "localhost"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.ldap_host))
    error_message = "LDAP host must be a valid hostname or IP address."
  }
}

variable "ldap_port" {
  description = "LDAP server port number"
  type        = number
  default     = 389

  validation {
    condition     = var.ldap_port > 0 && var.ldap_port <= 65535
    error_message = "LDAP port must be between 1 and 65535."
  }
}

variable "ldap_base_dn" {
  description = "LDAP base Distinguished Name"
  type        = string
  default     = "dc=example,dc=org"

  validation {
    condition     = can(regex("^(dc=|ou=|cn=)", var.ldap_base_dn))
    error_message = "LDAP base DN must be a valid Distinguished Name."
  }
}

variable "ldap_bind_user" {
  description = "LDAP bind user Distinguished Name for authentication"
  type        = string
  default     = "cn=admin,dc=example,dc=org"

  validation {
    condition     = can(regex("^(cn=|uid=)", var.ldap_bind_user))
    error_message = "LDAP bind user must be a valid Distinguished Name."
  }
}

variable "ldap_bind_password" {
  description = "LDAP bind user password for authentication"
  type        = string
  default     = "admin"
  sensitive   = true

  validation {
    condition     = length(var.ldap_bind_password) >= 4
    error_message = "LDAP bind password must be at least 4 characters long."
  }
}

variable "use_tls" {
  description = "Whether to use TLS/SSL for LDAP connection (LDAPS)"
  type        = bool
  default     = false
}

variable "ldap_groups" {
  description = "List of LDAP groups to query"
  type        = list(string)
  default     = ["administrators", "developers", "users"]

  validation {
    condition     = length(var.ldap_groups) > 0
    error_message = "At least one LDAP group must be specified."
  }

  validation {
    condition = alltrue([
      for group in var.ldap_groups : can(regex("^[a-zA-Z0-9_-]+$", group))
    ])
    error_message = "Group names must contain only alphanumeric characters, underscores, and hyphens."
  }
}

# Terraform Cloud Configuration ✅ TESTED & WORKING
# Note: TFE_TOKEN environment variable is used for authentication
# Successfully tested on August 6, 2025 with organization "yulei"
variable "tfe_organization" {
  description = "Terraform Cloud organization name"
  type        = string
  default     = "yulei"  # Tested working configuration

  validation {
    condition = var.tfe_organization == null || can(regex("^[a-zA-Z0-9-_]+$", var.tfe_organization))
    error_message = "Organization name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "create_tfe_teams" {
  description = "Whether to create teams in Terraform Cloud"
  type        = bool
  default     = true  # Enabled by default - creates teams automatically
}

variable "team_visibility" {
  description = "Visibility of created teams in Terraform Cloud"
  type        = string
  default     = "organization"

  validation {
    condition     = contains(["secret", "organization"], var.team_visibility)
    error_message = "Team visibility must be either 'secret' or 'organization'."
  }
}

variable "team_prefix" {
  description = "Prefix for team names in Terraform Cloud"
  type        = string
  default     = "ldap-"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]*$", var.team_prefix))
    error_message = "Team prefix must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "user_email_mapping" {
  description = "Mapping of LDAP usernames to email addresses for TFC organization membership"
  type        = map(string)
  default = {
    "admin"      = "admin@example.com"
    "john.doe"   = "john.doe@example.com"
    "jane.smith" = "jane.smith@example.com"
    "bob.wilson" = "bob.wilson@example.com"
  }
}

variable "create_user_memberships" {
  description = "Whether to create organization memberships and team memberships for LDAP users"
  type        = bool
  default     = true
}
