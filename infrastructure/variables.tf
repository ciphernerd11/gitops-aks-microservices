# ─────────────────────────────────────────────────────
# Input Variables
# ─────────────────────────────────────────────────────

variable "project_name" {
  description = "Project name used for naming all resources"
  type        = string
  default     = "disaster-relief"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"
}

variable "aks_node_count" {
  description = "Number of nodes in the default AKS node pool"
  type        = number
  default     = 2
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.29"
}

variable "acr_sku" {
  description = "SKU tier for Azure Container Registry (Basic, Standard, Premium)"
  type        = string
  default     = "Basic"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
