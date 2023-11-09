provider "azurerm" {
  features {} 
}

provider "azurerm" {
  features {}
  alias = "hub"
  subscription_id = var.subscription_id_mgmt
}
provider "azurerm" {
  features {}
  alias = "prod"
  subscription_id = var.subscription_id_prd
}
provider "azurerm" {
  features {}
  alias = "identity"
  subscription_id = var.subscription_id_identity
}
provider "azurerm" {
  features {}
  alias = "avd"
  subscription_id = var.subscription_id_avd
}

data "azurerm_log_analytics_workspace" "law" {
  provider = azurerm.hub
  name = "law-hub-${var.prefix}-01"
  resource_group_name = "rg-hub-${var.prefix}-management-01" 
}
data "azurerm_resource_group" "rg-kv" {
  provider = azurerm.hub
  name = "rg-${var.env}-${var.prefix}-avd-management-01"
}

resource "azurerm_key_vault" "kv" {
  provider = azurerm.hub
  depends_on = [ data.azurerm_resource_group.rg-kv ]
  name                        = "kv-${var.env}-${var.prefix}-${var.solution}-80"
  location                    = data.azurerm_resource_group.rg-kv.location
  resource_group_name         = data.azurerm_resource_group.rg-kv.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true #be careful with this feature
  enabled_for_deployment = true
  enabled_for_template_deployment = true
  enabled_for_disk_encryption = true
  public_network_access_enabled = false
 
  sku_name = "premium"
  tags = {
    "Costcenter"   = "ICT"
    "Critical"     = "Yes"
    "Environment"  = "AVD PRD"
    "Solution"     = "Keyvault"
  }
}
resource "azurerm_monitor_diagnostic_setting" "kv-diag" {
  name               = "diag-keyvault"
  target_resource_id = azurerm_key_vault.kv.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  
  log {
    category = "AuditEvent"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "AzurePolicyEvaluationDetails"
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

