# Main configuration file
# Provider configurations are defined in versions.tf

# Configure Terraform Cloud provider
# Uses TFE_TOKEN environment variable for authentication
provider "tfe" {
  # token is read from TFE_TOKEN environment variable
  # This is more secure than storing tokens in configuration files
}
