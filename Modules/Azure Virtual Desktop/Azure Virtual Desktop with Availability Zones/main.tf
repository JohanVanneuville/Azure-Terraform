terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.22.0"
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

data "azurerm_resource_group" "rg-backplane" {
  provider = azurerm.hub
    name = "rg-${var.env}-${var.prefix}-${var.solution}-backplane-01"
}
data "azurerm_resource_group" "rg-sessionhosts" {
  provider = azurerm.hub
    name = "rg-${var.env}-${var.prefix}-${var.solution}-session-hosts-01"
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
  name = "diag-ws-${var.solution}-${var.prefix}"
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
    name = "diag-hp-${var.solution}${var.prefix}"
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
  name = "diag-fd-${var.solution}-${var.prefix}"
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

## session hosts

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "${var.vm_name}${count.index + 1}"
  location            = data.azurerm_resource_group.rg-sessionhosts.location
  resource_group_name = data.azurerm_resource_group.rg-sessionhosts.name
  size               = "${var.vm_size}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  count                 = "${var.vm_count}"
 
  identity {
    type = "SystemAssigned"
  }
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  source_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  os_disk {
    name          = "${var.vm_name}${count.index + 1}-c"
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
 tags = {
    "Environment" = "prd"
    "Solution" = "Shared"
    "Costcenter" = "IT"
    "solution" = "Avd session host"
  }
  
    provision_vm_agent = true
  
  zone = "${(count.index%3)+1}"
}
resource "azurerm_network_interface" "nic" {
  name                = "nic-01-${var.vm_name}${count.index + 1}"
  location            = data.azurerm_resource_group.rg-sessionhosts.location
  resource_group_name = data.azurerm_resource_group.rg-sessionhosts.name
  count               = "${var.vm_count}"

  ip_configuration {
    name                                    = "${var.vm_name}${count.index}"
    subnet_id                               = "${var.subnet_id}"
    private_ip_address_allocation           = "Dynamic"
    }
}

resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  provider = azurerm.hub
  count = "${var.vm_count}"
  depends_on = [
      azurerm_virtual_machine_extension.registersessionhost
  ]

  name                 = "AADLoginForWindows"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADLoginForWindows"
  type_handler_version = "1.0"

}
locals {
  registration_token = "${azurerm_virtual_desktop_host_pool_registration_info.avd_token.token}"
}
resource "azurerm_virtual_machine_extension" "registersessionhost" {
  name                 = "registersessionhost"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm[count.index].id
  depends_on = [
    azurerm_windows_virtual_machine.vm
  ]
  publisher            = "Microsoft.Powershell"
  count                = "${var.vm_count}"
  type = "DSC"
  type_handler_version = "2.73"
  auto_upgrade_minor_version = true
  settings = <<SETTINGS
    {
        "ModulesUrl": "${var.artifactslocation}",
        "ConfigurationFunction" : "Configuration.ps1\\AddSessionHost",
        "Properties": {
            "hostPoolName": "azurerm_virtual_desktop_host_pool.hp.name",
            "aadJoin": true
            
        }
    }
    SETTINGS
        protected_settings = <<PROTECTED_SETTINGS
    {
      "properties" : {
            "registrationInfoToken" : "${azurerm_virtual_desktop_host_pool_registration_info.avd_token.token}"
        }
    }
    PROTECTED_SETTINGS

    lifecycle {
        ignore_changes = [settings, protected_settings ]
    }
}
## session hosts extensions

##AzureMonitoringAgent
resource "null_resource" "AzureMonitoringAgent" {
  count                = "${var.vm_count}"
  
  provisioner "local-exec" {
    command = "az vm extension set --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --ids ${azurerm_windows_virtual_machine.vm[count.index].id} --enable-auto-upgrade true"
  }
  
}
##dependencyAgent
resource "azurerm_virtual_machine_extension" "da" {
  provider = azurerm.hub
  count                = "${var.vm_count}"
  name                       = "DAExtension"
  virtual_machine_id         =  azurerm_windows_virtual_machine.vm[count.index].id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true

}
##MicrosoftMonitoringAgent
resource "azurerm_virtual_machine_extension" "mmaagent" {
  provider = azurerm.hub
  count                = "${var.vm_count}"
  name                  = "MicrosoftMonitoringAgent" 
  virtual_machine_id    = azurerm_windows_virtual_machine.vm[count.index].id
  publisher             = "Microsoft.EnterpriseCloud.Monitoring"
  type                  = "MicrosoftMonitoringAgent"
  type_handler_version  = "1.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "workspaceId": "${var.workspace_id}"
    }
  SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
    {
      "workspaceKey": "${var.workspace_key}"
    }
  PROTECTED_SETTINGS  

  
}












