# Storage Module: Domain-Driven Data Lake Architecture 🗄️

Welcome to the Storage module! This is where we implement a **modern data lake architecture** using Azure Data Lake Storage Gen2. Think of this as the **organized filing system** for your enterprise data - structured, secure, and scalable.

## 🎯 What Does This Module Do?

This module creates an enterprise-grade data storage solution with:

1. **🏢 ADLS Gen2 Storage** - Hierarchical namespace for big data analytics
2. **🏷️ Domain-Based Organization** - Separate containers for business domains
3. **🔐 Network Security** - Private endpoints and firewall integration
4. **👤 Role-Based Access** - Fine-grained permissions per domain
5. **🔒 Zero-Trust Networking** - Deny-by-default security model

## 🏗️ Architecture Overview

```
                    Internet
                        │
                        ▼
            ┌───────────────────────┐
            │    Azure Firewall     │
            │    (Hub Network)      │
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
│  │  │Analytics  │  │──────▶│  │ to Storage        │  │  │
│  │  │Workloads  │  │       │  │ (Secure Access)   │  │  │
│  │  └───────────┘  │       │  └───────────────────┘  │  │
│  └─────────────────┘       └─────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                                │
                                ▼
                ┌─────────────────────────────────────┐
                │      ADLS Gen2 Storage              │
                │    (stcontosodatadev)               │
                │                                     │
                │  ┌─────────────┐  ┌─────────────┐  │
                │  │  Finance    │  │ Marketing   │  │
                │  │ Container   │  │ Container   │  │
                │  │             │  │             │  │
                │  │ ┌─────────┐ │  │ ┌─────────┐ │  │
                │  │ │Raw Data │ │  │ │Raw Data │ │  │
                │  │ │Processed│ │  │ │Processed│ │  │
                │  │ │Curated  │ │  │ │Curated  │ │  │
                │  │ └─────────┘ │  │ └─────────┘ │  │
                │  └─────────────┘  └─────────────┘  │
                │                                     │
                │  ┌─────────────┐                   │
                │  │    Sales    │                   │
                │  │  Container  │                   │
                │  │             │                   │
                │  │ ┌─────────┐ │                   │
                │  │ │Raw Data │ │                   │
                │  │ │Processed│ │                   │
                │  │ │Curated  │ │                   │
                │  │ └─────────┘ │                   │
                │  └─────────────┘                   │
                └─────────────────────────────────────┘
```

## 🧩 Resource Breakdown

Let's explore each component and understand the **business logic** behind it:

### 1. ADLS Gen2 Storage Account 🗃️

```hcl
resource "azurerm_storage_account" "adls" {
  name                     = "${var.storage_account_name_prefix}${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"           # Latest generation
  account_tier             = "Standard"           # Cost-effective tier
  account_replication_type = "LRS"                # Local redundancy
  is_hns_enabled           = true                 # 🎯 This makes it Data Lake!

  network_rules {
    default_action             = "Deny"           # 🔒 Zero-trust security
    bypass                     = ["AzureServices"] # Allow Azure services
    virtual_network_subnet_ids = [
      var.private_endpoint_subnet_ids[var.environment]  # Only our private subnet
    ]
  }
}
```

**Key Configuration Explained:**

- **`is_hns_enabled = true`** - This is the **magic setting** that transforms a regular storage account into ADLS Gen2!
  - **Hierarchical Namespace** enables file system semantics
  - **Better performance** for analytics workloads
  - **POSIX-compliant** permissions
  - **Directory operations** become atomic

- **`default_action = "Deny"`** - **Zero-trust networking**
  - No public internet access by default
  - Only explicitly allowed networks can connect
  - Forces all access through private endpoints

### 2. Domain-Based Containers 📦

```hcl
resource "azurerm_storage_container" "domains" {
  for_each              = toset(var.domains)  # Creates one per domain
  name                  = lower(each.value)   # Lowercase for consistency
  storage_account_id    = azurerm_storage_account.adls.id
  container_access_type = "private"           # No anonymous access
}
```

**Domain-Driven Design in Action:**

This follows **Domain-Driven Design (DDD)** principles:

```hcl
domains = ["finance", "marketing", "sales"]
```

**Results in:**
- `finance` container → Financial data, reports, budgets
- `marketing` container → Campaign data, customer analytics
- `sales` container → CRM data, sales forecasts

**Benefits:**
- **Data governance** - Clear ownership boundaries
- **Security isolation** - Separate access controls per domain
- **Scalability** - Each domain can grow independently
- **Compliance** - Easier to implement domain-specific policies

### 3. Role-Based Access Control 👥

```hcl
resource "azurerm_role_assignment" "storage_spn" {
  for_each             = azurerm_storage_container.domains
  scope                = each.value.id                    # Container-level scope
  role_definition_name = "Storage Blob Data Contributor"  # Read/write permissions
  principal_id         = var.storage_spn_object_id        # Service principal
}
```

**Security Model Explained:**

- **Container-level permissions** - Each domain container has separate access
- **Service Principal authentication** - Machine-to-machine security
- **Principle of least privilege** - Only necessary permissions granted

**Role Hierarchy:**
```
Storage Blob Data Owner      → Full control (create, read, update, delete)
Storage Blob Data Contributor → Read/write access (our choice)
Storage Blob Data Reader     → Read-only access
```

## 🔗 Network Integration Deep Dive

### Private Endpoint Connection Flow

```
Analytics Workload (Databricks)
         │
         ▼
    Workload Subnet (10.1.1.0/24)
         │
         ▼ (Internal routing)
    Private Endpoint Subnet (10.1.0.64/27)
         │
         ▼ (Private connection)
    ADLS Gen2 Storage Account
         │
         ▼ (Container access)
    Domain-specific containers
```

### Network Security Layers

1. **Azure Firewall** - Inspects outbound traffic from workloads
2. **VNet Integration** - Traffic stays within private network
3. **Private Endpoints** - Direct, secure connection to storage
4. **Storage Firewall** - Denies all public access
5. **RBAC** - Fine-grained access control

## 📤 Module Outputs

```hcl
# Storage account details for other modules
output "storage_account_id" {
  description = "Resource ID of the ADLS Gen2 storage account"
  value       = azurerm_storage_account.adls.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.adls.name
}

# Container information for data pipelines
output "domain_containers" {
  description = "Map of domain names to container resource IDs"
  value       = {
    for domain, container in azurerm_storage_container.domains:
    domain => {
      id   = container.id
      name = container.name
      url  = container.url
    }
  }
}

# Primary endpoints for applications
output "primary_endpoints" {
  description = "Primary endpoints for different storage services"
  value = {
    blob  = azurerm_storage_account.adls.primary_blob_endpoint
    dfs   = azurerm_storage_account.adls.primary_dfs_endpoint   # ADLS Gen2 endpoint
    file  = azurerm_storage_account.adls.primary_file_endpoint
    table = azurerm_storage_account.adls.primary_table_endpoint
  }
}
```

## 🔗 Module Integration Examples

### How Databricks Connects

```hcl
# In the main environment configuration
module "databricks" {
  source = "../../modules/databricks"
  
  # Network connectivity (from network module)
  virtual_network_id = module.network.spoke_vnet_ids[var.environment]
  
  # Storage access (this module provides the account)
  storage_account_name = module.storage.storage_account_name
  
  # Authentication (service principal can access containers)
  databricks_spn_id = azuread_application.dbx_app.client_id
}
```

### Data Pipeline Access Pattern

```python
# Example: Accessing finance data from Databricks
spark.conf.set(
    f"fs.azure.account.auth.type.{storage_account}.dfs.core.windows.net", 
    "SAS"
)

# Read from finance container
df_finance = spark.read.parquet(
    f"abfss://finance@{storage_account}.dfs.core.windows.net/raw/transactions/"
)

# Process data and write to processed zone
df_processed.write.mode("overwrite").parquet(
    f"abfss://finance@{storage_account}.dfs.core.windows.net/processed/daily_summary/"
)
```

## 📊 Variables Reference

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `storage_account_name_prefix` | string | Prefix for storage account name | `"stcontosodata"` |
| `environment` | string | Environment suffix | `"dev"` |
| `resource_group_name` | string | Resource group | `"rg-contoso-infra-dev"` |
| `location` | string | Azure region | `"North Europe"` |
| `domains` | list(string) | Business domains | `["finance", "marketing", "sales"]` |
| `private_endpoint_subnet_ids` | map(string) | Map env → subnet ID | `{dev = "/subscriptions/.../subnets/pe"}` |
| `storage_spn_object_id` | string | Service principal object ID | `"12345678-1234-..."` |

## 🎯 Usage Example

```hcl
module "storage" {
  source = "../../modules/storage"
  
  environment                 = "dev"
  location                   = "North Europe"
  resource_group_name        = "rg-contoso-infra-dev"
  storage_account_name_prefix = "stcontosodata"
  
  # Business domains for container creation
  domains = ["finance", "marketing", "sales", "hr", "operations"]
  
  # Network integration (from network module)
  private_endpoint_subnet_ids = module.network.spoke_private_endpoint_ids
  
  # Access control
  storage_spn_object_id = var.databricks_spn_object_id
}
```

## 🗂️ Data Organization Best Practices

### Recommended Folder Structure

Each domain container should follow a **medallion architecture**:

```
finance/
├── raw/                    # Bronze layer - raw ingested data
│   ├── transactions/
│   ├── accounts/
│   └── customers/
├── processed/              # Silver layer - cleaned and validated
│   ├── daily_summaries/
│   ├── customer_profiles/
│   └── transaction_enriched/
└── curated/               # Gold layer - business-ready datasets
    ├── financial_reports/
    ├── kpi_dashboards/
    └── ml_features/
```

### Naming Conventions

- **Container names**: lowercase, business domain aligned
- **Folder structure**: `{layer}/{entity}/{partition}`
- **File formats**: Parquet for analytics, Delta for transactional

## 🔧 Advanced Features

### Access Control Scenarios

```hcl
# Additional role assignments for different teams
resource "azurerm_role_assignment" "finance_analysts" {
  scope                = azurerm_storage_container.domains["finance"].id
  role_definition_name = "Storage Blob Data Reader"  # Read-only for analysts
  principal_id         = var.finance_team_group_id
}

resource "azurerm_role_assignment" "data_engineers" {
  scope                = azurerm_storage_account.adls.id  # Full storage access
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.data_engineering_group_id
}
```

### Lifecycle Management

```hcl
# Add to storage account resource
lifecycle_rule {
  enabled = true
  
  rule {
    name = "archive_old_raw_data"
    
    filters {
      prefix_match = ["raw/"]
    }
    
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification    = 30
        tier_to_archive_after_days_since_modification = 90
        delete_after_days_since_modification          = 365
      }
    }
  }
}
```

## 🛡️ Security Features

### Defense in Depth

1. **Network Level**
   - Private endpoints only
   - No public internet access
   - Firewall inspection

2. **Storage Level**
   - Network rules deny-by-default
   - Container-level access control
   - Service principal authentication

3. **Data Level**
   - POSIX permissions (ADLS Gen2)
   - Role-based access control
   - Audit logging enabled

### Compliance Features

- **Data residency** - Data stays in specified region
- **Encryption** - At rest and in transit by default
- **Audit trails** - All access logged and monitored
- **Immutable storage** - Can be enabled for compliance

## 🎓 Learning Takeaways

1. **ADLS Gen2** combines blob storage scalability with file system semantics
2. **Domain-driven design** improves data governance and security
3. **Private endpoints** enable secure, private cloud connectivity
4. **RBAC** provides fine-grained access control at container level
5. **Zero-trust networking** defaults to deny with explicit allow rules

## 🔄 Next Steps

- Explore [Databricks Module](../databricks/README.md) to see how analytics workloads consume this data
- Check [Key Vault Module](../keyvault/README.md) for storing access keys securely
- Review [Network Module](../network/README.md) for understanding the networking foundation

This storage foundation provides secure, scalable data lake capabilities for your enterprise! 🚀
