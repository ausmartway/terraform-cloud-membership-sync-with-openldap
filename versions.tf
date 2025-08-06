terraform {
  required_version = ">= 1.0"

  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.51"
    }
  }
}
