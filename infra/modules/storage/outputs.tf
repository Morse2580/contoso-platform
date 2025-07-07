# infra/modules/storage/outputs.tf

# 1) Container IDs map (domains only)
output "container_ids" {
  description = "Map of container name → resource ID for each business domain"
  value = {
    for dom, ctr in azurerm_storage_container.domains :
    dom => ctr.id
  }
}

# 2) Container URLs map (domains only)
output "container_urls" {
  description = "Map of container name → HTTPS URL for each business domain"
  value = {
    for dom in keys(azurerm_storage_container.domains) :
    dom => "${azurerm_storage_account.adls.primary_blob_endpoint}${lower(dom)}"
  }
}