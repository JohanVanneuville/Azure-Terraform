provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = ""
}
provider "azurerm" {
  features {}
  alias           = "prod"
  subscription_id = ""
}

data "azurerm_resource_group" "hub-rg" {
  provider = azurerm.hub
  name     = "rg-hub-${var.prefix}-networking-01"
}
resource "azurerm_route_table" "avd" {
  provider                      = azurerm.hub
  name                          = "rt-avd-firewall"
  location                      = data.azurerm_resource_group.hub-rg.location
  resource_group_name           = data.azurerm_resource_group.hub-rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "avd"
    address_prefix         = "10.1.6.0/24"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.1.1.68"
  }

  tags = {
    Solution = "AVD"
  }
}
