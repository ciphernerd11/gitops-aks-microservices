output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "kubernetes_host" {
  description = "The Kubernetes cluster host URL"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 encoded public certificate used by clients to authenticate to the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Base64 encoded private key used by clients to authenticate to the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded public CA certificate used by the Kubernetes cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kube_config" {
  description = "Raw Kubernetes config to be used by kubectl and other compatible tools"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kubelet_identity_client_id" {
  description = "The Client ID of the Kubelet Managed Identity"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].client_id
}
output "agic_identity_client_id" {
  description = "The Client ID of the AGIC User Assigned Identity"
  value       = azurerm_user_assigned_identity.agic.client_id
}

output "agic_identity_id" {
  description = "The ID of the AGIC User Assigned Identity"
  value       = azurerm_user_assigned_identity.agic.id
}
