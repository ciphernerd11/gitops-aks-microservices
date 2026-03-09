# ─────────────────────────────────────────────────────
# Local Values & Shared Tags
# ─────────────────────────────────────────────────────

locals {
  resource_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# ─────────────────────────────────────────────────────
# 1. Base Infrastructure (Group & Network)
# ─────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source              = "./modules/network"
  resource_prefix     = local.resource_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_cidr           = var.vnet_cidr
  app_subnets_cidr    = var.app_subnets_cidr
  db_subnets_cidr     = var.db_subnets_cidr
  gateway_subnet_cidr = var.gateway_subnet_cidr
  tags                = local.common_tags
}

# ─────────────────────────────────────────────────────
# 2. Supporting Services (Governance & Security)
# ─────────────────────────────────────────────────────

module "log_analytics" {
  source              = "./modules/log_analytics"
  resource_prefix     = local.resource_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}

  module "keyvault" {
  source              = "./modules/keyvault"
  resource_prefix     = local.resource_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # Passing subnet IDs for Network ACLs
  app_subnet_ids    = module.network.app_subnet_ids
  tags                = local.common_tags
}

# ─────────────────────────────────────────────────────
# 3. Application Hosting (Registry & Cluster)
# ─────────────────────────────────────────────────────

module "acr" {
  source              = "./modules/acr"
  resource_prefix     = local.resource_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  acr_sku             = var.acr_sku
  tags                = local.common_tags
}

module "aks" {
  source                     = "./modules/aks"
  resource_prefix            = local.resource_prefix
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  kubernetes_version         = var.kubernetes_version
  aks_node_count             = var.aks_node_count
  aks_node_vm_size           = var.aks_node_vm_size
  acr_id                     = module.acr.id
  key_vault_id               = module.keyvault.id
  vnet_subnet_id             = module.network.app_subnet_ids[0]
  gateway_subnet_id          = module.network.gateway_subnet_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = local.common_tags
}

