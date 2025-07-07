# Key Vault module input variables
variable "environment" {
  description = "Deployment environment name (dev, qa, prod)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "RG where Key Vault will live"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "kv_name_prefix" {
  description = "Prefix for the Key Vault name"
  type        = string
  default     = "kv-contoso"
}

variable "private_endpoint_subnet_id" {
  description = "The subnet ID in which to place the Key Vault private endpoint"
  type        = string
}