terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.43.0"
    }
     azapi = {
      source  = "azure/azapi"
      version = "=0.3.0"
    }
  }
}


provider "azurerm" {
  features {}
}
provider "azapi" {
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

data "azurerm_subscription" "current" {}
data "azurerm_log_analytics_workspace" "law" {
  provider            = azurerm.hub
  name                = "law-${var.env}-${var.prefix}-01"
  resource_group_name = "rg-${var.env}-${var.prefix}-management-01"
}
locals {
  defender_plan = toset([
    "VirtualMachines",
    "KeyVaults",
    "AppServices",
    "SqlServers",
    "OpenSourceRelationalDatabases",
    "SqlServerVirtualMachines",
    "StorageAccounts",
    "KubernetesService",
    "Dns",
    "Arm",
    "ContainerRegistry",
    "CloudPosture",
    "Containers",

  ])
}
resource "azurerm_security_center_contact" "sec-contact" {
  email = ""
  phone = ""

  alert_notifications = true
  alerts_to_admins    = true
}
resource "azurerm_security_center_subscription_pricing" "sc-hub" {
  provider = azurerm.hub
  for_each = local.defender_plan
  tier          = "Standard"
  resource_type = each.key
}
resource "azurerm_security_center_auto_provisioning" "autop" {
  auto_provision = "On"
}
resource "azurerm_security_center_workspace" "law" {
  scope        = data.azurerm_subscription.current.id
  workspace_id = data.azurerm_log_analytics_workspace.law.id
}
resource "azapi_resource" "DfSMDVMSettings" {
  type = "Microsoft.Security/serverVulnerabilityAssessmentsSettings@2022-01-01-preview"
  name = "AzureServersSetting"
  parent_id = data.azurerm_subscription.current.id
  body = jsonencode({
    properties = {
      selectedProvider = "MdeTvm"
    }
  kind = "AzureServersSetting"
  })
  schema_validation_enabled = false
}


