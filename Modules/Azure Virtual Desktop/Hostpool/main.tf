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

data "azurerm_resource_group" "rg-backplane" {
  provider = azurerm.hub
    name = "rg-${var.env}-${var.prefix}-${var.solution}-backplane-01"
}
data "azurerm_resource_group" "rg-sessionhosts" {
  provider = azurerm.hub
    name = "rg-${var.env}-${var.prefix}-${var.solution}-session-hosts-01"
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.99.0"
    }
  }
}

data "azurerm_log_analytics_workspace" "law" {
  provider = azurerm.hub
    name = "law-hub-jvn-01"
    resource_group_name = "rg-hub-${var.prefix}-management-01"
}



#Create WVD workspace
resource "azurerm_virtual_desktop_workspace" "ws" {
  provider = azurerm.hub
  name                = "ws-${var.env}-${var.prefix}-${var.solution}-we-01"
  resource_group_name = data.azurerm_resource_group.rg-backplane.name
  location            = data.azurerm_resource_group.rg-backplane.location
  friendly_name       = "avd Workspace"
  description         = "avd workspace"
  tags = {
    "Location" = "We"
    "Costcenter" = "IT"
  }
}
resource "azurerm_monitor_diagnostic_setting" "avd-ws-logs" {
  provider = azurerm.hub
  name = "diag-ws-${var.solution}${var.prefix}-avd"
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
  provider = azurerm.hub
  hostpool_id = azurerm_virtual_desktop_host_pool.hp.id
  expiration_date = var.rfc3339
}
# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hp" {
  provider = azurerm.hub
  resource_group_name      = data.azurerm_resource_group.rg-backplane.name
  name                     = "hp-${var.env}-${var.prefix}-${var.solution}-we-01"
  location                 = data.azurerm_resource_group.rg-backplane.location
  validate_environment     = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;targetisaadjoined:i:1;"
  type                     = "Pooled"
  maximum_sessions_allowed = 10
  load_balancer_type       = "BreadthFirst"
  friendly_name            = "AVD HostPool"
  start_vm_on_connect = true
  scheduled_agent_updates {
    enabled = true
    schedule {
      day_of_week = "Wednesday"
      hour_of_day = 10
    }
  use_session_host_timezone = true
    
     schedule {
      day_of_week = "Friday"
      hour_of_day = 10
    } 
  }
  tags = {
    "Location" = "We"
    "Costcenter" = "IT"
  }
}
# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "fd" {
  provider = azurerm.hub
  resource_group_name = data.azurerm_resource_group.rg-backplane.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hp.id
  location            = data.azurerm_resource_group.rg-backplane.location
  type                = "Desktop"
  name                = "fd-prod-${var.prefix}-avd-we-01"
  friendly_name       = "AVD Full Desktop"
  description         = "AVD Full Desktop"
  depends_on          = [azurerm_virtual_desktop_host_pool.hp]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "fd" {
  provider = azurerm.hub
  application_group_id = azurerm_virtual_desktop_application_group.fd.id
  workspace_id         = azurerm_virtual_desktop_workspace.ws.id
}

resource "azurerm_monitor_diagnostic_setting" "avd-logs" {
  provider = azurerm.hub
    name = "diag-hp-${var.solution}${var.prefix}-avd"
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
  provider = azurerm.hub
  name = "diag-fd-${var.solution}${var.prefix}-avd"
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
