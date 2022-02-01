provider "azurerm" {
  features {}
}

data "azurerm_log_analytics_workspace" "law" {
  name = "law-jvn-hub-01"
  resource_group_name = "rg-jvn-law-hub-01"
  
}
##Create Networking Resource Group for hub-spoke vnet
resource "azurerm_resource_group" "hub-rg" {
  name     = "rg-${var.prefix}-vnet-hub-weu"
  location = var.location
  tags = {
    "critical" = "yes"
    "solution" = "vnet"
    "costcenter" = "it"
    "environment" = "hub"
    "location" = "weu"
  }
}
resource "azurerm_resource_group" "spoke-rg" {
  name     = "rg-${var.prefix}-vnet-spoke-01"
  location = var.location
  tags = {
    "critical" = "yes"
    "solution" = "vnet"
    "costcenter" = "it"
    "environment" = "spoke"
    "location" = "weu"
  }
}
#VNETs and Subnets
#add custom dns servers from customer
#dns server from Azure and my own dns is also defined here
resource "azurerm_virtual_network" "hub-vnet" {
  name                = "vnet-${var.prefix}-hub-weu"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub-rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["168.63.129.16", "10.5.0.4"]
  tags = {
    "critical" = "yes"
    "solution" = "vnet"
    "costcenter" = "it"
    "environment" = "hub"
    "location" = "weu"
  }
  
}
##Create hub subnets
resource "azurerm_subnet" "hub-snet" {
  name                 = "snet-${var.prefix}-hub-weu-01"
  resource_group_name  = azurerm_resource_group.hub-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.2.0/28"]
}
resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.3.0/26"]
}
##Configure diagnostic settings hub vnet
resource "azurerm_monitor_diagnostic_setting" "hub-diag" {
  name               = "hub-diagsettings"
  target_resource_id = azurerm_virtual_network.hub-vnet.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [azurerm_virtual_network.hub-vnet]
  

log {
  category = "VMProtectionAlerts"
}

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
}
resource "azurerm_virtual_network" "hub-spoke-vnet" {
  name                = "vnet-${var.prefix}-spoke-weu"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
  address_space       = ["10.1.0.0/16"]
  dns_servers         = ["168.63.129.16", "10.5.0.4"]
  tags = {
    "critical" = "yes"
    "solution" = "vnet"
    "costcenter" = "it"
    "environment" = "spoke"
    "location" = "weu"
  }
 
}
##Create Spoke vnet diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "spoke-diag" {
  name               = "spoke-diagsettings"
  target_resource_id = azurerm_virtual_network.hub-spoke-vnet.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [azurerm_virtual_network.hub-spoke-vnet]
  

  log {
    category= "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
}
resource "azurerm_subnet" "spoke-snet-rg" {
  name                 = "snet-${var.prefix}-spoke-weu-01"
  resource_group_name  = azurerm_resource_group.spoke-rg.name
  virtual_network_name = azurerm_virtual_network.hub-spoke-vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}
resource "azurerm_network_security_group" "nsg-spoke" {
  name                = "nsg-${var.prefix}-jvn-spoke-weu-01"
  location            = azurerm_resource_group.spoke-rg.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_monitor_diagnostic_setting" "hub-spoke-diag" {
  name               = "spoke-diagsettings"
  target_resource_id = azurerm_virtual_network.hub-spoke-vnet.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [azurerm_virtual_network.hub-spoke-vnet]
  

  log {
    category= "VMProtectionAlerts"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
}
resource "azurerm_network_security_group" "nsg-hub" {
  name                = "nsg-${var.prefix}-jvn-hub-weu"
  location            = azurerm_resource_group.hub-rg.location
  resource_group_name = azurerm_resource_group.hub-rg.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network_peering" "spoke2hub-peer" {
  name                      = "spoke2hub"
  resource_group_name       = azurerm_resource_group.spoke-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-spoke-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  allow_forwarded_traffic = true
  
}
resource "azurerm_virtual_network_peering" "hub2spoke-peer" {
  name                      = "hub2spoke"
  resource_group_name       = azurerm_resource_group.hub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-spoke-vnet.id
  allow_forwarded_traffic = true
  
}

