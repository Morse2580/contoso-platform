# Key Vault module - Key Vault & secrets
# Key Vault
resource "azurerm_key_vault" "this" {
  name                        = "${var.kv_name_prefix}-${var.environment}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"

  # Disable vault access policies in favor of RBAC
  enable_rbac_authorization   = true
  purge_protection_enabled    = false
  soft_delete_retention_days  = 90

  # Only allow from your spokes (via the firewall we set up)
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = []  # we'll add PEs next
  }
}


# Private Endpoint for KV
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${azurerm_key_vault.this.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${azurerm_key_vault.this.name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}

# Grant Databricks MSI access to read secrets
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_access_policy" "dbx_msi" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List"]
}