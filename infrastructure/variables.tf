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
  default     = "1.33.7"
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

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "app_subnets_cidr" {
  description = "CIDR blocks for the App Subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "db_subnets_cidr" {
  description = "CIDR blocks for the DB Subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}
