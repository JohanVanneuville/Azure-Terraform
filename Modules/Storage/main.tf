terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.41.0"
      #version = "=2.99.0"
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
  name                = "law-${var.hub}-${var.prefix}-01"
  resource_group_name = "rg-${var.hub}-${var.prefix}-management-01"
}
## Create a Resource Group for Storage
data "azurerm_resource_group" "avd-rg" {
  provider = azurerm.hub
  name     = "rg-${var.env}-${var.prefix}-${var.solution}-storage-01"
}
data "azurerm_resource_group" "avd-rg-dr" {
  provider = azurerm.hub
  name     = "rg-${var.env}-${var.prefix}-${var.solution}-storage-02"
}


## Azure Storage Accounts requires a globally unique names
## https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview
## Create a File Storage Account 
resource "azurerm_storage_account" "avd-sa" {
  provider                 = azurerm.hub
  name                     = "st${var.env}${var.prefix}${var.solution}01"
  resource_group_name      = data.azurerm_resource_group.avd-rg.name
  location                 = data.azurerm_resource_group.avd-rg.location
  account_tier             = "Premium"
  account_replication_type = "ZRS"
  account_kind             = "FileStorage"
  enable_https_traffic_only = true
  allow_nested_items_to_be_public = false
  #allow_blob_public_access = false
  shared_access_key_enabled = false
  public_network_access_enabled = false
  min_tls_version = "1.2"
  azure_files_authentication {
    directory_type = "AADKERB"
  }
  tags = {
    "location"    = "westeurope"
    "environment" = "prd"
    "StorageTier" = "ZRS"
  }
}
resource "azurerm_monitor_diagnostic_setting" "st-avd-diag-file" {
  name                       = "diag-st-${var.solution}-jvn"
  target_resource_id         = "${azurerm_storage_account.avd-sa.id}/fileservices/default"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_storage_share.fslogix
  ]
  enabled_log {
    category = "StorageRead"
    

    retention_policy {
      enabled = true
    }
  }
  enabled_log {
    category = "StorageWrite"
    

    retention_policy {
      enabled = true
    }
  }
  enabled_log {
    category = "StorageDelete"
    

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
  name                       = "diag-st-${var.solution}-jvn"
  target_resource_id         = azurerm_storage_account.avd-sa.id
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
  provider                 = azurerm.hub
  name                     = "st${var.env}${var.prefix}${var.solution}02"
  resource_group_name      = data.azurerm_resource_group.avd-rg-dr.name
  location                 = data.azurerm_resource_group.avd-rg-dr.location
  account_tier             = "Premium"
  account_replication_type = "ZRS"
  account_kind             = "FileStorage"
  allow_nested_items_to_be_public = false
  #allow_blob_public_access = false
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true
  shared_access_key_enabled = false
  public_network_access_enabled = false 
  min_tls_version = "1.2"
  azure_files_authentication {
    directory_type = "AADKERB"
  }
    tags = {
    "location"    = "northeurope"
    "environment" = "DR"
    "StorageTier" = "ZRS"
  }
}

resource "azurerm_monitor_diagnostic_setting" "st-avd-dr-diag" {
  name                       = "diag-st-${var.solution}-jvn"
  target_resource_id         = azurerm_storage_account.avd-sa-dr.id
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
  name                       = "diag-st-${var.solution}-jvn"
  target_resource_id         = "${azurerm_storage_account.avd-sa-dr.id}/fileservices/default"
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [
    azurerm_storage_share.fslogix-dr
  ]
  enabled_log {
    category = "StorageRead"
    

    retention_policy {
      enabled = true
    }
  }
  enabled_log {
    category = "StorageWrite"
    

    retention_policy {
      enabled = true
    }
  }
  enabled_log {
    category = "StorageDelete"
    

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
  provider             = azurerm.hub
  name                 = "fslogix"
  storage_account_name = azurerm_storage_account.avd-sa.name
  depends_on           = [azurerm_storage_account.avd-sa]
  quota                = "100"
  metadata = {
    "costcenter" = "iT"
    "solution" = "Fslogix"
    "environment" = "prd"
    "critical"    = "yes"
  }
}

resource "azurerm_storage_share" "fslogix-dr" {
  provider             = azurerm.hub
  name                 = "fslogix"
  storage_account_name = azurerm_storage_account.avd-sa-dr.name
  depends_on           = [azurerm_storage_account.avd-sa-dr]
  quota                = "100"
   metadata = {
    "costcenter" = "iT"
    "solution" = "Fslogix"
    "environment" = "prd"
    "critical"    = "yes"
  }
}

