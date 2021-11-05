provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "sig" {
  location = var.location
  name     = "rg-${var.prefix}-sig"
}
# Created Shared Image Gallery
resource "azurerm_shared_image_gallery" "sig" {
  name                = "sig${var.prefix}"
  resource_group_name = azurerm_resource_group.sig.name
  location            = azurerm_resource_group.sig.location
  description         = "Shared images and things."

  tags = {
    Environment = "prd"
    Tech        = "Terraform"
  }
}

resource "azurerm_shared_image" "sig" {
  name                = "wvd-image"
  gallery_name        = azurerm_shared_image_gallery.sig.name
  resource_group_name = azurerm_resource_group.sig.name
  location            = azurerm_resource_group.sig.location
  os_type             = "Windows"

  identifier {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "office-365"
    sku       = "20h2-evd-o365pp"
  }
}
