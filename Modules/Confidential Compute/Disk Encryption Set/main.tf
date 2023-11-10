data "azurerm_resource_group" "rg-kv" {
  provider = azurerm.hub
  name = "rg-${var.env}-${var.prefix}-avd-management-01"
}
data "azurerm_key_vault" "kv" {
    provider = azurerm.hub
    name = "kv-${var.env}-${var.prefix}-avd-80"
    resource_group_name = "rg-${var.env}-${var.prefix}-avd-management-01"
}
data "azurerm_key_vault_key" "avd-key" {
  name = "key-prd-jvn-avd-10"
  key_vault_id = data.azurerm_key_vault.kv.id
}
resource "azurerm_disk_encryption_set" "en-set" {
    provider = azurerm.hub
  name                = "des-${var.env}-${var.prefix}-avd-50"
  resource_group_name = data.azurerm_resource_group.rg-kv.name
  location            = data.azurerm_resource_group.rg-kv.location
  key_vault_key_id    = data.azurerm_key_vault_key.avd-key.id
  encryption_type = "ConfidentialVmEncryptedWithCustomerKey"

  identity {
    type = "SystemAssigned"
  }
 
}
