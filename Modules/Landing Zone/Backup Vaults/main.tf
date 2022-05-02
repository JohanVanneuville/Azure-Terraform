provider "azurerm" {
  features {}
}
data "azurerm_log_analytics_workspace" "law" {
  name = "law-hub-jvn-01"
  resource_group_name = "rg-hub-jvn-law-01"
  
}
## Create Resource Group for Production Recovery Services Vault

resource "azurerm_resource_group" "rsv-rg-prod" {
  name     = "rg-prod-${var.prefix}-backup-01"
  location = var.location
  tags = {
    "Costcenter" = "IT"
    "Location" = "Weu"
    "Critical" = "Yes"
    "Environment" = "Production"
    "Solution" = "Backup"
  }
}
resource "azurerm_resource_group" "rsv-rg-prod-irp" {
  name     = "rg-prod-${var.prefix}-backup-irp-01"
  location = var.location
  tags = {
    "Costcenter" = "IT"
    "Location" = "Weu"
    "Critical" = "Yes"
    "Environment" = "Production"
    "Solution" = "Backup-irp"
  }
}

resource "azurerm_recovery_services_vault" "rsv-prod" {
  name                = "rsv-prod-${var.prefix}-01"
  location            = azurerm_resource_group.rsv-rg-prod.location
  resource_group_name = azurerm_resource_group.rsv-rg-prod.name
  sku                 = "Standard"
  soft_delete_enabled = true
   tags = {
    "Costcenter" = "IT"
    "Location" = "Weu"
    "Critical" = "Yes"
    "Environment" = "Production"
    "Solution" = "Backup"
  }
}

resource "azurerm_monitor_diagnostic_setting" "rsv-prod-diag" {
  name               = "diag-prod-${var.prefix}-rsv"
  target_resource_id = azurerm_recovery_services_vault.rsv-prod.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  
  log {
    category = "AzureBackupReport"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "CoreAzureBackup"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "AddonAzureBackupJobs"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "AddonAzureBackupAlerts"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "AddonAzureBackupPolicy"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "AddonAzureBackupStorage"
    enabled  = true

    retention_policy {
      enabled = true
    }
  }
  log {
    category = "AddonAzureBackupProtectedInstance"
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

##BAckup Vault

resource "azurerm_data_protection_backup_vault" "backup-vault" {
  name                = "vault-prod-${var.prefix}-01"
  resource_group_name = azurerm_resource_group.rsv-rg-prod.name
  location            = azurerm_resource_group.rsv-rg-prod.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant" #changing this value will create a new vault / GeoRedundant
  tags = {
    "Costcenter" = "IT"
    "Location" = "Weu"
    "Critical" = "Yes"
    "Environment" = "Production"
    "Solution" = "Backup"
  }
}
