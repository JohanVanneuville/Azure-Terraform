terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.99.0"
    }
  }
}

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
  name = "law-${var.hub}-${var.prefix}-01"
  resource_group_name = "rg-${var.hub}-${var.prefix}-management-01"
  
}
## Create a Resource Group for Storage
resource "azurerm_resource_group" "avd-rg" {
  provider = azurerm.prod
  location = var.location
  name     = "rg-${var.env}-${var.prefix}-${var.solution}-storage-01"
   tags = {
    "location" = "westeurope"
    "environment" = "prd"
  }
}

resource "azurerm_resource_group" "avd-rg-dr" {
  provider = azurerm.prod
  location = "northeurope"
  name     = "rg-${var.env}-${var.prefix}-${var.solution}-storage-02"
   tags = {
    "location" = "northeurope"
    "environment" = "prd"
  }
}

## Azure Storage Accounts requires a globally unique names
## https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview
## Create a File Storage Account 
resource "azurerm_storage_account" "avd-sa" {
  provider = azurerm.prod
  name                     = "st${var.env}${var.prefix}${var.solution}01"
  resource_group_name      = azurerm_resource_group.avd-rg.name
  location                 = azurerm_resource_group.avd-rg.location
  account_tier             = "Premium"
  account_replication_type = "ZRS"
  account_kind             = "FileStorage"
  allow_blob_public_access  = false
  min_tls_version = "TLS1_2"
  enable_https_traffic_only = true
  tags = {
    "location" = "westeurope"
    "environment" = "prd"
    "StorageTier" = "ZRS"
  }
}
resource "azurerm_monitor_diagnostic_setting" "st-avd-diag-file" {
  name = "diag-st-${var.solution}-jvn"
  target_resource_id = "${azurerm_storage_account.avd-sa.id}/fileservices/default"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_storage_share.fslogix
  ]
  log {
    category = "StorageRead"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "StorageWrite"
    enabled = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "StorageDelete"
    enabled = true

    retention_policy {
      enabled = true
    }
  } 
  metric {
    category = "Transaction"

    retention_policy {
      enabled = true
    }
  }
}
resource "azurerm_monitor_diagnostic_setting" "st-avd-diag" {
  name = "diag-st-${var.solution}-jvn"
  target_resource_id = azurerm_storage_account.avd-sa.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_storage_share.fslogix
  ]
  metric {
    category = "Transaction"

    retention_policy {
      enabled = true
    }
  }
}
resource "azurerm_storage_account" "avd-sa-dr" {
  provider = azurerm.prod
  name                     = "st${var.env}${var.prefix}${var.solution}02"
  resource_group_name      = azurerm_resource_group.avd-rg-dr.name
  location                 = azurerm_resource_group.avd-rg-dr.location
  account_tier             = "Premium"
  account_replication_type = "ZRS"
  account_kind             = "FileStorage"
  allow_blob_public_access  = false
  min_tls_version = "TLS1_2"
  enable_https_traffic_only = true
  tags = {
    "location" = "northeurope"
    "environment" = "DR"
    "StorageTier" = "ZRS"
  }
}
resource "azurerm_monitor_diagnostic_setting" "st-avd-dr-diag" {
  name = "diag-st-${var.solution}-jvn"
  target_resource_id = azurerm_storage_account.avd-sa-dr.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_storage_share.fslogix
  ]
  metric {
    category = "Transaction"

    retention_policy {
      enabled = true
    }
  }
}
resource "azurerm_monitor_diagnostic_setting" "st-avd-dr-file-diag" {
  name = "diag-st-${var.solution}-jvn"
  target_resource_id = "${azurerm_storage_account.avd-sa-dr.id}/fileservices/default"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_storage_share.fslogix-dr
  ]
  log {
    category = "StorageRead"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "StorageWrite"
    enabled = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "StorageDelete"
    enabled = true

    retention_policy {
      enabled = true
    }
  } 
  metric {
    category = "Transaction"

    retention_policy {
      enabled = true
    }
  }
}

resource "azurerm_storage_share" "fslogix" {
  provider = azurerm.prod
  name                 = "fslogix"
  storage_account_name = azurerm_storage_account.avd-sa.name
  depends_on           = [azurerm_storage_account.avd-sa]
  quota = "100"
}

resource "azurerm_storage_share" "fslogix-dr" {
  provider = azurerm.prod
  name                 = "fslogix"
  storage_account_name = azurerm_storage_account.avd-sa-dr.name
  depends_on           = [azurerm_storage_account.avd-sa-dr]
  quota = "100"
}

