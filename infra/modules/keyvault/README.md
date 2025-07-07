# Key Vault Module: Enterprise Secret Management 🔐

Welcome to the Key Vault module! This is your **digital fortress** for managing secrets, keys, and certificates. Think of this as the **high-security vault** where all your sensitive information is stored, protected, and carefully controlled.

## 🎯 What Does This Module Do?

This module creates a **centralized secret management solution** with:

1. **🏛️ Azure Key Vault** - Hardware-backed secret storage
2. **🔒 Private Endpoint Access** - Secure network connectivity
3. **👥 RBAC Authorization** - Role-based access control
4. **🛡️ Network Security** - Deny-by-default with explicit allow
5. **📋 Access Policies** - Fine-grained permission management

## 🏗️ Architecture Overview

```
                    Internet
                        │
                        ▼
            ┌───────────────────────┐
            │    Azure Firewall     │
            │    (Blocks access)    │
            └───────────┬───────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│                 SPOKE NETWORK                           │
│               (10.1.0.0/16)                             │
│                                                         │
│  ┌─────────────────┐       ┌─────────────────────────┐  │
│  │  Workload       │       │  Private Endpoint       │  │
│  │  Subnet         │       │  Subnet                 │  │
│  │  (10.1.1.0/24)  │       │  (10.1.0.64/27)        │  │
│  │                 │       │                         │  │
│  │  ┌───────────┐  │       │  ┌───────────────────┐  │  │
│  │  │Databricks │  │       │  │ Private Endpoint  │  │  │
│  │  │Apps &     │  │──────▶│  │ to Key Vault      │  │  │
│  │  │Services   │  │       │  │ (Secure Access)   │  │  │
│  │  └───────────┘  │       │  └───────────────────┘  │  │
│  └─────────────────┘       └─────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                                │
                                ▼ (Private Connection)
                ┌─────────────────────────────────────┐
                │         Azure Key Vault             │
                │      (kv-contoso-dev)               │
                │                                     │
                │  ┌─────────────────────────────┐    │
                │  │          SECRETS            │    │
                │  │                             │    │
                │  │  📋 databricks-spn-id       │    │
                │  │  🔑 databricks-spn-secret   │    │
                │  │  🗝️ storage-account-key     │    │
                │  │  🔐 database-password       │    │
                │  │  📜 api-connection-string   │    │
                │  │                             │    │
                │  └─────────────────────────────┘    │
                │                                     │
                │  ┌─────────────────────────────┐    │
                │  │        ACCESS CONTROL       │    │
                │  │                             │    │
                │  │  👤 RBAC Enabled           │    │
                │  │  🛡️ Access Policies         │    │
                │  │  📊 Audit Logging          │    │
                │  │  🔍 Monitoring Enabled     │    │
                │  │                             │    │
                │  └─────────────────────────────┘    │
                └─────────────────────────────────────┘
```

## 🧩 Resource Breakdown

Let's explore each component and understand the **security architecture**:

### 1. Azure Key Vault Core 🏛️

```hcl
resource "azurerm_key_vault" "this" {
  name                        = "${var.kv_name_prefix}-${var.environment}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"           # Standard tier for most use cases

  # Modern RBAC approach (recommended)
  enable_rbac_authorization   = true                 # 🎯 Use RBAC instead of access policies
  purge_protection_enabled    = false               # Allow deletion in dev/test
  soft_delete_retention_days  = 90                  # 90-day soft delete retention

  # Zero-trust network security
  network_acls {
    default_action             = "Deny"             # 🔒 Deny all by default
    bypass                     = "AzureServices"    # Allow Azure services
    virtual_network_subnet_ids = []                 # No direct VNet access (we use private endpoints)
  }
}
```

**Key Configuration Explained:**

- **`enable_rbac_authorization = true`** - **Modern security approach**
  - Uses Azure RBAC for access control
  - More flexible than traditional access policies
  - Easier to manage at scale
  - Consistent with other Azure services

- **`purge_protection_enabled = false`** - **Environment considerations**
  - In **production**: Set to `true` for compliance
  - In **dev/test**: Set to `false` for easier cleanup
  - Prevents accidental permanent deletion

- **`soft_delete_retention_days = 90`** - **Data protection**
  - Deleted secrets are recoverable for 90 days
  - Balances security with operational flexibility
  - Configurable from 7 to 90 days

### 2. Private Endpoint (The Secure Gateway) 🚪

```hcl
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${azurerm_key_vault.this.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${azurerm_key_vault.this.name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]          # Connect to Key Vault service
    is_manual_connection           = false              # Auto-approve connection
  }
}
```

**Private Endpoint Benefits:**

- **Network isolation** - No public internet exposure
- **Azure backbone** - Traffic stays on Microsoft network
- **DNS integration** - Automatic private DNS resolution
- **Compliance** - Meets strict security requirements

### 3. Access Control Layer 👥

```hcl
# Get current Azure context for configuration
data "azurerm_client_config" "current" {}

# Grant access to the current user/service principal
resource "azurerm_key_vault_access_policy" "dbx_msi" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List"]  # Read-only permissions
}
```

**Access Policy vs RBAC:**

While we enable RBAC, we also configure access policies for **hybrid scenarios**:

- **RBAC** - For Azure AD users and managed identities
- **Access Policies** - For legacy applications and specific scenarios
- **Principle of least privilege** - Only necessary permissions granted

## 🔐 Security Deep Dive

### Network Security Layers

```
1. Azure Firewall     → Blocks unauthorized outbound traffic
          ↓
2. Private Endpoint   → Private network connection only
          ↓
3. Key Vault ACLs     → Deny-by-default network rules
          ↓
4. RBAC/Policies      → Fine-grained access control
          ↓
5. Audit Logging      → All access logged and monitored
```

### Authentication Flow

```
Application (Databricks)
         │ (Service Principal)
         ▼
    Azure AD Authentication
         │ (JWT Token)
         ▼
    Private Endpoint
         │ (Secure Channel)
         ▼
    Key Vault RBAC Check
         │ (Authorization)
         ▼
    Secret Access Granted
```

## 📤 Module Outputs

```hcl
# Key Vault resource information
output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

# Private endpoint details
output "private_endpoint_id" {
  description = "Resource ID of the Key Vault private endpoint"
  value       = azurerm_private_endpoint.kv_pe.id
}

output "private_endpoint_ip" {
  description = "Private IP address of the Key Vault"
  value       = azurerm_private_endpoint.kv_pe.private_service_connection[0].private_ip_address
}
```

## 🔗 Module Integration Examples

### How Secrets Are Stored

```hcl
# In the main environment configuration
resource "azurerm_key_vault_secret" "databricks_spn_id" {
  name         = "databricks-spn-id"
  value        = azuread_application.dbx_app.client_id
  key_vault_id = module.keyvault.key_vault_id
}

resource "azurerm_key_vault_secret" "databricks_spn_secret" {
  name         = "databricks-spn-secret"
  value        = azuread_application_password.dbx_secret.value
  key_vault_id = module.keyvault.key_vault_id
}
```

### How Applications Access Secrets

```python
# Example: Databricks accessing secrets
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

# Authenticate using service principal
credential = DefaultAzureCredential()

# Connect to Key Vault via private endpoint
client = SecretClient(
    vault_url="https://kv-contoso-dev.vault.azure.net/",
    credential=credential
)

# Retrieve secrets securely
spn_id = client.get_secret("databricks-spn-id").value
storage_key = client.get_secret("storage-account-key").value
```

### Terraform Configuration Access

```hcl
# Reference secrets in other resources
data "azurerm_key_vault_secret" "databricks_spn_id" {
  name         = "databricks-spn-id"
  key_vault_id = module.keyvault.key_vault_id
}

# Use in Databricks configuration
resource "databricks_cluster" "example" {
  # ... other configuration
  
  spark_conf = {
    "fs.azure.account.auth.type.${var.storage_account}.dfs.core.windows.net" = "SAS"
    "fs.azure.account.oauth2.client.id.${var.storage_account}.dfs.core.windows.net" = data.azurerm_key_vault_secret.databricks_spn_id.value
  }
}
```

## 📊 Variables Reference

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `kv_name_prefix` | string | Prefix for Key Vault name | `"kv-contoso"` |
| `environment` | string | Environment suffix | `"dev"` |
| `location` | string | Azure region | `"North Europe"` |
| `resource_group_name` | string | Resource group | `"rg-contoso-infra-dev"` |
| `tenant_id` | string | Azure AD tenant ID | `"12345678-1234-..."` |
| `private_endpoint_subnet_id` | string | Subnet ID for private endpoint | `"/subscriptions/.../subnets/pe"` |

## 🎯 Usage Example

```hcl
module "keyvault" {
  source = "../../modules/keyvault"
  
  environment         = "dev"
  location           = "North Europe"
  resource_group_name = "rg-contoso-infra-dev"
  tenant_id          = var.tenant_id
  kv_name_prefix     = "kv-contoso"
  
  # Network integration (from network module)
  private_endpoint_subnet_id = module.network.spoke_private_endpoint_ids[var.environment]
}
```

## 🛡️ Advanced Security Features

### RBAC Role Assignments

```hcl
# Grant Key Vault Secrets User role to Databricks managed identity
resource "azurerm_role_assignment" "databricks_kv_access" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.databricks_managed_identity_id
}

# Grant Key Vault Administrator role to DevOps team
resource "azurerm_role_assignment" "devops_kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.devops_team_group_id
}
```

### Certificate Management

```hcl
# Store SSL certificates securely
resource "azurerm_key_vault_certificate" "app_ssl" {
  name         = "app-ssl-certificate"
  key_vault_id = azurerm_key_vault.this.id

  certificate_policy {
    issuer_parameters {
      name = "Self"  # Or your CA
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}
```

### Advanced Access Policies

```hcl
# Fine-grained access for different teams
resource "azurerm_key_vault_access_policy" "developers" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = var.developers_group_id

  secret_permissions = [
    "Get",                    # Read secrets
    "List",                   # List secret names
  ]
}

resource "azurerm_key_vault_access_policy" "admins" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = var.tenant_id
  object_id    = var.admins_group_id

  secret_permissions = [
    "Get", "List", "Set",     # Full secret management
    "Delete", "Recover", "Backup", "Restore"
  ]

  key_permissions = [
    "Get", "List", "Create",  # Full key management
    "Delete", "Recover", "Backup", "Restore"
  ]

  certificate_permissions = [
    "Get", "List", "Create",  # Full certificate management
    "Delete", "Recover", "Import", "ManageContacts", "ManageIssuers"
  ]
}
```

## 🔍 Monitoring and Compliance

### Diagnostic Settings

```hcl
# Enable comprehensive logging
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "keyvault-diagnostics"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "AuditEvent"  # All access attempts
    enabled  = true

    retention_policy {
      enabled = true
      days    = 365        # Retain for compliance
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 365
    }
  }
}
```

### Security Alerts

```hcl
# Alert on suspicious activity
resource "azurerm_monitor_metric_alert" "keyvault_failures" {
  name                = "keyvault-access-failures"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_key_vault.this.id]

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "ServiceApiResult"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 10

    dimension {
      name     = "StatusCode"
      operator = "Include"
      values   = ["403", "404"]  # Unauthorized and not found
    }
  }
}
```

## 🎓 Best Practices

### Secret Naming Conventions

```
Environment-based:
├── dev-database-password
├── qa-database-password
└── prod-database-password

Service-based:
├── databricks-spn-id
├── databricks-spn-secret
├── storage-account-key
└── app-registration-secret

Category-based:
├── database/mysql-password
├── storage/account-key
├── api/external-service-token
└── certificates/ssl-cert
```

### Secret Rotation Strategy

```hcl
# Automatic secret rotation (example)
resource "azurerm_key_vault_secret" "database_password" {
  name         = "database-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.this.id

  # Rotation metadata
  tags = {
    rotation_frequency = "90-days"
    last_rotated      = timestamp()
    next_rotation     = timeadd(timestamp(), "2160h")  # 90 days
  }
}
```

### Environment-Specific Configuration

```hcl
# Production hardening
locals {
  is_production = var.environment == "prod"
  
  key_vault_config = {
    sku_name                  = local.is_production ? "premium" : "standard"
    purge_protection_enabled  = local.is_production ? true : false
    soft_delete_retention     = local.is_production ? 90 : 7
  }
}
```

## 🎓 Learning Takeaways

1. **Private endpoints** eliminate public internet exposure
2. **RBAC** provides modern, flexible access control
3. **Zero-trust networking** defaults to deny with explicit allow
4. **Soft delete** protects against accidental deletion
5. **Audit logging** provides complete access trails
6. **Network integration** works seamlessly with hub-spoke topology

## 🔄 Next Steps

- Explore [Databricks Module](../databricks/README.md) to see how it securely accesses secrets
- Check [Storage Module](../storage/README.md) for understanding private endpoint patterns
- Review [Environment Management](../../envs/dev/README.md) for secret integration examples

This Key Vault foundation provides enterprise-grade secret management for your entire platform! 🚀
