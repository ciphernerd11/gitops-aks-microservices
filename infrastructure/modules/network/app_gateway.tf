resource "azurerm_public_ip" "gateway" {
  name                = "pip-gw-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(var.tags, { Name = "pip-gw-${var.resource_prefix}" })
}

locals {
  backend_address_pool_name      = "vnet-beap"
  frontend_port_name             = "vnet-feport"
  frontend_ip_configuration_name = "vnet-feip"
  http_setting_name              = "vnet-be-htst"
  listener_name                  = "vnet-httplstn"
  request_routing_rule_name      = "vnet-rqrt"
  redirect_configuration_name    = "vnet-rdrcfg"
}

resource "azurerm_application_gateway" "main" {
  name                = "agw-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.gateway.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1
  }

  lifecycle {
    ignore_changes = [
      tags,
      backend_address_pool,
      backend_http_settings,
      http_listener,
      probe,
      request_routing_rule,
      frontend_port,
      redirect_configuration,
      ssl_certificate,
      url_path_map
    ]
  }

  tags = merge(var.tags, { Name = "agw-${var.resource_prefix}" })
}
