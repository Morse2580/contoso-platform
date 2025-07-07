# Infrastructure: The Heart of Contoso Platform 🏗️

Welcome to the infrastructure directory! This is the **engineering command center** of the Contoso Platform. Here, we orchestrate cloud resources, manage environments, and build the foundation that powers data-driven insights across the organization.

## 🎯 What's Inside This Directory?

This infrastructure setup is designed around **two core principles**:

1. **🧩 Modularity** - Reusable components that can be mixed and matched
2. **🌍 Multi-Environment** - Consistent patterns across dev, qa, and production

```
infra/
├── envs/                    # Environment-specific orchestrations
│   ├── dev/                # Development environment
│   ├── qa/                 # Quality assurance environment
│   └── prod/               # Production environment
├── modules/                # Reusable infrastructure components
│   ├── network/           # Hub-spoke networking + security
│   ├── storage/           # Data lake + domain organization
│   ├── keyvault/          # Secret management + security
│   └── databricks/        # Analytics platform + workspace
└── scripts/               # Automation and utilities
```

## 🎨 Architecture Philosophy

Our infrastructure follows **enterprise-grade design patterns**:

### 1. Hub-and-Spoke Network Topology 🌐

```
                    🌐 Internet
                         │
                ┌─────────────────┐
                │  Azure Firewall │  ← Central security control
                └─────────┬───────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
   ┌─────────┐       ┌─────────┐       ┌─────────┐
   │   DEV   │       │   QA    │       │  PROD   │
   │ Spoke   │       │ Spoke   │       │ Spoke   │
   └─────────┘       └─────────┘       └─────────┘
```

**Benefits:**
- **Centralized security** through Azure Firewall
- **Environment isolation** with separate spokes
- **Scalable architecture** that grows with business needs
- **Cost optimization** through shared hub resources

### 2. Domain-Driven Data Architecture 📊

```
Data Lake Storage (ADLS Gen2)
├── finance/           # Financial data and analytics
├── marketing/         # Customer and campaign data
├── sales/            # Revenue and pipeline data
├── hr/               # People and performance data
└── operations/       # Process and efficiency data
```

**Benefits:**
- **Clear data ownership** by business domain
- **Governance boundaries** for compliance
- **Scalable access control** per domain
- **Independent evolution** of each domain

### 3. Zero-Trust Security Model 🔒

```
Defense Layers:
1. Azure Firewall    → Network perimeter protection
2. Private Endpoints → No public internet exposure
3. Service Principals → Automated, auditable authentication
4. RBAC & Policies   → Fine-grained access control
5. Key Vault         → Centralized secret management
```

## 🧩 Module Deep Dive

Each module is a **self-contained piece** of infrastructure that solves a specific problem:

### Network Module: The Foundation 🌐
```
Purpose: Secure, scalable networking foundation
Creates: Hub VNet, spoke VNets, firewall, route tables
Exports: VNet IDs, subnet IDs, firewall IP
```

**Why this matters:**
- **Security perimeter** for all other resources
- **Traffic inspection** and threat protection
- **Network isolation** between environments
- **Private connectivity** within Azure backbone

### Storage Module: The Data Lake 🗄️
```
Purpose: Scalable, secure data storage
Creates: ADLS Gen2, domain containers, private endpoints
Exports: Storage account details, container information
```

**Why this matters:**
- **Hierarchical namespace** for big data analytics
- **Domain separation** for data governance
- **Private access** through network integration
- **Role-based permissions** per business domain

### Key Vault Module: The Secret Fortress 🔐
```
Purpose: Centralized secret management
Creates: Key Vault, private endpoints, access policies
Exports: Key Vault ID, private endpoint details
```

**Why this matters:**
- **No secrets in code** or configuration files
- **Centralized management** of all credentials
- **Audit trail** for compliance requirements
- **Integration ready** for all applications

### Databricks Module: The Analytics Engine 📊
```
Purpose: Scalable analytics and ML platform
Creates: Databricks workspace, VNet injection, provider config
Exports: Workspace URL, resource IDs
```

**Why this matters:**
- **Collaborative analytics** for data teams
- **Secure network integration** via VNet injection
- **Enterprise features** with premium SKU
- **Automated authentication** via service principals

## 🌍 Environment Strategy

Each environment follows the **same pattern** but with **different scale and security**:

### Development Environment 🛠️
```
Purpose: Rapid iteration and testing
Characteristics:
- Smaller VM sizes for cost optimization
- Relaxed security policies for development velocity
- Shorter secret rotation periods
- Enhanced logging for debugging
```

### QA Environment 🧪
```
Purpose: Production-like testing and validation
Characteristics:
- Production-equivalent sizing
- Production security policies
- Automated testing integration
- Staging data sets
```

### Production Environment 🚀
```
Purpose: Live business operations
Characteristics:
- High availability configurations
- Maximum security settings
- Compliance-ready logging
- Disaster recovery enabled
```

## 📁 Directory Structure Explained

### `/envs/` - Environment Orchestrations

Each environment directory contains:

```
envs/dev/
├── main.tf           # Resource orchestration
├── variables.tf      # Environment-specific variables
├── terraform.tfvars  # Actual values (environment-specific)
├── backend.tf        # State management configuration
└── README.md         # Environment-specific documentation
```

**Pattern Benefits:**
- **Consistent structure** across all environments
- **Environment isolation** through separate state files
- **Easy promotion** from dev → qa → prod
- **Clear variable management** and overrides

### `/modules/` - Reusable Components

Each module follows standard structure:

```
modules/network/
├── main.tf           # Resource definitions
├── variables.tf      # Input parameters
├── outputs.tf        # Exported values
└── README.md         # Module documentation
```

**Module Benefits:**
- **Reusability** across multiple environments
- **Versioning** for stable, predictable deployments
- **Testing** of individual components
- **Documentation** for each component's purpose

## 🚀 Getting Started Guide

### Prerequisites Checklist ✅

```bash
# 1. Install required tools
brew install terraform azure-cli  # macOS
# or use appropriate package manager for your OS

# 2. Authenticate with Azure
az login
az account set --subscription "your-subscription-id"

# 3. Verify permissions
az account show
```

### Initial Deployment Workflow 🎯

```bash
# 1. Start with development environment
cd envs/dev

# 2. Review and customize variables
vim terraform.tfvars

# 3. Initialize Terraform
terraform init

# 4. Plan deployment (review carefully!)
terraform plan -out=dev.tfplan

# 5. Apply changes
terraform apply dev.tfplan
```

### Verification Steps ✅

After deployment, verify everything works:

```bash
# Check network connectivity
az network firewall show --name dev-azurefw --resource-group rg-contoso-infra-dev

# Verify storage account
az storage account show --name stcontosodatadev --resource-group rg-contoso-infra-dev

# Test Key Vault access
az keyvault secret list --vault-name kv-contoso-dev

# Check Databricks workspace
az databricks workspace show --resource-group rg-contoso-infra-dev --name contoso-dev-eun1-ws
```

## 🔄 Deployment Patterns

### Development Workflow 👨‍💻

```bash
# 1. Make changes to modules
cd modules/storage
# ... edit files ...

# 2. Test in development
cd ../../envs/dev
terraform plan
terraform apply

# 3. Promote to QA
cd ../qa
terraform plan
terraform apply

# 4. Deploy to production
cd ../prod
terraform plan
terraform apply
```

### CI/CD Integration 🔄

Recommended pipeline stages:

```yaml
stages:
- validate:    # terraform validate, format check
- plan:        # terraform plan for all environments
- deploy-dev:  # Auto-deploy to development
- deploy-qa:   # Deploy to QA after approval
- deploy-prod: # Deploy to production after approval
```

## 🛡️ Security Best Practices

### Secret Management 🔐

```bash
# ❌ Never do this - secrets in plain text
databricks_secret = "super-secret-password"

# ✅ Do this - secrets from Key Vault
databricks_secret = data.azurerm_key_vault_secret.dbx_secret.value
```

### Network Security 🌐

```bash
# ❌ Never do this - public access
default_action = "Allow"

# ✅ Do this - private access only
default_action = "Deny"
virtual_network_subnet_ids = [var.private_subnet_id]
```

### Identity Security 👤

```bash
# ❌ Never do this - user accounts in automation
# Manual authentication

# ✅ Do this - service principals
azure_client_id     = var.service_principal_id
azure_client_secret = var.service_principal_secret
```

## 📊 Cost Optimization

### Resource Sizing by Environment

| Resource | Development | QA | Production |
|----------|-------------|-------|------------|
| VM Sizes | Standard_D2s_v3 | Standard_D4s_v3 | Standard_D8s_v3 |
| Storage Tier | Standard | Standard | Premium |
| Firewall SKU | Standard | Standard | Premium |
| Databricks | Standard | Premium | Premium |

### Cost Monitoring

```bash
# Set up budget alerts
az consumption budget create \
  --budget-name "dev-monthly-budget" \
  --amount 1000 \
  --resource-group rg-contoso-infra-dev
```

## 🎓 Learning Path

### For Infrastructure Beginners 📚

1. **Start here:** [Network Module](modules/network/README.md)
2. **Then:** [Storage Module](modules/storage/README.md)
3. **Next:** [Key Vault Module](modules/keyvault/README.md)
4. **Finally:** [Databricks Module](modules/databricks/README.md)
5. **Orchestration:** [Dev Environment](envs/dev/README.md)

### For Terraform Veterans 🚀

1. **Module patterns:** Review module structure and outputs
2. **State management:** Check backend configurations
3. **Provider patterns:** Multi-provider setup and dependencies
4. **Environment promotion:** Dev → QA → Prod workflows

## 🔍 Troubleshooting Guide

### Common Issues and Solutions

#### Provider Errors 🔧
```bash
# Problem: Provider not found
Error: Failed to query available provider packages

# Solution: Check required_providers block
terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"  # Correct namespace
    }
  }
}
```

#### Network Connectivity Issues 🌐
```bash
# Problem: Can't reach private endpoints
# Solution: Check DNS resolution
nslookup kv-contoso-dev.vault.azure.net

# Check route tables
az network route-table show --name dev-rt --resource-group rg-contoso-infra-dev
```

#### Permission Errors 👥
```bash
# Problem: Access denied
# Solution: Check service principal roles
az role assignment list --assignee <service-principal-id>

# Add required roles
az role assignment create \
  --assignee <service-principal-id> \
  --role "Key Vault Secrets User" \
  --scope <key-vault-id>
```

## 📈 Scaling and Evolution

### Adding New Environments 🌍

```bash
# 1. Create new environment directory
cp -r envs/dev envs/staging

# 2. Update variables
vim envs/staging/terraform.tfvars

# 3. Update network addresses
spoke_address_spaces = {
  dev     = "10.1.0.0/16"
  qa      = "10.2.0.0/16"
  staging = "10.3.0.0/16"  # New environment
  prod    = "10.4.0.0/16"
}
```

### Adding New Business Domains 📊

```bash
# Update domain list in terraform.tfvars
domains = [
  "finance",
  "marketing", 
  "sales",
  "hr",           # New domain
  "operations",   # New domain
  "legal"         # New domain
]
```

### Module Versioning 🏷️

```bash
# Use specific module versions for production
module "network" {
  source = "git::https://github.com/contoso/terraform-modules.git//network?ref=v1.2.0"
}
```

## 🔄 What's Next?

Ready to dive deeper? Here are your next steps:

1. **🏗️ Deploy Development** - Start with [dev environment](envs/dev/README.md)
2. **🔍 Explore Modules** - Understand each [module's purpose](modules/)
3. **🚀 Scale Up** - Deploy to QA and production environments
4. **📊 Add Monitoring** - Implement Azure Monitor and alerting
5. **🔄 Automate** - Set up CI/CD pipelines for automated deployments

## 🎉 Success Metrics

When everything is working, you'll have:

- ✅ **Secure network foundation** with hub-spoke topology
- ✅ **Scalable data lake** with domain-driven organization
- ✅ **Centralized secret management** via Key Vault
- ✅ **Enterprise analytics platform** with Databricks
- ✅ **Multi-environment deployment** capability
- ✅ **Infrastructure as code** with full automation
- ✅ **Security best practices** implemented throughout

This infrastructure foundation provides the **enterprise-grade capabilities** needed to support data-driven innovation at scale! 🚀

---

*Remember: Infrastructure is not just about technology - it's about enabling your teams to build amazing things. This platform gives you the secure, scalable foundation to innovate with confidence.*
