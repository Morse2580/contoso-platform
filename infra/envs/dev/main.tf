terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  features {}
}

# Configure the Databricks Provider
provider "databricks" {
  # This assumes you are logged into Azure CLI.
  # The provider will authenticate automatically.
}

resource "azurerm_resource_group" "infra" {
  name     = var.resource_group_names[var.environment]
  location = var.location
}

# Module calls for dev infrastructure
module "network" {
  source              = "../../modules/network"
  environment         = var.environment
  location            = var.location
  resource_group_name = var.resource_group_names[var.environment]
  hub_address_space   = "10.0.0.0/16"
  spoke_address_spaces = {
    dev = "10.1.0.0/16"
    qa  = "10.2.0.0/16"
    prod= "10.3.0.0/16"
  }
}

module "keyvault" {
  source                      = "../../modules/keyvault"
  environment                 = var.environment
  location                    = var.location
  resource_group_name         = var.resource_group_names[var.environment]
  tenant_id                   = var.tenant_id
  kv_name_prefix              = "kv-contoso"

  # <-- HERE we pull the subnet ID from the network module output
  private_endpoint_subnet_id  = module.network.spoke_private_endpoint_ids[var.environment]
}

module "storage" {
  source                      = "../../modules/storage"
  environment                 = var.environment
  location                    = var.location
  resource_group_name         = var.resource_group_names[var.environment]
  storage_account_name_prefix = "stcontosodata"
  domains                     = var.domains
  private_endpoint_subnet_ids = module.network.spoke_private_endpoint_ids
  storage_spn_object_id       = var.storage_spn_object_id
}

locals {
  workspace_name = "${var.org_prefix}-${var.environment}-${var.location_short}-ws"
}


###############################################################################
# 0) Create and store Databricks SPN & secret in Key Vault
###############################################################################
# 0.1) Register an AAD application
resource "azuread_application" "dbx_app" {
  display_name = "dbx-spn-dev"
}

# 0.2) Create a Service Principal for it
resource "azuread_service_principal" "dbx_sp" {
  # v2+ of the provider wants "client_id" instead of "application_id"
  client_id = azuread_application.dbx_app.client_id
}

# 0.3) Create a long-lived password for the SPN
resource "azuread_application_password" "dbx_secret" {
  # v2+ wants "application_id" instead of "application_object_id"
  application_id = azuread_application.dbx_app.client_id

  # end_date_relative is deprecated, use end_date in RFC3339
  end_date   = "2026-07-07T00:00:00Z"
}

# 0.4) Store the SPN's client ID in Key Vault
resource "azurerm_key_vault_secret" "dbx_id" {
  name         = "databricks-spn-id"
  value        = azuread_application.dbx_app.client_id
  key_vault_id = module.keyvault.key_vault_id
}

# 0.5) Store the SPN’s secret value in Key Vault
resource "azurerm_key_vault_secret" "dbx_secret" {
  name         = "databricks-spn-secret"
  value        = azuread_application_password.dbx_secret.value
  key_vault_id = module.keyvault.key_vault_id
}


module "databricks" {
  source              = "../../modules/databricks"

  # You must supply these because your module expects them:
  org_prefix          = var.org_prefix
  environment         = var.environment
  location_short      = var.location_short

  workspace_name      = local.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_names[var.environment]
  virtual_network_id  = module.network.spoke_vnet_ids[var.environment]
  public_subnet_name  = "WorkloadSubnet"
  private_subnet_name = "PrivateEndpointSubnet"
  databricks_spn_id     = azuread_application.dbx_app.client_id
  databricks_spn_secret = azuread_application_password.dbx_secret.value

  tenant_id             = var.tenant_id
}

