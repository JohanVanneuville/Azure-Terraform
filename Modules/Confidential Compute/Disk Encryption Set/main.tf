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
