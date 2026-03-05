# ─────────────────────────────────────────────────────
# Local Values
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
# 1. Resource Group
# ─────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

# ─────────────────────────────────────────────────────
# 2. Azure Container Registry (ACR)
# ─────────────────────────────────────────────────────

resource "azurerm_container_registry" "acr" {
  name                = replace("acr${local.resource_prefix}", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────
# 3. Azure Kubernetes Service (AKS)
# ─────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = local.resource_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_vm_size
    os_disk_size_gb     = 30
    enable_auto_scaling = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
  }

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────
# 4. Grant AKS → ACR Pull Permission
# ─────────────────────────────────────────────────────

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
