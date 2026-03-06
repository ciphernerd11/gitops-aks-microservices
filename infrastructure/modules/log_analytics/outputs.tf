output "workspace_id" {
  description = "The Resource ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_name" {
  description = "The Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}
