provider "azurerm" {
  features {}
}

resource "azurerm_management_group" "parent-jvn" {
  display_name =  "mg-${var.CompanyManagementGroupName}"
}
resource "azurerm_management_group" "decom-mg" {
  display_name = "mg-${var.shortcompanyname}-${var.decomissioned}"
  parent_management_group_id = azurerm_management_group.parent-jvn.id
  depends_on = [
    azurerm_management_group.parent-jvn
  ]
}
resource "azurerm_management_group" "landingzones-mg" {
  display_name = "mg-${var.shortcompanyname}-${var.landingzones}"
  parent_management_group_id = azurerm_management_group.parent-jvn.id
  depends_on = [
    azurerm_management_group.parent-jvn
  ]
}
resource "azurerm_management_group" "corp" {
    display_name = "mg-${var.shortcompanyname}-${var.corp}"
    parent_management_group_id = azurerm_management_group.landingzones-mg.id
    depends_on = [
      azurerm_management_group.landingzones-mg
    ]
  
}
resource "azurerm_management_group" "online" {
    display_name = "mg-${var.shortcompanyname}-${var.online}"
    parent_management_group_id = azurerm_management_group.landingzones-mg.id
    depends_on = [
      azurerm_management_group.landingzones-mg
    ]
}
resource "azurerm_management_group" "sap" {
    display_name = "mg-${var.shortcompanyname}-${var.sap}"
    parent_management_group_id = azurerm_management_group.landingzones-mg.id
    depends_on = [
      azurerm_management_group.landingzones-mg
    ]
  
}
resource "azurerm_management_group" "platform" {
    display_name = "mg-${var.shortcompanyname}-${var.platform}"
    parent_management_group_id = azurerm_management_group.parent-jvn.id
    depends_on = [
      azurerm_management_group.parent-jvn
    ]
  
}
resource "azurerm_management_group" "connectivity" {
    display_name = "mg-${var.shortcompanyname}-${var.connectivity}"
    parent_management_group_id = azurerm_management_group.platform.id
    depends_on = [
      azurerm_management_group.platform
    ]
  
}
resource "azurerm_management_group" "identity" {
    display_name = "mg-${var.shortcompanyname}-${var.identity}"
    parent_management_group_id = azurerm_management_group.platform.id
    depends_on = [
      azurerm_management_group.platform
    ]
}
resource "azurerm_management_group" "management" {
    display_name = "mg-${var.shortcompanyname}-${var.management}"
    parent_management_group_id = azurerm_management_group.platform.id
    depends_on = [
      azurerm_management_group.platform
    ]
  
}
resource "azurerm_management_group" "sandboxes" {
    display_name = "mg-${var.shortcompanyname}-${var.sandboxes}"
    parent_management_group_id = azurerm_management_group.parent-jvn.id
    depends_on = [
      azurerm_management_group.parent-jvn
    ]
  
}
