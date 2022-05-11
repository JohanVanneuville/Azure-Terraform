terraform {
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
      
    }
  }
}
provider "azurerm" {
  features {}
  alias = "prod"
  subscription_id = "5601b367-9101-4a22-9af4-541dee535215"
  
}

provider "azurerm" {
  features {}
}

data "azurerm_log_analytics_workspace" "law" {
  provider = azurerm.prod
    name = "law-hub-jvn-01"
    resource_group_name = "rg-hub-jvn-law-01"
}

##Create AVD Backplane Resource Group
resource "azurerm_resource_group" "rg-backplane" {
  name     = "rg-prod-${var.prefix}-avd-backplane-01"
  location = var.location
  tags = {
    "Location" = "Weu"
    "Costcenter" = "IT"
  }
  
}
##Create AVD Session Hosts resource Group
resource "azurerm_resource_group" "rg-sessionhosts" {
  name     = "rg-prod-${var.prefix}-avd-session-hosts-01"
  location = var.location
   tags = {
    "Location" = "Weu"
    "Costcenter" = "IT"
  }
}
#Create WVD workspace
resource "azurerm_virtual_desktop_workspace" "ws" {
  name                = "ws-prod-${var.prefix}-avd-weu-01"
  resource_group_name = azurerm_resource_group.rg-backplane.name
  location            = azurerm_resource_group.rg-backplane.location
  friendly_name       = "avd Workspace"
  description         = "avd workspace"
  tags = {
    "Location" = "Weu"
    "Costcenter" = "IT"
  }
}
resource "azurerm_monitor_diagnostic_setting" "avd-ws-logs" {
  provider = azurerm.prod
  name = "diag-prod-jvn-avd-ws"
  target_resource_id =  azurerm_virtual_desktop_workspace.ws.id 
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  depends_on = [azurerm_virtual_desktop_workspace.ws]
   log {
    category = "Error"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Checkpoint"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Management"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Feed"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd_token" {
  hostpool_id = azurerm_virtual_desktop_host_pool.hp.id
  expiration_date = var.rfc3339
  
}
# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hp" {
  resource_group_name      = azurerm_resource_group.rg-backplane.name
  name                     = "hp-prod-${var.prefix}-avd-weu-01"
  location                 = azurerm_resource_group.rg-backplane.location
  validate_environment     = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;"
  type                     = "Pooled"
  maximum_sessions_allowed = 2
  load_balancer_type       = "BreadthFirst"
  friendly_name            = "AVD HostPool"
  start_vm_on_connect = true
  tags = {
    "Location" = "Weu"
    "Costcenter" = "IT"
  }
}
# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "fd" {
  resource_group_name = azurerm_resource_group.rg-backplane.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hp.id
  location            = azurerm_resource_group.rg-backplane.location
  type                = "Desktop"
  name                = "fd-prod-${var.prefix}-avd-weu-01"
  friendly_name       = "AVD Full Desktop"
  description         = "AVD Full Desktop"
  depends_on          = [azurerm_virtual_desktop_host_pool.hp]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "fd" {
  application_group_id = azurerm_virtual_desktop_application_group.fd.id
  workspace_id         = azurerm_virtual_desktop_workspace.ws.id
}

resource "azurerm_monitor_diagnostic_setting" "avd-logs" {
  provider = azurerm.prod
    name = "diag-prod-jvn-avd-hp"
    target_resource_id = azurerm_virtual_desktop_host_pool.hp.id
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
    depends_on = [azurerm_virtual_desktop_host_pool.hp]
   log {
    category = "Error"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Checkpoint"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Management"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Connection"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "HostRegistration"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "AgentHealthStatus"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "NetworkData"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "SessionHostManagement"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
}
resource "azurerm_monitor_diagnostic_setting" "fd-logs" {
  provider = azurerm.prod
  name = "diag-prod-jvn-avd-fd"
  target_resource_id = azurerm_virtual_desktop_application_group.fd.id 
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id 
  depends_on = [
    azurerm_virtual_desktop_application_group.fd
  ]
  log {
    category = "Checkpoint"
    enabled = "true"

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Error"
    enabled = "true"

    retention_policy {
      enabled = false
    }
  }
  log {
    category = "Management"
    enabled = "true"

    retention_policy {
      enabled = false
    }
  }
}
