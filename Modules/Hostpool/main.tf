provider "azurerm" {
  features {}
}



##Create AVD Backplane Resource Group
resource "azurerm_resource_group" "rg-backplane" {
  name     = "rg-${var.prefix}-avd-backplane"
  location = var.location
  tags = {
    "image" = "february"
    "location" = "westeurope"
    "environment" = "prd"
  }
  
}
##Create AVD Session Hosts resource Group
resource "azurerm_resource_group" "rg-sessionhosts" {
  name     = "rg-${var.prefix}-avd-session-hosts"
  location = var.location
  tags = {
    "image" = "february"
    "location" = "westeurope"
    "environment" = "prd"
  }
}
resource "time_rotating" "wvd_token" {
  rotation_days = 30
}

#Create WVD workspace
resource "azurerm_virtual_desktop_workspace" "ws" {
  name                = "${var.prefix}-avd-ws"
  resource_group_name = azurerm_resource_group.rg-backplane.name
  location            = azurerm_resource_group.rg-backplane.location
  friendly_name       = "avd Workspace"
  description         = "avd workspace"
}

# Create WVD host pool
resource "azurerm_virtual_desktop_host_pool" "hp" {
  resource_group_name      = azurerm_resource_group.rg-backplane.name
  name                     = "${var.prefix}-hp"
  location                 = azurerm_resource_group.rg-backplane.location
  validate_environment     = true
  start_vm_on_connect      = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;targetisaadjoined:i:1;"
  type                     = "Pooled"
  maximum_sessions_allowed = 16
  load_balancer_type       = "BreadthFirst" #[BreadthFirst DepthFirst]
  friendly_name            = "AVD HostPool"
  tags = {
    "image" = "february"
    "location" = "westeurope"
    "environment" = "prd"
  }

  registration_info {
    expiration_date = time_rotating.wvd_token.rotation_rfc3339
  }
}

# Create WVD DAG
resource "azurerm_virtual_desktop_application_group" "fd" {
  resource_group_name = azurerm_resource_group.rg-backplane.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hp.id
  location            = azurerm_resource_group.rg-backplane.location
  type                = "Desktop"
  name                = "fd-${var.prefix}-avd"
  friendly_name       = "AVD Full Desktop"
  description         = "AVD Full Desktop"
  depends_on          = [azurerm_virtual_desktop_host_pool.hp]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "example" {
  application_group_id = azurerm_virtual_desktop_application_group.fd.id
  workspace_id         = azurerm_virtual_desktop_workspace.ws.id
}
