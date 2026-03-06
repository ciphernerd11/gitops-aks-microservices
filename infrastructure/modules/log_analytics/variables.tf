variable "resource_prefix" {
  description = "Prefix for the Log Analytics Workspace"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location for the Log Analytics Workspace"
  type        = string
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
}
