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
  provider = azurerm.hub
  name = "law-hub-${var.prefix}-01"
  resource_group_name = "rg-${var.env}-${var.prefix}-management-01" 
}
data "azurerm_resource_group" "rg-kv" {
  provider = azurerm.hub
  name = "rg-${var.env}-${var.prefix}-management-01"
}
data "azurerm_key_vault" "kv" {
    provider = azurerm.hub
    name = "kv-${var.env}-${var.prefix}-99"
    resource_group_name = "rg-${var.env}-${var.prefix}-management-01"
}
resource "azurerm_key_vault_key" "vm-key" {
    provider = azurerm.hub
  name         = "key-hub-vm-01"
  key_vault_id = data.azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  depends_on = [
    azurerm_key_vault_access_policy.kv-user
  ]

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_disk_encryption_set" "en-set" {
    provider = azurerm.hub
  name                = "des-${var.env}-${var.prefix}-01"
  resource_group_name = data.azurerm_resource_group.rg-kv.name
  location            = data.azurerm_resource_group.rg-kv.location
  key_vault_key_id    = azurerm_key_vault_key.vm-key.id

  identity {
    type = "SystemAssigned"
  }
 
}

resource "azurerm_key_vault_access_policy" "vm-disk" {
    provider = azurerm.hub
  key_vault_id = data.azurerm_key_vault.kv.id

  tenant_id = azurerm_disk_encryption_set.en-set.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.en-set.identity.0.principal_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign"
  ]
}
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault_access_policy" "kv-user" {
    provider = azurerm.hub
  key_vault_id = data.azurerm_key_vault.kv.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Delete",
    "Get",
    "Purge",
    "Recover",
    "Update",
    "List",
    "Decrypt",
    "Sign"
  ]
}

resource "azurerm_role_assignment" "vm-disk" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_disk_encryption_set.en-set.identity.0.principal_id
}
resource "azurerm_key_vault_access_policy" "kv-access-policy-des" {
    provider = azurerm.hub
  key_vault_id = data.azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_disk_encryption_set.en-set.identity.0.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}
