variable "workspace_name" {
  description = "Name of the Databricks workspace (e.g. dev)"
  type        = string
}

variable "location" {
  description = "Azure region for the workspace"
  type        = string
}

variable "org_prefix" {
  description = "Short org or project prefix"
  type        = string
  default     = "contoso"
}

variable "environment" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
}

variable "location_short" {
  description = "Region code (eun1, use2, etc.)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where to create the workspace"
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the spoke VNet for VNet injection"
  type        = string
}

variable "public_subnet_name" {
  description = "Name of the subnet for cluster traffic (WorkloadSubnet)"
  type        = string
}

variable "private_subnet_name" {
  description = "Name of the subnet for control-plane (PrivateEndpointSubnet)"
  type        = string
}

variable "databricks_spn_id" {
  description = "Client ID of the Service Principal for Terraform → Databricks"
  type        = string
}

variable "databricks_spn_secret" {
  description = "Secret of the Service Principal"
  type      = string
  sensitive = true
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}
