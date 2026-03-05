# ─────────────────────────────────────────────────────
# Outputs — Values needed by CI/CD and deployment
# ─────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Name of the Azure Resource Group"
  value       = azurerm_resource_group.main.name
}

output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "ACR login server URL (e.g. myacr.azurecr.io)"
  value       = azurerm_container_registry.acr.login_server
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_kube_config" {
  description = "Kubeconfig for connecting to AKS (sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "aks_fqdn" {
  description = "FQDN of the AKS API server"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}
