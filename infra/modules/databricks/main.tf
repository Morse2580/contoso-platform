terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.0"
    }
  }
}

provider "databricks" {
  host                         = azurerm_databricks_workspace.this.workspace_url
  azure_client_id              = var.databricks_spn_id
  azure_client_secret          = var.databricks_spn_secret
  azure_tenant_id              = var.tenant_id
  azure_workspace_resource_id  = azurerm_databricks_workspace.this.id
}


locals {
  workspace_name = "${var.org_prefix}-${var.environment}-${var.location_short}-ws"
}


resource "azurerm_databricks_workspace" "this" {
  name                        = local.workspace_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  sku                         = "premium"
  managed_resource_group_name = "rg-db-${local.workspace_name}"

  custom_parameters {
    virtual_network_id  = var.virtual_network_id
    public_subnet_name  = var.public_subnet_name
    private_subnet_name = var.private_subnet_name
  }
}