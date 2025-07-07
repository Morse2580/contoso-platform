# 1) ADLS Gen2 Storage Account
resource "azurerm_storage_account" "adls" {
  name                     = "${var.storage_account_name_prefix}${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true  # Enable hierarchical namespace for Gen2

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [
      # Pick the correct subnet ID for this environment; empty list if not set
      var.private_endpoint_subnet_ids[var.environment]
    ]
  }
}

# 3) Containers per business domain
resource "azurerm_storage_container" "domains" {
  for_each              = toset(var.domains)
  name                  = lower(each.value)
  storage_account_id    = azurerm_storage_account.adls.id
  container_access_type = "private"
}

# 4) Assign Blob Data Contributor to your SPN on each domain container
resource "azurerm_role_assignment" "storage_spn" {
  for_each             = azurerm_storage_container.domains
  scope                = each.value.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.storage_spn_object_id
}
