variable "environment" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create storage in"
  type        = string
}

variable "storage_account_name_prefix" {
  description = "Prefix for naming the storage account"
  type        = string
  default     = "stcontosodata"
}

variable "domains" {
  description = "List of business domains (e.g. finance, marketing, sales)"
  type        = list(string)
}

variable "private_endpoint_subnet_ids" {
  description = "Map of environment → PrivateEndpointSubnet ID from the network module"
  type        = map(string)
}

variable "storage_spn_object_id" {
  description = "Azure AD Object ID of the SPN to grant Blob Data Contributor"
  type        = string
}
