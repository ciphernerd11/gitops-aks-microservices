output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "app_subnet_ids" {
  description = "List of IDs of the App Subnets"
  value       = azurerm_subnet.app[*].id
}

output "db_subnet_ids" {
  description = "List of IDs of the DB Subnets"
  value       = azurerm_subnet.db[*].id
}

output "gateway_subnet_id" {
  value = azurerm_subnet.gateway.id
}

output "gateway_id" {
  description = "The ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "gateway_name" {
  description = "The Name of the Application Gateway"
  value       = azurerm_application_gateway.main.name
}
