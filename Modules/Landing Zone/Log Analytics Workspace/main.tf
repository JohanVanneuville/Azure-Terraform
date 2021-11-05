provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "law" {
  name     = "rg-${var.prefix}-law-mgmt"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.prefix}-01"
  location            = azurerm_resource_group.law.location
  resource_group_name = azurerm_resource_group.law.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
resource "azurerm_log_analytics_solution" "container" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.law.location
  resource_group_name   = azurerm_resource_group.law.name
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name        = azurerm_log_analytics_workspace.law.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
