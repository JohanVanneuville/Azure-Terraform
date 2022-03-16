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
}

data "azurerm_log_analytics_workspace" "law" {
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
  expiration_date = "2022-03-20T08:00:00Z"
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



## New Azure AD role definition for Autoscale
resource "azurerm_role_definition" "avd-autoscale" {
    name = "AVD-Autoscale"
    scope = "/subscriptions/dadb7fec-f397-4981-8ea7-9ba12934a0d0"
    description = "AVD Autoscale Custom role"
   permissions {
    actions = [
      "Microsoft.Insights/eventtypes/values/read",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.DesktopVirtualization/hostpools/read",
      "Microsoft.DesktopVirtualization/hostpools/write",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/read",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/write",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/delete",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/sendMessage/action",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read"
    ]
    not_actions = []
  }
  assignable_scopes = [
    "/subscriptions/dadb7fec-f397-4981-8ea7-9ba12934a0d0",
  ]
}
data "azuread_service_principal" "avd-sp" {
    display_name = "Windows Virtual Desktop"  
}

resource "random_uuid" "avd-sp-custom-role" {
}
resource "azurerm_role_assignment" "avd-sp-custom-role" {
  name                             = random_uuid.avd-sp-custom-role.result
  scope                            = "/subscriptions/dadb7fec-f397-4981-8ea7-9ba12934a0d0"
  role_definition_id               = azurerm_role_definition.avd-autoscale.role_definition_resource_id
  principal_id                     = data.azuread_service_principal.avd-sp.id
  skip_service_principal_aad_check = true
}

resource "azurerm_virtual_desktop_scaling_plan" "avd-scalingplan" {
  name                = "sp-prod-jvn-avd-weu-01"
  location            = azurerm_resource_group.rg-backplane.location
  resource_group_name = azurerm_resource_group.rg-backplane.name
  friendly_name       = "Production week days scaling plan"
  description         = "Production week days scaling plan"
  depends_on = [
    azurerm_virtual_desktop_host_pool.hp
  ]
  time_zone           = "Romance standard Time"
  schedule {
    name                                 = "Weekdays"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "07:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 10
    ramp_up_capacity_threshold_percent   = 10
    peak_start_time                      = "09:00"
    peak_load_balancing_algorithm        = "BreadthFirst"
    ramp_down_start_time                 = "19:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 10
    ramp_down_force_logoff_users         = false
    ramp_down_wait_time_minutes          = 45
    ramp_down_notification_message       = "Please log off in the next 45 minutes..."
    ramp_down_capacity_threshold_percent = 5
    ramp_down_stop_hosts_when            = "ZeroSessions"
    off_peak_start_time                  = "22:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }
  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.hp.id
    scaling_plan_enabled = true
  }
}
resource "azurerm_monitor_diagnostic_setting" "sp-logs" {
  name = "diag-prod-jvn-avd-sp"
  target_resource_id = azurerm_virtual_desktop_scaling_plan.avd-scalingplan.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id 
  depends_on = [
    azurerm_virtual_desktop_scaling_plan.avd-scalingplan
  ]
  log {
    category = "Autoscale"
    enabled = "true"

    retention_policy {
      enabled = false
    }
  }
} 


