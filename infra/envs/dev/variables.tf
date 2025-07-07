# Dev-specific variable defaults
variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "location" {
  description = "Azure region to deploy into"
  type        = string
}

variable "org_prefix" {
  type    = string
  default = "contoso"
}

variable "location_short" {
  type = string
}

variable "resource_group_names" {
  description = "Mapping of environment to resource group names"
  type        = map(string)
}

variable "subscription_id" {
  description = "Azure subscription ID for this environment"
  type        = string
}

# variables.tf
variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "storage_spn_object_id" {
  description = "Azure AD Object ID of the service principal used for storage access"
  type        = string
}

variable "private_endpoint_subnet_ids" {
  description = "Map of environment name → PrivateEndpointSubnet resource ID"
  type        = map(string)
}

variable "domains" {
  description = "List of business domains (e.g. finance, marketing, sales)"
  type        = list(string)
}
