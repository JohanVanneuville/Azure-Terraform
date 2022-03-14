provider "azurerm" {
  features {}
}

data "azurerm_log_analytics_workspace" "law" {
  name = "law-hub-jvn-01"
  resource_group_name = "rg-hub-jvn-law-01"
}
##Create Networking Resource Group for hub-spoke vnet
resource "azurerm_resource_group" "vnet-hub-rg" {
  name     = "rg-hub-${var.prefix}-vnet-01"
  location = var.location
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Vnet"
    "Costcenter"  = "It"
    "Environment" = "Hub"
    "Location"    = "Weu"
  }
}
resource "azurerm_resource_group" "vnet-prod-rg" {
  name     = "rg-prod-${var.prefix}-vnet-01"
  location = var.location
 tags = {
    "Critical"    = "Yes"
    "Solution"    = "Vnet"
    "Costcenter"  = "It"
    "Environment" = "Prod"
    "Location"    = "Weu"
  }
}
resource "azurerm_resource_group" "vnet-dev-rg" {
  name     = "rg-dev-${var.prefix}-vnet-01"
  location = var.location
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Vnet"
    "Costcenter"  = "It"
    "Environment" = "Dev"
    "Location"    = "Weu"
  }
}
resource "azurerm_resource_group" "vnet-tst-rg" {
  name     = "rg-tst-${var.prefix}-vnet-01"
  location = var.location
 tags = {
    "Critical"    = "Yes"
    "Solution"    = "Vnet"
    "Costcenter"  = "It"
    "Environment" = "Test"
    "Location"    = "Weu"
  }
}
#VNETs and Subnets
#add custom dns servers from customer
#dns server from Azure and my own dns is also defined here
resource "azurerm_virtual_network" "hub-vnet" {
  name                = "vnet-hub-${var.prefix}-weu-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.vnet-hub-rg.name
  address_space       = ["10.0.0.0/20"]
  dns_servers         = ["10.5.0.4","168.63.129.16"]
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Vnet"
    "Costcenter"  = "It"
    "Environment" = "Hub"
    "Location"    = "Weu"
  }
}
resource "azurerm_virtual_network" "prod-vnet" {
  name                = "vnet-prod-${var.prefix}-weu-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.vnet-prod-rg.name
  address_space       = ["10.1.0.0/20"]
  dns_servers         = ["10.5.0.4","168.63.129.16"]
 tags = {
    "Critical"    = "Yes"
    "Solution"    = "Vnet"
    "Costcenter"  = "It"
    "Environment" = "Prod"
    "Location"    = "Weu"
  }
}
resource "azurerm_virtual_network" "dev-vnet" {
  name                = "vnet-dev-${var.prefix}-weu-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.vnet-dev-rg.name
  address_space       = ["10.2.0.0/20"]
  dns_servers         = ["10.5.0.4","168.63.129.16"]
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Vnet"
    "Costcenter"  = "It"
    "Environment" = "Dev"
    "Location"    = "Weu"
  }
}
resource "azurerm_virtual_network" "tst-vnet" {
  name                = "vnet-tst-${var.prefix}-weu-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.vnet-tst-rg.name
  address_space       = ["10.3.0.0/20"]
  dns_servers         = ["10.5.0.4","168.63.129.16"]
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Vnet"
    "Costcenter"  = "It"
    "Environment" = "Test"
    "Location"    = "Weu"
  }
}
##Create hub subnets
resource "azurerm_subnet" "hub-snet-management" {
  name                 = "snet-${var.prefix}-hub-weu-management"
  resource_group_name  = azurerm_resource_group.vnet-hub-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.2.0/28"]
}
resource "azurerm_subnet" "hub-snet-gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.vnet-hub-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.4.0/27"]
}
resource "azurerm_subnet" "bastion-subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.vnet-hub-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.3.0/26"]
}
resource "azurerm_subnet" "firewall-subnet" {
  name                 = "AzureFirewallSubnet" ##can also be AzureFirewallManagementSubnet
  resource_group_name  = azurerm_resource_group.vnet-hub-rg.name
  virtual_network_name = azurerm_virtual_network.hub-vnet.name
  address_prefixes     = ["10.0.5.0/26"]
}
##Configure diagnostic settings vnets
resource "azurerm_monitor_diagnostic_setting" "vnet-hub-diag" {
  name               = "diag-hub-${var.prefix}-vnet"
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
resource "azurerm_monitor_diagnostic_setting" "vnet-prod-diag" {
  name               = "diag-prod-${var.prefix}-vnet"
  target_resource_id = azurerm_virtual_network.prod-vnet.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [azurerm_virtual_network.prod-vnet]
  

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
resource "azurerm_monitor_diagnostic_setting" "vnet-dev-diag" {
  name               = "diag-dev-${var.prefix}-vnet"
  target_resource_id = azurerm_virtual_network.dev-vnet.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [azurerm_virtual_network.dev-vnet]
  

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
resource "azurerm_monitor_diagnostic_setting" "vnet-tst-diag" {
  name               = "diag-tst-${var.prefix}-vnet"
  target_resource_id = azurerm_virtual_network.tst-vnet.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [azurerm_virtual_network.tst-vnet]
  

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

resource "azurerm_network_security_group" "nsg-hub" {
  name                = "nsg-hub-${var.prefix}-01"
  location            = azurerm_resource_group.vnet-hub-rg.location
  resource_group_name = azurerm_resource_group.vnet-hub-rg.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "nsg-prod" {
  name                = "nsg-prod-${var.prefix}-01"
  location            = azurerm_resource_group.vnet-prod-rg.location
  resource_group_name = azurerm_resource_group.vnet-prod-rg.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "nsg-dev" {
  name                = "nsg-dev-${var.prefix}-01"
  location            = azurerm_resource_group.vnet-dev-rg.location
  resource_group_name = azurerm_resource_group.vnet-dev-rg.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "nsg-tst" {
  name                = "nsg-tst-${var.prefix}-01"
  location            = azurerm_resource_group.vnet-tst-rg.location
  resource_group_name = azurerm_resource_group.vnet-tst-rg.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_virtual_network_peering" "peer-hub-2-prod" {
  name                      = "peer-hub-2-prod"
  resource_group_name       = azurerm_resource_group.vnet-hub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.prod-vnet.id 
}
resource "azurerm_virtual_network_peering" "peer-prod-2-hub" {
  name                      = "peer-prod-2-hub"
  resource_group_name       = azurerm_resource_group.vnet-prod-rg.name
  virtual_network_name      = azurerm_virtual_network.prod-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id 
}
resource "azurerm_virtual_network_peering" "peer-hub-2-dev" {
  name                      = "peer-hub-2-dev"
  resource_group_name       = azurerm_resource_group.vnet-hub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.dev-vnet.id 
  allow_forwarded_traffic = true
}
resource "azurerm_virtual_network_peering" "peer-dev-2-hub" {
  name                      = "peer-dev-2-hub"
  resource_group_name       = azurerm_resource_group.vnet-dev-rg.name
  virtual_network_name      = azurerm_virtual_network.dev-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id 
  allow_forwarded_traffic = true
}
resource "azurerm_virtual_network_peering" "peer-hub-2-tst" {
  name                      = "peer-hub-2-tst"
  resource_group_name       = azurerm_resource_group.vnet-hub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.tst-vnet.id 
  allow_forwarded_traffic = true
}
resource "azurerm_virtual_network_peering" "peer-tst-2-hub" {
  name                      = "peer-tst-2-hub"
  resource_group_name       = azurerm_resource_group.vnet-tst-rg.name
  virtual_network_name      = azurerm_virtual_network.tst-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id 
  allow_forwarded_traffic = true
}

resource "azurerm_network_watcher" "network-watcher-hub" {
  name = "nw-${var.prefix}-vnet-we-01"
  location = azurerm_resource_group.vnet-hub-rg.location
  resource_group_name = azurerm_resource_group.vnet-hub-rg.name
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Vnet"
    "Costcenter"  = "It"
    "Location"    = "Weu"
  }
}
resource "azurerm_monitor_diagnostic_setting" "nsg-Hub" {
  name               = "diag-hub-${var.prefix}-nsg"
  target_resource_id = azurerm_network_security_group.nsg-hub.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [azurerm_network_security_group.nsg-hub]
  

log {
    category = "NetworkSecurityGroupEvent"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "NetworkSecurityGroupRuleCounter"
    enabled = true

    retention_policy {
      enabled =true
    }
  }
}
resource "azurerm_monitor_diagnostic_setting" "nsg-diag-prod" {
  name = "diag-prod-${var.prefix}-nsg"
  target_resource_id = azurerm_network_security_group.nsg-prod.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  log {
    category = "NetworkSecurityGroupEvent"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "NetworkSecurityGroupRuleCounter"
    enabled = true

    retention_policy {
      enabled =true
    }
  }
}
resource "azurerm_monitor_diagnostic_setting" "nsg-diag-dev" {
  name = "diag-dev-${var.prefix}-nsg"
  target_resource_id = azurerm_network_security_group.nsg-dev.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  log {
    category = "NetworkSecurityGroupEvent"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "NetworkSecurityGroupRuleCounter"
    enabled = true

    retention_policy {
      enabled =true
    }
  }
}
resource "azurerm_monitor_diagnostic_setting" "nsg-diag-test" {
  name = "diag-tst-${var.prefix}-nsg"
  target_resource_id = azurerm_network_security_group.nsg-tst.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  log {
    category = "NetworkSecurityGroupEvent"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "NetworkSecurityGroupRuleCounter"
    enabled = true

    retention_policy {
      enabled =true
    }
  }
}
