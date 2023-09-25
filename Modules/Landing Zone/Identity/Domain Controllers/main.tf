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
  name = "law-hub-${var.prefix}-01"
  resource_group_name = "rg-hub-${var.prefix}-management-01" 
}
data "azurerm_virtual_network" "hub" {
   provider = azurerm.hub
  name = "vnet-hub-${var.prefix}-we-01"
  resource_group_name = "rg-hub-${var.prefix}-networking-01"
}
data "azurerm_subnet" "identity" {
  provider = azurerm.hub
  name = "snet-hub-${var.prefix}-identity-01"
  virtual_network_name = data.azurerm_virtual_network.hub.name
  resource_group_name = data.azurerm_virtual_network.hub.resource_group_name
}
data "azurerm_storage_account" "bootdiagdc" {
  provider = azurerm.hub
  name = "sthub${var.prefix}bootdiag01"
  resource_group_name = "rg-hub-${var.prefix}-storage-01" 
}

data "azurerm_resource_group" "rg-dc" {
  name = "rg-hub-${var.prefix}-dc-01"
}
data "azurerm_key_vault" "kv-hub" {
  name = "kv-hub-${var.prefix}-80"
  resource_group_name = "rg-hub-${var.prefix}-management-01"
  
}
data "azurerm_key_vault_secret" "loc-admin" {
  name = "loc-admin"
  key_vault_id = data.azurerm_key_vault.kv-hub.id
}
## deploy domain controller nic's

resource "azurerm_network_interface" "nic-dc-01" {
  provider = azurerm.hub
    name = "nic-01-vm-${var.prefix}-dc-01"
    resource_group_name = data.azurerm_resource_group.rg-dc.name
    location = var.location
    ip_configuration {
      name = "sip-vm-${var.prefix}-dc-01"
      subnet_id = data.azurerm_subnet.identity.id
      private_ip_address_allocation = "Dynamic"
    } 
      tags = {
    "Critical"    = "Yes"
    "Solution"    = "Network interface"
    "Costcenter"  = "IT"
    "Environment" = "Hub"
  } 
}
resource "azurerm_monitor_diagnostic_setting" "diag-nic1" {
  name = "diag-nic"
  target_resource_id = azurerm_network_interface.nic-dc-01.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
}
resource "azurerm_network_interface" "nic-dc-02" {
  provider = azurerm.hub
    name = "nic-01-vm-${var.prefix}-dc-02"
    resource_group_name = data.azurerm_resource_group.rg-dc.name
    location = var.location
    ip_configuration {
      name = "sip-vm-${var.prefix}-dc-02"
      subnet_id = data.azurerm_subnet.identity.id
      private_ip_address_allocation = "Dynamic"

    } 
      tags = {
    "Critical"    = "Yes"
    "Solution"    = "Network interface"
    "Costcenter"  = "IT"
    "Environment" = "Hub"
  } 
}
resource "azurerm_monitor_diagnostic_setting" "diag-nic2" {
  name = "diag-nic"
  target_resource_id = azurerm_network_interface.nic-dc-02.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.law.id
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
    }
  }
}
##Deploy Domain Controller 1

resource "azurerm_windows_virtual_machine" "dc1" {
  provider = azurerm.hub
  name = "vm-${var.prefix}-dc-01"
  resource_group_name = data.azurerm_resource_group.rg-dc.name
  location = data.azurerm_resource_group.rg-dc.location
  network_interface_ids = [azurerm_network_interface.nic-dc-01.id]
  size = "Standard_D2s_V3"
  admin_username = data.azurerm_key_vault_secret.loc-admin.name
  admin_password = data.azurerm_key_vault_secret.loc-admin.value
  #patch_mode = "Manual"
   identity {
    type = "SystemAssigned"
  }
  secure_boot_enabled = true
  vtpm_enabled = true
  provision_vm_agent = true

  os_disk {
    name = "c-vm-${var.prefix}-dc-01"
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb = 64
    
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter-smalldisk-g2"
    version   = "latest"
  }
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Domain Controller"
    "Costcenter"  = "IT"
    "Environment" = "Hub"
  } 
  availability_set_id = azurerm_availability_set.avs-dc.id
  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.bootdiagdc.primary_blob_endpoint
  }

}
resource "azurerm_managed_disk" "dc1-datadisk" {
  name = "f-vm-${var.prefix}-dc-01"
  resource_group_name = azurerm_windows_virtual_machine.dc1.resource_group_name
  location = data.azurerm_resource_group.rg-dc.location
  storage_account_type = "Premium_LRS"
  disk_size_gb = 32
  create_option = "Empty"
}
resource "azurerm_virtual_machine_data_disk_attachment" "dc1-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.dc1-datadisk.id
  virtual_machine_id = azurerm_windows_virtual_machine.dc1.id
  lun                = "1"
  caching            = "None"
}


##Deploy Domain Controller 2

resource "azurerm_windows_virtual_machine" "dc2" {
  provider = azurerm.hub
  name = "vm-${var.prefix}-dc-02"
  resource_group_name = data.azurerm_resource_group.rg-dc.name
  location = data.azurerm_resource_group.rg-dc.location
  network_interface_ids = [azurerm_network_interface.nic-dc-02.id]
  size = "Standard_D2s_V3"
  admin_username = data.azurerm_key_vault_secret.loc-admin.name
  admin_password = data.azurerm_key_vault_secret.loc-admin.value
  #patch_mode = "Manual"
   identity {
    type = "SystemAssigned"
  }
  secure_boot_enabled = true
  vtpm_enabled = true
  provision_vm_agent = true
  os_disk {
    name = "c-vm-${var.prefix}-dc-02"
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb = 64
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter-smalldisk-g2"
    version   = "latest"
  }
  tags = {
    "Critical"    = "Yes"
    "Solution"    = "Domain Controller"
    "Costcenter"  = "IT"
    "Environment" = "Hub"
  }  
  availability_set_id = azurerm_availability_set.avs-dc.id
  boot_diagnostics {
    storage_account_uri = data.azurerm_storage_account.bootdiagdc.primary_blob_endpoint
  }
 
}
resource "azurerm_managed_disk" "dc2-datadisk" {
  name = "f-vm-${var.prefix}-dc-02"
  resource_group_name = azurerm_windows_virtual_machine.dc2.resource_group_name
  location = data.azurerm_resource_group.rg-dc.location
  storage_account_type = "Premium_LRS"
  disk_size_gb = 32
  create_option = "Empty"
}
resource "azurerm_virtual_machine_data_disk_attachment" "dc2-datadisk-attach" {
  managed_disk_id    = azurerm_managed_disk.dc2-datadisk.id
  virtual_machine_id = azurerm_windows_virtual_machine.dc2.id
  lun                = "1"
  caching            = "None"
}

##Create availability set

resource "azurerm_availability_set" "avs-dc" {
  name                = "avail-hub-${var.prefix}-dc-01"
  location            = data.azurerm_resource_group.rg-dc.location
  resource_group_name = data.azurerm_resource_group.rg-dc.name

   tags = {
    "Critical"    = "Yes"
    "Solution"    = "Availabitity Set"
    "Costcenter"  = "IT"
    "Environment" = "Hub"
  } 
}
resource "null_resource" "bginfo-dc1" {
  provisioner "local-exec" {
    command = "az vm extension set --name BGInfo --publisher Microsoft.Compute --resource-group rg-hub-jvn-dc-01 --vm-name vm-jvn-dc-01"
    
  }
   depends_on = [
    azurerm_windows_virtual_machine.dc1
  ]
}
resource "null_resource" "ade-dc1" {
  provisioner "local-exec" {
    command = "az vm encryption enable --resource-group rg-hub-jvn-dc-01 --vm-name vm-jvn-dc-01 --disk-encryption-keyvault kv-hub-jvn-01"
    
  }
   depends_on = [
    azurerm_windows_virtual_machine.dc1
  ]
}
resource "null_resource" "bginfo-dc2" {
  provisioner "local-exec" {
    command = "az vm extension set --name BGInfo --publisher Microsoft.Compute --resource-group rg-hub-jvn-dc-01 --vm-name vm-jvn-dc-02"
    
  }
   depends_on = [
    azurerm_windows_virtual_machine.dc2
  ]
}

resource "null_resource" "AzureMonitoringAgent-dc1" {
  
  provisioner "local-exec" {
    command = "az vm extension set --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --ids ${azurerm_windows_virtual_machine.dc1.id} --enable-auto-upgrade true"
  }
  depends_on = [
    azurerm_windows_virtual_machine.dc1
  ]
}
resource "null_resource" "AzureMonitoringAgent-dc2" {
  
  provisioner "local-exec" {
    command = "az vm extension set --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --ids ${azurerm_windows_virtual_machine.dc2.id} --enable-auto-upgrade true"
  }
  depends_on = [
    azurerm_windows_virtual_machine.dc2
  ]
}




