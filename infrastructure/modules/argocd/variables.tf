variable "kubernetes_host" {
  type        = string
  description = "The Kubernetes cluster host URL"
}

variable "kubelet_identity_client_id" {
  type        = string
  description = "The Client ID of the Kubelet Managed Identity"
}

variable "key_vault_name" {
  type        = string
  description = "The name of the Key Vault"
}

variable "tenant_id" {
  type        = string
  description = "The Azure Tenant ID"
}

variable "agic_identity_client_id" {
  type = string
}

variable "agic_identity_id" {
  type = string
}

variable "gateway_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subscription_id" {
  type = string
}
