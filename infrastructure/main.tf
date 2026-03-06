# ─────────────────────────────────────────────────────
# Terraform Configuration — Azure Provider
# ─────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }

  #Uncomment and configure for remote state (recommended for teams)
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "disasterrelieftfstate123"
    container_name       = "tfstate"
    key                  = "disaster-relief.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
