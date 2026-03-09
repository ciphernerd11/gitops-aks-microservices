variable "resource_prefix" {
  description = "Prefix for the AKS cluster and DNS"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "aks_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
}

variable "aks_node_vm_size" {
  description = "VM size for the default node pool"
  type        = string
}

variable "acr_id" {
  description = "ID of the ACR for role assignment"
  type        = string
}

variable "key_vault_id" {
  type = string
}

variable "vnet_subnet_id" {
  description = "The ID of the Subnet where the AKS Cluster should be deployed"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for OMS Agent"
  type        = string
}

variable "tags" {
  description = "Tags for the AKS cluster"
  type        = map(string)
}
