provider "azurerm" {
  features {}
}

## Create a Resource Group for Storage
resource "azurerm_resource_group" "avd-sa" {
  location = var.location
  name     = "rg-${var.prefix}-avd-storage"
}

## Azure Storage Accounts requires a globally unique names
## https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview
## Create a File Storage Account 
resource "azurerm_storage_account" "avd-sa" {
  name                     = "${var.prefix}avdsa"
  resource_group_name      = azurerm_resource_group.avd-sa.name
  location                 = azurerm_resource_group.avd-sa.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
  tags = {
    "location" = "westeurope"
    "environment" = "prd"
  }
}

resource "azurerm_storage_share" "fslogix" {
  name                 = "fslogix"
  storage_account_name = azurerm_storage_account.avd-sa.name
  depends_on           = [azurerm_storage_account.avd-sa]
  quota = "1024"
}

resource "azurerm_storage_share" "msix" {
  name                 = "msix"
  storage_account_name = azurerm_storage_account.avd-sa.name
  depends_on           = [azurerm_storage_account.avd-sa]
  quota = "1024"
}
