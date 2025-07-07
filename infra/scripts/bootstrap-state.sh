#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bootstrap Contoso Terraform remote state storage
# Run this once before any `terraform init` step.
# -----------------------------------------------------------------------------

set -euo pipefail

echo "Creating RG for Terraform state..."
az group create \
  --name rg-contoso-terraform-state \
  --location westeurope

echo "Creating Storage Account for Terraform state..."
az storage account create \
  --name stcontosotfstate \
  --resource-group rg-contoso-terraform-state \
  --location westeurope \
  --sku Standard_LRS \
  --kind StorageV2

echo "Creating container for Terraform state..."
az storage container create \
  --account-name stcontosotfstate \
  --name tfstate

echo "✅ Bootstrap complete. You can now run terraform init."