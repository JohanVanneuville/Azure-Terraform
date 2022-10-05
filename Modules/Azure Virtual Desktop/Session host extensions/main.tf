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


data "azurerm_log_analytics_workspace" "law" {
  provider = azurerm.hub
  name = "law-${var.env}-${var.prefix}-01"
  resource_group_name = "rg-${var.env}-${var.prefix}-management-01" 
}


data "azurerm_virtual_machine" "avd-1" {
  provider = azurerm.hub
  name = "avd-prd-jvn-0"
  resource_group_name = "rg-prd-jvn-avd-session-hosts-01"
}


##diag settings vm
resource "null_resource" "bginfo-avd-1" {
  
  provisioner "local-exec" {
    command = "az vm extension set --name BGInfo --publisher Microsoft.compute --resource-group rg-prd-jvn-avd-session-hosts-01 --vm-name avd-prd-jvn-0"
  }
  
}
resource "null_resource" "AzureMonitoringAgent" {
  
  provisioner "local-exec" {
    command = "az vm extension set --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --ids ${data.azurerm_virtual_machine.avd-1.id} --enable-auto-upgrade true"
  }
  
}





resource "azurerm_virtual_machine_extension" "da" {
  provider = azurerm.hub
  name                       = "DAExtension"
  virtual_machine_id         =  data.azurerm_virtual_machine.avd-1.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true

}


resource "azurerm_virtual_machine_extension" "mmaagent" {
  provider = azurerm.hub
  name                  = "MicrosoftMonitoringAgent" 
  virtual_machine_id    = data.azurerm_virtual_machine.avd-1.id
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



