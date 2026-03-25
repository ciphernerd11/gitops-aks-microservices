variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "tags" {
  type = map(string)
}

resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  non_ssl_port_enabled = false
  minimum_tls_version = "1.2"

  tags = merge(var.tags, { Name = "redis-${var.resource_prefix}" })
}

output "id" {
  value = azurerm_redis_cache.main.id
}

output "hostname" {
  value = azurerm_redis_cache.main.hostname
}

output "primary_access_key" {
  value     = azurerm_redis_cache.main.primary_access_key
  sensitive = true
}
