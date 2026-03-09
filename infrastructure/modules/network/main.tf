resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_cidr
  tags                = var.tags
}

# 1. Gateway Subnet (For Ingress)
resource "azurerm_subnet" "gateway" {
  name                 = "snet-gateway"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

# 2. Application Subnet (For AKS)
resource "azurerm_subnet" "app" {
  count                = length(var.app_subnets_cidr)
  name                 = "snet-app-${format("%02d", count.index + 1)}"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = [var.app_subnets_cidr[count.index]]
  
  # Enable Service Endpoints for enhanced security
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage", "Microsoft.ContainerRegistry"]
}

# 3. Database Subnet (Isolated Data Tier)
resource "azurerm_subnet" "db" {
  count                = length(var.db_subnets_cidr)
  name                 = "snet-db-${format("%02d", count.index + 1)}"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = var.resource_group_name
  address_prefixes     = [var.db_subnets_cidr[count.index]]
}

# ─────────────────────────────────────────────────────
# Network Security Groups (NSGs)
# ─────────────────────────────────────────────────────

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_group" "db" {
  name                = "nsg-db-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_group" "gateway" {
  name                = "nsg-gw-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Association
resource "azurerm_subnet_network_security_group_association" "app" {
  count                     = length(var.app_subnets_cidr)
  subnet_id                 = azurerm_subnet.app[count.index].id
  network_security_group_id = azurerm_network_security_group.app.id
}

resource "azurerm_subnet_network_security_group_association" "db" {
  count                     = length(var.db_subnets_cidr)
  subnet_id                 = azurerm_subnet.db[count.index].id
  network_security_group_id = azurerm_network_security_group.db.id
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# ─────────────────────────────────────────────────────
# Security Rules - APP Tier
# ─────────────────────────────────────────────────────

# Allow traffic ONLY from Gateway (Tier 1) to App (Tier 2)
resource "azurerm_network_security_rule" "allow_gateway_to_app" {
  name                        = "AllowGatewayToApp"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443", "8080"]
  source_address_prefix       = var.gateway_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# Deny Direct Internet Access to App Tier (Everything must go through Gateway)
resource "azurerm_network_security_rule" "deny_direct_internet_to_app" {
  name                        = "DenyDirectInternetToApp"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# ─────────────────────────────────────────────────────
# Security Rules - DB Tier
# ─────────────────────────────────────────────────────

# Allow traffic ONLY from App tier to DB tier
resource "azurerm_network_security_rule" "allow_app_to_db" {
  name                        = "AllowAppToDB"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["5432", "3306", "1433", "6379", "27017"] # Common DB ports
  source_address_prefixes     = var.app_subnets_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

# Strict Deny All for DB Tier
resource "azurerm_network_security_rule" "deny_all_to_db" {
  name                        = "DenyAllToDB"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.db.name
}

# ─────────────────────────────────────────────────────
# Security Rules - Gateway Tier
# ─────────────────────────────────────────────────────

# Allow Internet traffic for Web
resource "azurerm_network_security_rule" "allow_web" {
  name                        = "AllowWebInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.gateway.name
}

# Allow Gateway Manager (MANDATORY for App Gateway V2)
resource "azurerm_network_security_rule" "allow_gateway_manager" {
  name                        = "AllowGatewayManagerInbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.gateway.name
}
