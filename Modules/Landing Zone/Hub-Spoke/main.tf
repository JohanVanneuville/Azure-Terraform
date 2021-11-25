provider "azurerm" {
  features {}
}

##Create AVD Networking Resource Group for spoke vnet
resource "azurerm_resource_group" "hub-rg" {
  name     = "rg-${var.prefix}-vnet-hub-weu"
  location = var.location
}
resource "azurerm_resource_group" "spoke-rg" {
  name     = "rg-${var.prefix}-vnet-spoke-weu"
  location = var.location
}
#VNETs and Subnets
#Spoke VNET and Subnets for hostpool
#add custom dns servers from customer
#dns server from Azure and my own dns is also defined here
resource "azurerm_virtual_network" "hub-vnet" {
  name                = "vnet-${var.prefix}-hub-weu"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub-rg.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["168.63.129.16", "10.5.0.4"]
  tags = {
    Environment = var.environment
    location = var.location
  }
}
resource "azurerm_virtual_network" "hub-spoke-vnet" {
  name                = "vnet-${var.prefix}-spoke-weu"
  location            = var.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
  address_space       = ["10.1.0.0/16"]
  dns_servers         = ["168.63.129.16", "10.5.0.4"]
  tags = {
    Environment = var.environment
    location = var.location
  }
}
resource "azurerm_subnet" "spoke-snet-rg" {
  name                 = "snet-${var.prefix}-spoke--weu"
  resource_group_name  = azurerm_resource_group.spoke-rg.name
  virtual_network_name = azurerm_virtual_network.hub-spoke-vnet.name
  address_prefixes     = ["10.1.0.0/16"]
}
resource "azurerm_network_security_group" "nsg-spoke" {
  name                = "nsg-${var.prefix}-jvn-spoke-weu"
  location            = azurerm_resource_group.spoke-rg.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_group" "nsg-hub" {
  name                = "nsg-${var.prefix}-jvn-hub-weu"
  location            = azurerm_resource_group.hub-rg.location
  resource_group_name = azurerm_resource_group.hub-rg.name
  security_rule {
    name                       = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_virtual_network_peering" "spoke2hub-peer" {
  name                      = "spoke2hub"
  resource_group_name       = azurerm_resource_group.spoke-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-spoke-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  
}
resource "azurerm_virtual_network_peering" "hub2spoke-peer" {
  name                      = "hub2spoke"
  resource_group_name       = azurerm_resource_group.hub-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-spoke-vnet.id
  
}

