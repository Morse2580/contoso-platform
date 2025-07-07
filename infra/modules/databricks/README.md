# Databricks Module: Scalable Analytics Platform 📊

Welcome to the Databricks module! This is where we build the **data-driven heart** of our architecture. Think of this as the **innovation engine** of your data platform - where data meets insights.

## 🎯 What Does This Module Do?

This module sets up a **complete Databricks analytics environment** with:

1. **📈 Databricks Workspace** - Collaboration platform for data engineers
2. **🔗 VNet Injection** - Network security by injecting into VNet
3. **🔒 Secure SPN Authentication** - Access through Azure AD SPN
4. **🚀 Custom Workloads** - Optimized for diverse data workloads
5. **🔗 Integration with Networks and Storage** - Seamless data flow

## 🏗️ Architecture Overview

```
                    Internet
                        │
┌─────────────────────────────────────────────────────────┐
│                 HUB NETWORK                             │
│                   VNet                                  │
│                       │                                 │
│    ┌────────────────┐ │                                 │
│    │  Azure Firewall│ │                                 │
│    └────────────────┘ │                                 │
└────────────▲──────────┘                                 │
             │                                            │
┌────────────┴───────────────┐                            │
│        SPOKE VNET          │                            │
│                            │                            │
│  ┌──────────────────────┐  │  Network traffic controlled│
│  │ Databricks Workspace │◀──────────via Firewall────────┤
│  └──────────────────────┘  │                            │
│        VNet Injection      │                            │
└────────────────────────────┘
```

## 🧩 Resource Breakdown

Let's explore each component and understand the **analytics architecture**:

### 1. Databricks Workspace 📊

```hcl
resource "azurerm_databricks_workspace" "this" {
  name                        = local.workspace_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  sku                         = "premium"             # Premium SKU for additional features
  managed_resource_group_name = "rg-db-${local.workspace_name}"

  custom_parameters {
    virtual_network_id  = var.virtual_network_id       # Inject into VNet
    public_subnet_name  = var.public_subnet_name       # Use designated public subnet
    private_subnet_name = var.private_subnet_name      # Use designated private endpoint
  }
}
```

**Key Configuration Explained:**

- **`sku = "premium"`** - Offers advanced features such as:
  - **High concurrency** clusters
  - **Job management** for automated workflows
  - **Interactive clusters** for collaboration
  - **Advanced analytics** with higher DBU allocation

- **`custom_parameters`** - VNet Injection
  - **Secure network integration** with your Azure VNet
  - **Workloads operate** within secure boundaries
  - **Compliance-friendly** for data processing

### 2. Databricks Provider 🔗

```hcl
provider "databricks" {
  host                         = azurerm_databricks_workspace.this.workspace_url
  azure_client_id              = var.databricks_spn_id
  azure_client_secret          = var.databricks_spn_secret
  azure_tenant_id              = var.tenant_id
  azure_workspace_resource_id  = azurerm_databricks_workspace.this.id
}
```

**Secure Authentication**

- **Service Principal Model** - Uses an Azure AD App Registration
- **Secure access** to your workspace through managed identities
- **Prevents dependency** on personal user tokens

## Provider Configuration Deep Dive

This module requires explicit provider configuration because it uses the `databricks/databricks` provider, which is not owned by HashiCorp.

### Why Provider Declaration is Required

Unlike other Azure resources that use the `azurerm` provider (owned by HashiCorp), Databricks uses a separate provider owned by Databricks Inc. This means:

1. **`azurerm` provider** → Owned by HashiCorp (`hashicorp/azurerm`)
2. **`databricks` provider** → Owned by Databricks (`databricks/databricks`)

### Provider Inheritance vs. Explicit Declaration

- **Root configuration** providers are automatically inherited by child modules
- **Third-party providers** (like Databricks) must be explicitly declared in each module's `required_providers` block
- Without explicit declaration, Terraform defaults to the legacy `hashicorp/databricks` namespace, which doesn't exist

### Required Providers Block

```hcl
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
```

## 🔗 Integration Patterns

### Storage Integration

```hcl
# Connect Databricks to ADLS Storage
module "storage" {
  source = "../../modules/storage"

  # Storage configuration
  storage_account_name = module.storage.storage_account_name
}
```

**Data Flow**

- **Direct read/write** access from Databricks to storage containers
- **Private endpoint** ensures traffic never leaves Azure network
- **Role-based access** allows specific resource permissions

### Network Security

```hcl
# Use network module to dictate security policies
module "network" {
  source = "../../modules/network"

  virtual_network_id  = module.network.spoke_vnet_ids[var.environment]
}
```

**Secure Communication**

- **VNet injection** confines data flow inside private network
- **Firewall policies** restrict and monitor network traffic

## 📤 Module Outputs

```hcl
# Databricks Workspace information
output "workspace_url" {
  description = "URL of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "workspace_id" {
  description = "ARM resource ID of the workspace"
  value       = azurerm_databricks_workspace.this.id
}

# Managed Identity for secure access
output "workspace_spn_id" {
  description = "Service principal ID of the workspace"
  value       = var.databricks_spn_id
}

output "workspace_resource_group" {
  description = "Managed resource group for workspace deployments"
  value       = azurerm_databricks_workspace.this.managed_resource_group_name
}
```

## 📊 Variables Reference

| Variable | Type | Description | Example |
|----------|------|-------------|----------|
| `workspace_name` | string | Name of Databricks workspace | `"dbx-dev"` |
| `location` | string | Azure region | `"North Europe"` |
| `resource_group_name` | string | Resource group name | `"rg-contoso-infra-dev"` |
| `virtual_network_id` | string | Network ID for injection | `"/subscriptions/.../vnets/dev"` |
| `public_subnet_name` | string | Subnet name for public traffic | `"WorkloadSubnet"` |
| `private_subnet_name` | string | Subnet name for private endpoints | `"PrivateEndpointSubnet"` |
| `databricks_spn_id` | string | Service Principal ID | `"12345678-..."` |
| `databricks_spn_secret` | string | Service Principal Secret | `"<Secret>"` |
| `tenant_id` | string | Azure AD Tenant ID | `"12345678-..."` |

## 🎯 Usage Example

```hcl
module "databricks" {
  source = "../../modules/databricks"

  # Environment details
  workspace_name     = "dbx-dev"
  location           = "North Europe"
  resource_group_name = "rg-contoso-infra-dev"

  # Network integration
  virtual_network_id  = module.network.spoke_vnet_ids[var.environment]
  public_subnet_name  = "WorkloadSubnet"
  private_subnet_name = "PrivateEndpointSubnet"

  # Authentication
  databricks_spn_id     = azuread_application.dbx_app.client_id
  databricks_spn_secret = azuread_application_password.dbx_secret.value
  tenant_id             = var.tenant_id
}
```

## 🛠️ Advanced Configurations

### Scaling Analytics

```hcl
# Configure high concurrency clusters
resource "databricks_cluster" "high_concurrency" {
  cluster_name  = "high-concurrency"
  spark_version = "7.3.x-scala2.12"

  node_type_id  = "Standard_DS3_v2"
  num_workers   = 4  # Set for concurrency
  autotermination_minutes = 45

  spark_conf = {
    "spark.databricks.cluster.profile" = "serverless"
  }
}
```

### Automation with Jobs

```hcl
# Automate ETL workflows
resource "databricks_job" "etl_pipeline" {
  name = "ETL-Pipeline"

  existing_cluster_id = databricks_cluster.high_concurrency.id

  notebook_task {
    notebook_path = "/ETL/LoadData"
    base_parameters = {
      "input" = "/mnt/raw/"
    }
  }
}
```

### Data Governance

```hcl
# Centralize logging and monitoring
resource "databricks_cluster_policy" "governance" {
  name = "Enhanced-Governance"

  definition = jsonencode({
    "spark_conf.spark.databricks.delta.properties.defaults.dataSkipping" : "true"
    "aws_attributes.zone_id": {"type": "fixed"}
  })
}
```

## 🔎 Monitoring and Compliance

### Diagnostic Settings

```hcl
# Enable diagnostic logging
resource "azurerm_monitor_diagnostic_setting" "databricks" {
  name                      = "dbx-diagnostics"
  target_resource_id        = azurerm_databricks_workspace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  log {
    category = "WorkspaceEvents"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 90
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 90
    }
  }
}
```

## 🛡️ Security and Best Practices

### Secure Strategy
- **Use SPN for all connections** to ensure secure, automated workflows.
- **Leverage VNet injection** to scope data access.
- **Apply RBAC** to control access based on roles and tasks.

### Compliance Features
- **Encryption** is enabled at rest and in transit.
- **Audit trails** capture all workspace interactions.
- **Isolation** is maintained due to network architecture.

## 🎓 Learning Takeaways

1. **Databricks provides** a comprehensive analytics workspace.
2. **VNet Injection** ensures traffic stays secure within Azure.
3. **Service Principal** provides secure, scalable authentication.
4. **Module outputs** provide key resource information for other modules.
5. **Advanced configurations** allow fine-tuning for performance and security.

## 🔄 Next Steps

- Explore [Storage Module](../storage/README.md) to understand how data flows from storage to Databricks.
- Check [Network Module](../network/README.md) for VNet rules and peering configurations.
- Review [Key Vault Module](../keyvault/README.md) for securing secrets used by Databricks.

This Databricks foundation provides a robust, secure, and scalable analytics environment to unlock insights and drive innovation! 🚀
