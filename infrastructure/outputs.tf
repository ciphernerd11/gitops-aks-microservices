# ─────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "The login server for the Container Registry"
  value       = module.acr.login_server
}

/*
output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_kube_config" {
  description = "Command to configure kubectl to connect to the new cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}
*/
output "aca_environment_id" {
  description = "The ID of the Azure Container App Environment"
  value       = module.aca_environment.id
}

output "postgresql_fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server"
  value       = module.postgresql.fqdn
}

output "redis_hostname" {
  description = "The hostname of the Managed Redis Cache"
  value       = module.redis.hostname
}

output "aca_identity_id" {
  description = "The ID of the User Assigned Identity for ACA"
  value       = azurerm_user_assigned_identity.aca_identity.id
}
