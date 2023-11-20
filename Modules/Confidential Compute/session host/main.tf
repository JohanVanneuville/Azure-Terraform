terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.67.0"
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

data "azurerm_storage_account" "bootdiag" {
  name = "sthubjvnbootdiag01"
  resource_group_name = "rg-hub-jvn-storage-01"
}
data "azurerm_log_analytics_workspace" "law" {
  provider = azurerm.hub
  name = "law-${var.env}-${var.prefix}-01"
  resource_group_name = "rg-${var.env}-${var.prefix}-management-01" 
}
data "azurerm_resource_group" "rg-sessionhosts" {
  provider = azurerm.avd
  name     = "rg-${var.spoke}-${var.prefix}-${var.solution}-shared-sessionhosts-01"
}
data "azurerm_virtual_network" "avd-vnet" {
  provider            = azurerm.hub
  name                = "vnet-${var.spoke}-${var.prefix}-${var.solution}-we-01"
  resource_group_name = "rg-${var.spoke}-${var.prefix}-${var.solution}-networking-01"
}
data "azurerm_key_vault" "avd-keyvault" {
  provider = azurerm.avd
  name = "kv-${var.spoke}-${var.prefix}-${var.solution}-80"
  resource_group_name = "rg-${var.spoke}-${var.prefix}-${var.solution}-management-01"
}
data "azurerm_key_vault_secret" "loc-admin" {
  name = "loc-admin"
  key_vault_id = data.azurerm_key_vault.avd-keyvault.id
}

data "azurerm_virtual_desktop_host_pool" "hp" {
  provider = azurerm.hub
  name = "hp-${var.spoke}-${var.prefix}-${var.solution}-we-01"
  resource_group_name = "rg-${var.spoke}-${var.prefix}-${var.solution}-backplane-01"
}
data "azurerm_disk_encryption_set" "des" {
  provider = azurerm.avd
  name = "des-prd-jvn-avd-50"
  resource_group_name = "rg-prd-jvn-avd-management-01"
}
resource "azurerm_virtual_desktop_host_pool_registration_info" "avd_token" {
  provider        = azurerm.hub
  hostpool_id     = data.azurerm_virtual_desktop_host_pool.hp.id
  expiration_date = var.rfc3339
}
## session hosts

resource "azurerm_windows_virtual_machine" "vm" {
  provider = azurerm.avd
  name                  = "${var.vm_name}${count.index + 1}"
  location              = data.azurerm_resource_group.rg-sessionhosts.location
  resource_group_name   = data.azurerm_resource_group.rg-sessionhosts.name
  size                  = var.vm_size
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  count                 = var.vm_count
  license_type          = "None"
  vtpm_enabled = "true"
  secure_boot_enabled = "true"
  identity {
    type = "SystemAssigned"
  }
  admin_username = var.admin_username
  admin_password = var.admin_password
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
  os_disk {
    name                 = "c-${var.vm_name}${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    security_encryption_type = "DiskWithVMGuestState"
    secure_vm_disk_encryption_set_id = data.azurerm_disk_encryption_set.des.id
  }
  provision_vm_agent = true
    boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.bootdiag.primary_blob_endpoint
  }
  zone = (count.index % 3) + 1
  tags = {
    "Location"    = "We"
    "Costcenter"  = "IT"
    "Purpose"     = "AVD Session Host"
    "Environment" = "Prd"
  }
}
resource "azurerm_network_interface" "nic" {
  provider = azurerm.avd
  name                = "nic-01-${var.vm_name}${count.index}"
  location            = data.azurerm_resource_group.rg-sessionhosts.location
  resource_group_name = data.azurerm_resource_group.rg-sessionhosts.name
  count               = var.vm_count

  ip_configuration {
    name                          = "ipc-${var.vm_name}${count.index}"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    "Location"    = "We"
    "Costcenter"  = "IT"
    "Purpose"     = "AVD Session Host Nic"
    "Environment" = "Prd"
  }
}
resource "azurerm_virtual_machine_extension" "domain_join" {
  count                      = var.vm_count
  name                       = "${var.vm_name}-${count.index + 1}-domainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm.*.id[count.index]
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "Name": "${var.domain}",
      "OUPath": "${var.oupath}",
      "User": "${var.domainuser}@${var.domain}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.domainpassword}"
    }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

 
}

resource "azurerm_virtual_machine_extension" "registersessionhost" {
  name               = "registersessionhost"
  virtual_machine_id = azurerm_windows_virtual_machine.vm[count.index].id
  depends_on = [
    azurerm_windows_virtual_machine.vm
  ]
  publisher                  = "Microsoft.Powershell"
  count                      = var.vm_count
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  settings                   = <<SETTINGS
    {
        "ModulesUrl": "${var.artifactslocation}",
        "ConfigurationFunction" : "Configuration.ps1\\AddSessionHost",
        "Properties": {
            "hostPoolName": "${data.azurerm_virtual_desktop_host_pool.hp.name}"
      
            
        }
    }
    SETTINGS
  protected_settings         = <<PROTECTED_SETTINGS
    {
      "properties" : {
            "registrationInfoToken" : "${azurerm_virtual_desktop_host_pool_registration_info.avd_token.token}"
        }
    }
    PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}
## session hosts extensions

##AzureMonitoringAgent
resource "null_resource" "AzureMonitoringAgent" {
  count = var.vm_count

  provisioner "local-exec" {
    command = "az vm extension set --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --ids ${azurerm_windows_virtual_machine.vm[count.index].id} --enable-auto-upgrade true"
  }

}


##dependencyAgent
resource "azurerm_virtual_machine_extension" "da" {
  provider                   = azurerm.hub
  count                      = var.vm_count
  name                       = "DAExtension"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm[count.index].id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true

}
##MicrosoftMonitoringAgent
resource "azurerm_virtual_machine_extension" "mmaagent" {
  provider                   = azurerm.hub
  count                      = var.vm_count
  name                       = "MicrosoftMonitoringAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm[count.index].id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings           = <<SETTINGS
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


