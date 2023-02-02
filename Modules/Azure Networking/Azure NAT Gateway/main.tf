terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.22.0"
    }
  }
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


data "azurerm_log_analytics_workspace" "law" {
  provider            = azurerm.hub
  name                = "law-${var.env}-${var.prefix}-01"
  resource_group_name = "rg-${var.env}-${var.prefix}-management-01"
}
data "azurerm_virtual_network" "avd" {
  provider            = azurerm.hub
  name                = "vnet-${var.spoke}-${var.prefix}-${var.solution}-we-01"
  resource_group_name = "rg-${var.spoke}-${var.prefix}-${var.solution}-networking-01"
}
data "azurerm_subnet" "avd-sessionhosts" {
  name                 = "snet-${var.spoke}-${var.prefix}-${var.solution}-session-hosts-01"
  virtual_network_name = data.azurerm_virtual_network.avd.name
  resource_group_name  = data.azurerm_virtual_network.avd.resource_group_name
}

resource "azurerm_public_ip" "pip-natg" {
  name                = "pip-${var.spoke}-${var.prefix}-${var.solution}-01"
  location            = data.azurerm_virtual_network.avd.location
  resource_group_name = data.azurerm_virtual_network.avd.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]

  tags = {
    "Critical"   = "Yes"
    "Solution"   = "Public IP NATG"
    "Costcenter" = "It"
    "Location"   = "We"
  }

}

resource "azurerm_public_ip_prefix" "pippre" {
  name                = "pippre-${var.spoke}-${var.prefix}-${var.solution}-01"
  location            = data.azurerm_virtual_network.avd.location
  resource_group_name = data.azurerm_virtual_network.avd.resource_group_name
  prefix_length       = 30
  zones               = ["1"]
}
resource "azurerm_nat_gateway_public_ip_prefix_association" "natg-pippre" {
  nat_gateway_id      = azurerm_nat_gateway.natg.id
  public_ip_prefix_id = azurerm_public_ip_prefix.pippre.id
}

resource "azurerm_nat_gateway" "natg" {
  name                    = "natg-${var.spoke}-${var.prefix}-${var.solution}-01"
  location                = data.azurerm_virtual_network.avd.location
  resource_group_name     = data.azurerm_virtual_network.avd.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Nat Gateway"
    "Costcenter"  = "It"
    "Location"    = "We"
    "Environment" = "AVD"
  }

}
resource "azurerm_nat_gateway_public_ip_association" "natg-pip-ass" {
  nat_gateway_id       = azurerm_nat_gateway.natg.id
  public_ip_address_id = azurerm_public_ip.pip-natg.id
}
resource "azurerm_subnet_nat_gateway_association" "nat-avd-sessionhosts" {
  subnet_id      = data.azurerm_subnet.avd-sessionhosts.id
  nat_gateway_id = azurerm_nat_gateway.natg.id
}

resource "azurerm_monitor_diagnostic_setting" "natg-pip-diag" {
  provider                   = azurerm.hub
  name                       = "diag-pip-${var.prefix}-natg"
  target_resource_id         = azurerm_public_ip.pip-natg.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  log {
    category = "DDoSProtectionNotifications"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
  log {
    category = "DDoSMitigationFlowLogs"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "DDoSMitigationReports"
    enabled  = true
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }

}
