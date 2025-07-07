# Contoso Platform Infrastructure

Welcome to the Contoso Platform Infrastructure repository! This is a comprehensive, enterprise-ready infrastructure-as-code solution built with Terraform. Let me take you on a journey through this sophisticated multi-layered architecture.

## 🎯 What Are We Building?

Imagine you're designing a modern data platform for a global enterprise. You need:
- **Secure networking** with proper isolation
- **Scalable storage** for different business domains
- **Analytics capabilities** with Databricks
- **Secret management** for security
- **Multi-environment support** (dev, qa, prod)

This repository delivers exactly that! Let's explore how...

## 🏗️ Architecture Overview

Our platform follows a **Hub-and-Spoke network topology** with **domain-driven storage** and **enterprise security**:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   DEV SPOKE     │    │   QA SPOKE      │    │   PROD SPOKE    │
│  (10.1.0.0/16)  │    │  (10.2.0.0/16)  │    │  (10.3.0.0/16)  │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Workload    │ │    │ │ Workload    │ │    │ │ Workload    │ │
│ │ Subnet      │ │    │ │ Subnet      │ │    │ │ Subnet      │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Private     │ │    │ │ Private     │ │    │ │ Private     │ │
│ │ Endpoint    │ │    │ │ Endpoint    │ │    │ │ Endpoint    │ │
│ │ Subnet      │ │    │ │ Subnet      │ │    │ │ Subnet      │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │      ┌─────────────────────────────┐         │
          └──────┤        HUB VNET            ├─────────┘
                 │      (10.0.0.0/16)         │
                 │                             │
                 │  ┌─────────────────────┐   │
                 │  │   Azure Firewall    │   │
                 │  │   (10.0.1.0/26)     │   │
                 │  └─────────────────────┘   │
                 │                             │
                 │  ┌─────────────────────┐   │
                 │  │   Gateway Subnet    │   │
                 │  │   (10.0.2.0/27)     │   │
                 │  └─────────────────────┘   │
                 └─────────────────────────────┘
                               │
                               ▼
                          ┌─────────┐
                          │Internet │
                          └─────────┘
```

### 🔄 Data Flow Journey

1. **Traffic enters** through Azure Firewall
2. **Routes to appropriate spoke** (dev/qa/prod)
3. **Workloads process data** in isolated subnets
4. **Private endpoints** secure service access
5. **Storage organized** by business domains
6. **Secrets managed** centrally via Key Vault

## 📁 Repository Structure Deep Dive

```
contoso-platform/
├── infra/                          # Infrastructure root
│   ├── envs/                       # Environment-specific configurations
│   │   ├── dev/                    # Development environment
│   │   │   ├── main.tf            # Environment orchestration
│   │   │   ├── variables.tf       # Environment variables
│   │   │   ├── terraform.tfvars   # Environment values
│   │   │   └── backend.tf         # State management
│   │   ├── qa/                    # Quality Assurance environment
│   │   └── prod/                  # Production environment
│   │
│   └── modules/                    # Reusable infrastructure components
│       ├── network/               # Hub-spoke networking + firewall
│       ├── storage/               # ADLS Gen2 + domain containers
│       ├── keyvault/              # Secret management + private endpoints
│       └── databricks/            # Analytics platform + VNet injection
│
├── README.md                      # This file!
└── LICENSE                        # Project license
```

## 🚀 Getting Started: Your Infrastructure Journey

### Prerequisites (Your Toolkit)

```bash
# 1. Install Terraform
brew install terraform  # macOS
# or download from https://terraform.io

# 2. Install Azure CLI
brew install azure-cli  # macOS
# or download from https://docs.microsoft.com/cli/azure/

# 3. Login to Azure
az login
az account set --subscription "your-subscription-id"
```

### Quick Start (5 Minutes to Infrastructure!)

```bash
# 1. Clone and navigate
git clone <this-repo>
cd contoso-platform/infra/envs/dev

# 2. Initialize Terraform
terraform init

# 3. Plan your infrastructure
terraform plan

# 4. Deploy (when ready)
terraform apply
```

### What Gets Created?

After running `terraform apply`, you'll have:

- ✅ **1 Hub VNet** with Azure Firewall
- ✅ **3 Spoke VNets** (dev, qa, prod)
- ✅ **VNet peering** between hub and spokes
- ✅ **Route tables** forcing traffic through firewall
- ✅ **Storage account** with domain-based containers
- ✅ **Key Vault** with private endpoint
- ✅ **Databricks workspace** with VNet injection
- ✅ **Service principals** for secure authentication

## 🧩 Module Interconnections

This is where the magic happens! Let me show you how modules work together:

### Network Module → Everything Else
```hcl
# Network module creates the foundation
module "network" {
  source = "../../modules/network"
  # ... configuration
}

# Storage module uses network outputs
module "storage" {
  source = "../../modules/storage"
  private_endpoint_subnet_ids = module.network.spoke_private_endpoint_ids
}

# Key Vault module uses network outputs
module "keyvault" {
  source = "../../modules/keyvault"
  private_endpoint_subnet_id = module.network.spoke_private_endpoint_ids[var.environment]
}

# Databricks module uses network outputs
module "databricks" {
  source = "../../modules/databricks"
  virtual_network_id = module.network.spoke_vnet_ids[var.environment]
}
```

### Data Flow Between Modules

1. **Network** provides subnet IDs → **Storage** creates private endpoints
2. **Network** provides VNet IDs → **Databricks** injects into custom networking
3. **Azure AD** creates service principals → **Key Vault** stores secrets
4. **Key Vault** provides secrets → **Databricks** authenticates securely

## 🎓 Learning Path: Understanding Each Component

### For Infrastructure Beginners:
1. Start with `/infra/modules/network/README.md` - Learn networking basics
2. Move to `/infra/modules/storage/README.md` - Understand data storage
3. Continue with `/infra/modules/keyvault/README.md` - Security concepts
4. Finish with `/infra/modules/databricks/README.md` - Analytics platform

### For Terraform Veterans:
1. Check `/infra/envs/dev/README.md` - Environment orchestration
2. Review module interconnections and data flow
3. Explore advanced configurations in each module

## 🔒 Security Features

- **Network isolation** via VNets and subnets
- **Firewall protection** for all outbound traffic
- **Private endpoints** for secure service access
- **RBAC** for fine-grained access control
- **Service principals** for application authentication
- **Key Vault** for centralized secret management

## 🌍 Multi-Environment Strategy

Each environment (dev/qa/prod) has:
- **Isolated infrastructure** - No cross-contamination
- **Shared configuration** - Same modules, different parameters
- **Environment-specific values** - Sizing, naming, access controls

## 🛠️ Advanced Features

- **Provider configuration** for multiple Azure services
- **State management** with remote backends
- **Module versioning** and reusability
- **Automated testing** capabilities
- **CI/CD integration** ready

## 📚 Next Steps

Ready to dive deeper? Visit these detailed guides:

- [Network Module Deep Dive](infra/modules/network/README.md)
- [Storage Architecture Guide](infra/modules/storage/README.md)
- [Security Implementation](infra/modules/keyvault/README.md)
- [Analytics Platform Setup](infra/modules/databricks/README.md)
- [Environment Management](infra/envs/dev/README.md)

## 🤝 Contributing

We welcome contributions! This infrastructure grows with your needs.

## 📄 License

MIT License - Build amazing things! 🚀
