terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.4.0"
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

data "azurerm_virtual_network" "hub" {
  provider            = azurerm.hub
  name                = "vnet-${var.env}-${var.prefix}-we-01"
  resource_group_name = "rg-${var.env}-${var.prefix}-networking-01"
}
data "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.env}-${var.prefix}-01"
  resource_group_name = "rg-${var.env}-${var.prefix}-management-01"
}
data "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = "rg-${var.env}-${var.prefix}-networking-01"
  virtual_network_name = data.azurerm_virtual_network.hub.name

}
resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.env}-${var.prefix}-vpng-01"
  location            = data.azurerm_virtual_network.hub.location
  resource_group_name = data.azurerm_virtual_network.hub.resource_group_name

  allocation_method = "Dynamic"
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Public IP VPNG"
    "Costcenter"  = "It"
    "Location"    = "We"
  }
}
resource "azurerm_monitor_diagnostic_setting" "vpng-pip-diag" {
  provider = azurerm.hub
  name = "diag-pip-${var.prefix}-vpng"
  target_resource_id = azurerm_public_ip.pip.id
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
    enabled = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "DDoSMitigationReports"
    enabled =true
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
  
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "vpng-${var.env}-${var.prefix}-01"
  location            = data.azurerm_virtual_network.hub.location
  resource_group_name = data.azurerm_virtual_network.hub.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "VPN Gateway"
    "Costcenter"  = "It"
    "Location"    = "We"
  }

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.gateway.id
  }

  vpn_client_configuration {
    address_space = ["172.16.101.0/24"]

    root_certificate {
      name = "p2s-jvn-root-cert"

      public_cert_data = <<EOF
Your cert goes here
EOF

    }
  }
}
