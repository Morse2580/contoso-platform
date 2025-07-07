# Network module input variables
variable "environment" {
  description = "One of dev, qa, prod"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "RG where hub & spokes will live"
  type        = string
}

variable "hub_address_space" {
  description = "CIDR for the hub VNet"
  type        = string
}

variable "spoke_address_spaces" {
  description = "Map of env → CIDR for each spoke VNet"
  type        = map(string)
}

variable "hub_subnet_prefixes" {
  type = map(string)
  default = {
    AzureFirewallSubnet = "10.0.1.0/26"
    GatewaySubnet       = "10.0.2.0/27"
  }
}

variable "subnet_prefixes" {
  description = "Map of subnet names → prefix within each VNet"
  type        = map(string)
  default     = {
    WorkloadSubnet        = "24"
    PrivateEndpointSubnet = "27"
    AzureFirewallSubnet   = "26"
    GatewaySubnet         = "27"
  }
}