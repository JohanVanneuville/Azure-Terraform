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
data "azurerm_virtual_network" "hub" {
  provider            = azurerm.hub
  name                = "vnet-hub-${var.prefix}-we-01"
  resource_group_name = "rg-hub-${var.prefix}-networking-01"
}

data "azurerm_subnet" "AzureFirewallSubnet" {
  provider             = azurerm.hub
  name                 = "AzureFirewallSubnet"
  resource_group_name  = data.azurerm_virtual_network.hub.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.hub.name
}
data "azurerm_log_analytics_workspace" "hub-law" {
  provider            = azurerm.hub
  name                = "law-hub-${var.prefix}-01"
  resource_group_name = "rg-hub-${var.prefix}-management-01"
}
resource "azurerm_public_ip" "pip-firewall" {
  provider            = azurerm.hub
  name                = "pip-hub-${var.prefix}-fw-01"
  location            = data.azurerm_virtual_network.hub.location
  resource_group_name = data.azurerm_virtual_network.hub.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "hub-firewall" {
  provider            = azurerm.hub
  name                = "fw-hub-${var.prefix}-01"
  location            = data.azurerm_virtual_network.hub.location
  resource_group_name = data.azurerm_virtual_network.hub.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard" ##can be Premium
  ip_configuration {
    name                 = "configuration"
    subnet_id            = data.azurerm_subnet.AzureFirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.pip-firewall.id
  }

}
resource "azurerm_monitor_diagnostic_setting" "firewall-diag" {
  provider                   = azurerm.hub
  name                       = "diag-hub-${var.prefix}-firewall"
  target_resource_id         = azurerm_firewall.hub-firewall.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.hub-law.id
  
  log {
    category = "AzureFirewallApplicationRule"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
  log {
    category = "AzureFirewallApplicationRuleHit"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
  log {
    category = "AzureFirewallNetworkRule"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
  log {
    category = "AzureFirewallNetworkRuleHit"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
 
  log {
    category = "AzureFirewallDnsProxy"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }

  log {
    category = "AZFWThreatIntel"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
  log {
    category = "AZFWIdpsSignature"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
  log {
    category = "AZFWDnsquery"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
   log {
    category = "AZFWFqdnResolveFailure"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
    log {
    category = "AZFWNetworkRuleAggregation"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
   log {
    category = "AZFWApplicationRuleAggregation"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
   log {
    category = "AZFWNatRuleAggregation"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
     log {
    category = "AZFWDnsQueryHit"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
  
  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
    }

  }
}



resource "azurerm_monitor_diagnostic_setting" "firewall-pip-diag" {
  provider                   = azurerm.hub
  name                       = "diag-hub-${var.prefix}-firewall-pip"
  target_resource_id         = azurerm_public_ip.pip-firewall.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.hub-law.id
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
