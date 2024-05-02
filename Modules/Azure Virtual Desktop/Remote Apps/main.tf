terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.101.0"
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
data "azurerm_virtual_desktop_application_group" "remoteapps" {
  provider = azurerm.hub
  name                = "vdpool-prd-jvn-avd-remoteapps"
  resource_group_name = "rg-prd-jvn-avd-backplane-01"
}

#notepad++
resource "azurerm_virtual_desktop_application" "notepadplusplus" {
  name                         = "NotepadPlusPlus"
  application_group_id         = data.azurerm_virtual_desktop_application_group.remoteapps.id
  friendly_name                = "NotepadPlusPlus"
  description                  = "NotepadPlusPlus"
  path                         = "C:\\Program Files\\Notepad++\\notepad++.exe"
  command_line_argument_policy = "DoNotAllow"
  command_line_arguments       = "--incognito"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files\\Notepad++\\notepad++.exe"
  icon_index                   = 0
}
#adobe
resource "azurerm_virtual_desktop_application" "adobereader" {
  name                         = "AdobeReader"
  application_group_id         = data.azurerm_virtual_desktop_application_group.remoteapps.id
  friendly_name                = "AdobeReader"
  description                  = "AdobeReader"
  path                         = "C:\\Program Files\\Adobe\\Acrobat DC\\Acrobat\\Acrobat.exe"
  command_line_argument_policy = "DoNotAllow"
  command_line_arguments       = "--incognito"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files\\Adobe\\Acrobat DC\\Acrobat\\Acrobat.exe"
  icon_index                   = 0
}
#outlook
resource "azurerm_virtual_desktop_application" "outlook" {
  name                         = "Outlook"
  application_group_id         = data.azurerm_virtual_desktop_application_group.remoteapps.id
  friendly_name                = "Outlook"
  description                  = "Outlook"
  path                         = "C:\\Program Files\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE"
  command_line_argument_policy = "DoNotAllow"
  command_line_arguments       = "--incognito"
  show_in_portal               = true
  icon_path                    = "C:\\Program Files\\Microsoft Office\\root\\Office16\\OUTLOOK.EXE"
  icon_index                   = 0
}
