variable "resource_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-${substr(replace(var.resource_prefix, "-", ""), 0, 20)}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  # We will use RBAC instead of Access Policies for better management
  enable_rbac_authorization = true

  tags = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = "changeme-in-production" # In a real scenario, this would be generated or passed securely
  key_vault_id = azurerm_key_vault.kv.id
}

output "id" {
  value = azurerm_key_vault.kv.id
}

output "vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
