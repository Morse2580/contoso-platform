output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "workspace_id" {
  description = "ARM resource ID of the workspace"
  value       = azurerm_databricks_workspace.this.id
}

# Note: This workspace doesn't have a managed identity configured
# If you need a managed identity, add an identity block to the workspace resource
