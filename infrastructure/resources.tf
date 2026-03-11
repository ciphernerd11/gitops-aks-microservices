# ─────────────────────────────────────────────────────
# Local Values & Shared Tags
# ─────────────────────────────────────────────────────

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "tags" {
  source      = "./modules/tag"
  environment = var.environment
  project     = var.project_name
  owner       = var.owner
  cost_center = var.cost_center
}

# ─────────────────────────────────────────────────────
# 1. Base Infrastructure (Group & Network)
# ─────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = merge(module.tags.tags, { Name = "rg-${local.name_prefix}" })
}

module "network" {
  source              = "./modules/network"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_cidr           = var.vnet_cidr
  app_subnets_cidr    = var.app_subnets_cidr
  db_subnets_cidr     = var.db_subnets_cidr
  gateway_subnet_cidr = var.gateway_subnet_cidr
  tags                = module.tags.tags
}

# ─────────────────────────────────────────────────────
# 2. Supporting Services (Governance & Security)
# ─────────────────────────────────────────────────────

module "log_analytics" {
  source              = "./modules/log_analytics"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = module.tags.tags
}

module "keyvault" {
  source              = "./modules/keyvault"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # Passing subnet IDs for Network ACLs
  app_subnet_ids = module.network.app_subnet_ids
  allowed_ips    = var.allowed_ips
  tags           = module.tags.tags
}

# ─────────────────────────────────────────────────────
# 3. Application Hosting (Registry & Cluster)
# ─────────────────────────────────────────────────────

module "acr" {
  source              = "./modules/acr"
  resource_prefix     = local.name_prefix
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  acr_sku             = var.acr_sku
  tags                = module.tags.tags
}

module "aks" {
  source                     = "./modules/aks"
  resource_prefix            = local.name_prefix
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  kubernetes_version         = var.kubernetes_version
  aks_node_count             = var.aks_node_count
  aks_node_vm_size           = var.aks_node_vm_size
  acr_id                     = module.acr.id
  key_vault_id               = module.keyvault.id
  vnet_id                    = module.network.vnet_id
  vnet_subnet_id             = module.network.app_subnet_ids[0]
  gateway_subnet_id          = module.network.gateway_subnet_id
  gateway_id                 = module.network.gateway_id
  log_analytics_workspace_id = module.log_analytics.workspace_id
  tags                       = module.tags.tags
}

# ─────────────────────────────────────────────────────
# 4. GitOps & Application Configuration
# ─────────────────────────────────────────────────────

module "argocd" {
  source                     = "./modules/argocd"
  kubernetes_host            = module.aks.kubernetes_host
  kubelet_identity_client_id = module.aks.kubelet_identity_client_id
  key_vault_name             = module.keyvault.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  subscription_id            = data.azurerm_client_config.current.subscription_id
  resource_group_name        = azurerm_resource_group.main.name
  gateway_name               = module.network.gateway_name
  agic_identity_client_id    = module.aks.agic_identity_client_id
  agic_identity_id           = module.aks.agic_identity_id
  oidc_issuer_url            = module.aks.oidc_issuer_url

  depends_on = [module.aks]
}
