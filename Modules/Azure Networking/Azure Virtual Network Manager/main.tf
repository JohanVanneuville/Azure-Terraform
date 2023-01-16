terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azapi" {
}
provider "azurerm" {
  features {}
}

provider "azurerm" {
  features {}
  alias           = "hub"
  subscription_id = var.subscription_id_mgmt
}
provider "azurerm" {
  features {}
  alias           = "prod"
  subscription_id = var.subscription_id_prd
}
provider "azurerm" {
  features {}
  alias           = "identity"
  subscription_id = var.subscription_id_identity
}
provider "azurerm" {
  features {}
  alias           = "avd"
  subscription_id = var.subscription_id_avd
}
data "azurerm_resource_group" "hub-rg" {
  name = "rg-hub-jvn-networking-01"
}
data "azurerm_virtual_network" "avd-spoke" {
  name = "vnet-prd-jvn-avd-we-01"
  resource_group_name = "rg-prd-jvn-avd-networking-01"
}
data "azurerm_virtual_network" "prd-spoke" {
  name = "vnet-prd-jvn-we-01"
  resource_group_name = "rg-prd-jvn-networking-01"
}
data "azurerm_virtual_network" "dev-spoke" {
  name = "vnet-dev-jvn-we-01"
  resource_group_name = "rg-dev-jvn-networking-01"
}
data "azurerm_subscription" "current" {}

resource "azapi_resource" "network-manager" {
  type = "Microsoft.Network/networkManagers@2022-07-01"
  name = "vnw-hub-jvn-01"
  location = "westeurope"
  parent_id = "/subscriptions/Your sub id/resourceGroups/rg-hub-jvn-networking-01"
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "networking"
    "Costcenter"  = "It"
    "Environment" = "hub"
  }
  body = jsonencode({
    properties = {
      description = "vnm-jvn-01"
      networkManagerScopeAccesses = [
        "Connectivity",
        "SecurityAdmin"
      ]
      networkManagerScopes = {
        managementGroups = [
          
        ]
        subscriptions = [
           data.azurerm_subscription.current.id
        ]
      }
    }
  })
}
#-----------------------------

#---------------------------
resource "azapi_resource" "spoke_group" {
  type      = "Microsoft.Network/networkManagers/networkGroups@2022-04-01-preview"
  name      = "spokes-vnm-jvn-01"
  parent_id = azapi_resource.network-manager.id

  body = jsonencode({
    properties = {
      description = "vnm spoke group"
      memberType = "VirtualNetwork"
    }
  })
}

resource "azapi_resource" "spoke_group_members-avd" {
  name = "vnet-prd-jvn-avd-we-01"
  type      = "Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-04-01-preview"
  parent_id = azapi_resource.spoke_group.id

  body = jsonencode({
    properties = {
      resourceId = data.azurerm_virtual_network.avd-spoke.id
    }
  })
}
resource "azapi_resource" "spoke_group_members-prd" {
  name = "vnet-prd-jvn-we-01"
  type      = "Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-04-01-preview"
  parent_id = azapi_resource.spoke_group.id

  body = jsonencode({
    properties = {
      resourceId = data.azurerm_virtual_network.prd-spoke.id
    }
  })
}
resource "azapi_resource" "spoke_group_members-dev" {
  name = "vnet-dev-jvn-we-01"
  type      = "Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-04-01-preview"
  parent_id = azapi_resource.spoke_group.id

  body = jsonencode({
    properties = {
      resourceId = data.azurerm_virtual_network.dev-spoke.id
    }
  })
}
