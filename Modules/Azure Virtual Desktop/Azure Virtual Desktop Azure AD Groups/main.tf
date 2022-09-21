terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.22.0"
    }
  }
}

data "azuread_client_config" "current" {}
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
locals {
  display_name = toset([
    "desktop-virtualization-contributor",
    "desktop-virtualization-reader",
    "desktop-virtualization-user",
    "desktop-virtualization-host-pool-contributor",
    "desktop-virtualization-host-pool-reader",
    "desktop-virtualization-application-group-contributor",
    "desktop-virtualization-application-group-reader",
    "desktop-virtualization-workspace-contributor",
    "desktop-virtualization-workspace-reader",
    "desktop-virtualization-user-session-operator",
    "desktop-virtualization-session-host-operator",
    "desktop-virtualization-power-on-contributor",
    "desktop-virtualization-power-on-off-contributor",
    "desktop-virtualization-virtual-machine-contributor"
    ])

}
resource "azuread_group" "avd-groups" {
  for_each = local.display_name
  display_name = "sg-${var.env}-${var.prefix}-${var.solution}-${each.value}-01"
  security_enabled = true
}
