#!/bin/bash

# This script documents the EXACT process used to create this template
# Run this in a new directory to recreate the template structure

set -e

echo "🚀 Creating Terraform Project Template..."

# Step 1: Create project root structure
echo "📁 Creating root directory structure..."
mkdir -p contoso-platform
cd contoso-platform

# Initialize git repository
git init
echo "Created git repository"

# Create root-level files
touch README.md
touch LICENSE
touch .gitignore

# Add basic gitignore content
cat > .gitignore << 'EOF'
# Terraform files
*.tfstate
*.tfstate.*
*.tfplan
*.tfplan.*
.terraform/
.terraform.lock.hcl

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Environment files
*.tfvars
!terraform.tfvars.example

# Log files
*.log
EOF

# Step 2: Create infrastructure directory structure
echo "🏗️ Creating infrastructure directory structure..."
mkdir -p infra/{modules/{network,storage,keyvault,databricks},envs/{dev,qa,prod},scripts}

# Step 3: Create module files
echo "📦 Creating module files..."

# Network module files
cat > infra/modules/network/main.tf << 'EOF'
# Network module - hub & spoke VNets, firewall, peering resources
EOF

cat > infra/modules/network/variables.tf << 'EOF'
# Network module input variables
EOF

cat > infra/modules/network/outputs.tf << 'EOF'
# Network module output values
EOF

# Storage module files
cat > infra/modules/storage/main.tf << 'EOF'
# Storage module - ADLS Gen2 accounts & containers
EOF

cat > infra/modules/storage/variables.tf << 'EOF'
# Storage module input variables
EOF

cat > infra/modules/storage/outputs.tf << 'EOF'
# Storage module output values
EOF

# Key Vault module files
cat > infra/modules/keyvault/main.tf << 'EOF'
# Key Vault module - Key Vault & secrets
EOF

cat > infra/modules/keyvault/variables.tf << 'EOF'
# Key Vault module input variables
EOF

cat > infra/modules/keyvault/outputs.tf << 'EOF'
# Key Vault module output values
EOF

# Databricks module files
cat > infra/modules/databricks/main.tf << 'EOF'
# Databricks module - Workspace, Metastore, UC objects
EOF

cat > infra/modules/databricks/variables.tf << 'EOF'
# Databricks module input variables
EOF

cat > infra/modules/databricks/outputs.tf << 'EOF'
# Databricks module output values
EOF

# Step 4: Create environment files
echo "🌍 Creating environment files..."

# For each environment (dev, qa, prod)
for env in dev qa prod; do
    cat > infra/envs/$env/backend.tf << EOF
# Remote state settings for $env environment
EOF

    cat > infra/envs/$env/main.tf << EOF
# Module calls for $env infrastructure
EOF

    cat > infra/envs/$env/variables.tf << EOF
# $env-specific variable defaults
EOF

    cat > infra/envs/$env/terraform.tfvars << EOF
# $env environment variable values
EOF
done

# Step 5: Create root-level infrastructure files
echo "📄 Creating root infrastructure files..."

cat > infra/providers.tf << 'EOF'
# Provider definitions (Azure, Databricks)
EOF

cat > infra/variables.tf << 'EOF'
# Global variable definitions
EOF

cat > infra/terraform.tfvars.example << 'EOF'
# Example variable values for dev/qa/prod
EOF

# Step 6: Create scripts
echo "🔧 Creating scripts..."
touch infra/scripts/bootstrap-state.sh
chmod +x infra/scripts/bootstrap-state.sh

# Step 7: Create documentation
echo "📚 Creating documentation..."
cat > README.md << 'EOF'
# Contoso Platform Infrastructure

This repository contains the Terraform infrastructure code for the Contoso Platform.

## Structure

- `infra/modules/` - Reusable Terraform modules
- `infra/envs/` - Environment-specific configurations
- `infra/scripts/` - Helper scripts and automation

## Getting Started

1. Install prerequisites (Terraform, Azure CLI)
2. Authenticate with Azure: `az login`
3. Navigate to desired environment: `cd infra/envs/dev`
4. Initialize Terraform: `terraform init`
5. Plan deployment: `terraform plan`
6. Apply changes: `terraform apply`

## Prerequisites

- Terraform >= 1.0
- Azure CLI >= 2.0
- Active Azure subscription
- Contributor/Owner permissions on subscription
EOF

echo "✅ Template creation complete!"
echo ""
echo "📊 Template Statistics:"
echo "   Directories created: $(find . -type d | wc -l)"
echo "   Files created: $(find . -type f | wc -l)"
echo "   Modules: 4 (network, storage, keyvault, databricks)"
echo "   Environments: 3 (dev, qa, prod)"
echo ""
echo "🎯 Next Steps:"
echo "1. Customize variables in terraform.tfvars.example"
echo "2. Implement module logic in main.tf files"
echo "3. Configure backend for remote state"
echo "4. Set up CI/CD pipeline"
echo "5. Add monitoring and alerting"
