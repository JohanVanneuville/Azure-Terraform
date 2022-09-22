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

data "azurerm_resource_group" "rg-hub-mgmt" {
  provider = azurerm.hub
  name = "rg-${var.env}-${var.prefix}-management-01"
}
locals {
  solution_name = toset([
    "Security","SecurityInsights","AgentHealthAssessment","AzureActivity","SecurityCenterFree","DnsAnalytics","ADAssessment","AntiMalware","ServiceMap","SQLAssessment", "SQLAdvancedThreatProtection", "AzureAutomation", "Containers", "ChangeTracking", "Updates", "VMInsights"
  ])
}


resource "azurerm_log_analytics_workspace" "law" {
  provider = azurerm.hub
  name                = "law-${var.env}-${var.prefix}-01"
  location            = data.azurerm_resource_group.rg-hub-mgmt.location
  resource_group_name = data.azurerm_resource_group.rg-hub-mgmt.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
   tags = {
    "Critical"    = "Yes"
    "Solution"    = "Logs"
    "Costcenter"  = "It"
    "Environment" = "Hub"
  }
}
resource "azurerm_monitor_diagnostic_setting" "law" {
  name = "diag-law-${var.env}-${var.prefix}-01"
  target_resource_id = azurerm_log_analytics_workspace.law.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  log {
    category = "Audit"
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
resource "azurerm_log_analytics_solution" "solutions" {
  provider = azurerm.hub
  for_each = local.solution_name
  solution_name         = each.key
  location              = data.azurerm_resource_group.rg-hub-mgmt.location
  resource_group_name   = data.azurerm_resource_group.rg-hub-mgmt.name
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name        = azurerm_log_analytics_workspace.law.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.key}"
  }
}


