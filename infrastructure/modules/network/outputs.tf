output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "The ID of the AKS Subnet"
  value       = azurerm_subnet.aks.id
}
