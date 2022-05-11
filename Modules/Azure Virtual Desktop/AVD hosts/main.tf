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
resource "azurerm_virtual_desktop_host_pool" "hp" {
    
    custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;"
    friendly_name            = "AVD HostPool"
    
    load_balancer_type       = "BreadthFirst"
    location                 = "westeurope"
    maximum_sessions_allowed = 2
    name                     = "hp-prod-jvn-avd-weu-01"
    preferred_app_group_type = "Desktop"
    resource_group_name      = "rg-prod-jvn-avd-backplane-01"
    start_vm_on_connect      = true
    tags                     = {
        "Costcenter" = "IT"
        "Location"   = "Weu"
    }
    type                     = "Pooled"
    validate_environment     = true

    timeouts {}

}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd_token" {
  hostpool_id = azurerm_virtual_desktop_host_pool.hp.id
  expiration_date = var.rfc3339
}
data "azurerm_log_analytics_workspace" "law" {
  provider = azurerm.prod
    name = "law-hub-jvn-01"
    resource_group_name = "rg-hub-jvn-law-01"
}

data "azurerm_resource_group" "rg-sessionhosts" {
    name = "rg-prod-jvn-avd-session-hosts-01"
}
resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.vm_name}${count.index + 1}"
  location            = data.azurerm_resource_group.rg-sessionhosts.location
  resource_group_name = data.azurerm_resource_group.rg-sessionhosts.name
  vm_size               = "${var.vm_size}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  count                 = "${var.vm_count}"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  storage_os_disk {
    name          = "os-${var.vm_name}${count.index + 1}"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "${var.vm_name}${count.index + 1}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}
resource "azurerm_network_interface" "nic" {
  name                = "nic-${var.vm_name}${count.index + 1}"
  location            = data.azurerm_resource_group.rg-sessionhosts.location
  resource_group_name = data.azurerm_resource_group.rg-sessionhosts.name
  count               = "${var.vm_count}"

  ip_configuration {
    name                                    = "${var.vm_name}${count.index}"
    subnet_id                               = "${var.subnet_id}"
    private_ip_address_allocation           = "Dynamic"
    }
}
resource "azurerm_virtual_machine_extension" "domainjoinext" {
  name                 = "join-domain"
  virtual_machine_id   = element(azurerm_virtual_machine.vm.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.0"
  depends_on           = [azurerm_virtual_machine.vm]
  count                = "${var.vm_count}"

  settings = <<SETTINGS
    {
        "Name": "${var.domain}",
        "OUPath": "${var.oupath}",
        "User": "${var.domainuser}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
        "Password": "${var.domainpassword}"
    }
PROTECTED_SETTINGS
}
resource "azurerm_virtual_machine_extension" "registersessionhost" {
  name                 = "registersessionhost"
  virtual_machine_id   = azurerm_virtual_machine.vm[count.index].id
  depends_on = [
    azurerm_virtual_machine_extension.domainjoinext
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
            "hostPoolName": "azurerm_virtual_desktop_host_pool.hp.name"
            
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
