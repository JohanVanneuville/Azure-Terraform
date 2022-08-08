provider "azurerm" {
  features {} 
}

provider "azurerm" {
  features {}
  alias = "hub"
  subscription_id = ""
}
provider "azurerm" {
  features {}
  alias = "prod"
  subscription_id = ""
}
data "azurerm_virtual_network" "hub" {
   provider = azurerm.hub
  name = "vnet-hub-${var.prefix}-we-01"
  resource_group_name = "rg-hub-${var.prefix}-networking-01"
}

data "azurerm_firewall" "fw" {
  provider = azurerm.hub
    name = "fw-hub-${var.prefix}-01"
    resource_group_name = "rg-hub-${var.prefix}-networking-01"  
}
data "azurerm_subnet" "avd-prd" {
  provider = azurerm.hub
    name = "snet-avd-${var.prefix}-prd-01"
    virtual_network_name = "vnet-avd-jvn-we-01"
    resource_group_name = "rg-avd-${var.prefix}-networking-01"
}
data "azurerm_virtual_network" "avd-vnet" {
  provider = azurerm.hub
    name = "vnet-avd-${var.prefix}-we-01"
    resource_group_name = "rg-avd-${var.prefix}-networking-01"
}

##Firewall policy

resource "azurerm_firewall_policy" "fw-policy" {
  provider = azurerm.hub
  name = "policy-avd-${var.prefix}-fw-01"
  resource_group_name = data.azurerm_virtual_network.hub.resource_group_name
  location = data.azurerm_virtual_network.hub.location
  
}
resource "azurerm_firewall_policy_rule_collection_group" "avd-policy" {
  provider = azurerm.hub
  name               = "policy-prd-${var.prefix}-avd-01"
  firewall_policy_id = azurerm_firewall_policy.fw-policy.id
  priority           = 100
  network_rule_collection {
    name     = "AVD-production-rules"
    priority = 100
    action   = "Allow"
    rule {
      name                  = "AVD_rule_80"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.6.0/27"]
      destination_addresses = ["169.254.169.254", "168.63.129.16",]
      destination_ports     = ["80"]
    }
    rule {
      name                  = "AVD_rule_443"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.6.0/27"]
      destination_addresses = ["AzureCloud", "WindowsVirtualDesktop", "AzureFrontDoor.Frontend",]
      destination_ports     = ["443"]
    }
    rule {
      name                  = "AVD_rule_53"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.1.6.0/27"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }
    rule {
      name                  = "AVD_rule_1688_AZ_KMS"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.6.0/27"]
      destination_addresses = ["20.118.99.244", "40.83.235.53"]
      destination_ports     = ["1688"]
    }
     rule {
      name                  = "AVD_rule_1688_KMS"
      protocols             = ["TCP"]
      source_addresses      = ["10.1.6.0/27"]
      destination_addresses = ["23.102.135.246"]
      destination_ports     = ["1688"]
    }
  
  }
}









