variable "resource_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_subnet_ids" {
  type    = list(string)
  default = []
}

variable "allowed_ips" {
  type    = list(string)
  default = []
}

variable "tags" {
  type = map(string)
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-${substr(replace(var.resource_prefix, "-", ""), 0, 20)}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  enable_rbac_authorization = true

  network_acls {
    bypass                     = "AzureServices"
    default_action             = (length(var.app_subnet_ids) > 0 || length(var.allowed_ips) > 0) ? "Deny" : "Allow"
    virtual_network_subnet_ids = var.app_subnet_ids
    ip_rules                   = var.allowed_ips
  }

  public_network_access_enabled = true

  tags = merge(var.tags, { Name = "kv-${substr(replace(var.resource_prefix, "-", ""), 0, 20)}" })

  lifecycle {
    ignore_changes = [
      network_acls[0].ip_rules,
      network_acls[0].virtual_network_subnet_ids
    ]
  }
}

resource "azurerm_role_assignment" "terraform_kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}



output "id" {
  value = azurerm_key_vault.kv.id
}

output "name" {
  value = azurerm_key_vault.kv.name
}

output "vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
