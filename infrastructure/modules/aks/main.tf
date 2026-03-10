resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.resource_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name           = "default"
    node_count     = var.aks_node_count
    vm_size        = var.aks_node_vm_size
    vnet_subnet_id = var.vnet_subnet_id
    os_disk_size_gb = 30
    temporary_name_for_rotation = "tempnodepool"
  }

  identity {
    type = "SystemAssigned"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "calico"
    dns_service_ip    = "10.100.0.10"
    service_cidr      = "10.100.0.0/16"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # We disable the managed addon and will use a manually defined Application Gateway for stability
  # ingress_application_gateway {
  #   subnet_id = var.gateway_subnet_id
  # }

  tags = merge(var.tags, { Name = "aks-${var.resource_prefix}" })
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_kv_secrets" {
  principal_id                     = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = var.key_vault_id
  skip_service_principal_aad_check = true
}

resource "azurerm_user_assigned_identity" "agic" {
  name                = "id-agic-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_agic_network" {
  principal_id                     = azurerm_user_assigned_identity.agic.principal_id
  role_definition_name             = "Network Contributor"
  scope                            = var.vnet_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_agic_gw" {
  principal_id                     = azurerm_user_assigned_identity.agic.principal_id
  role_definition_name             = "Network Contributor"
  scope                            = var.gateway_id
  skip_service_principal_aad_check = true
}
