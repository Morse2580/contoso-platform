# Network module - hub & spoke VNets, firewall, peering resources
# Hub VNet
resource "azurerm_virtual_network" "hub" {
  name                = "${var.environment}-hub-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.hub_address_space]
}

# Subnets in Hub (Firewall & Gateway)
resource "azurerm_subnet" "hub_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnet_prefixes.AzureFirewallSubnet]
}

resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_subnet_prefixes.GatewaySubnet]
}

# Azure Firewall in Hub
resource "azurerm_public_ip" "fw_pip" {
  name                = "${var.environment}-fw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "fw" {
  name                = "${var.environment}-azurefw"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "fw-config"
    subnet_id            = azurerm_subnet.hub_firewall.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}

# Spoke VNets and Subnets
resource "azurerm_virtual_network" "spoke" {
  for_each            = var.spoke_address_spaces
  name                = "${var.environment}-${each.key}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [each.value]
}

resource "azurerm_subnet" "spoke_workload" {
  for_each            = azurerm_virtual_network.spoke
  name                = "WorkloadSubnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = each.value.name

  # carve out the second /24 from the /16 VNet
  address_prefixes = [
    cidrsubnet(
      tolist(each.value.address_space)[0],
      8,
      1
    )
  ]
}

resource "azurerm_subnet" "spoke_private_endpoint" {
  for_each            = azurerm_virtual_network.spoke
  name                = "PrivateEndpointSubnet"
  resource_group_name = var.resource_group_name
  virtual_network_name = each.value.name
  # Allow Storage service endpoint on this subnet
  service_endpoints = ["Microsoft.Storage"]

  # carve out the third /27 from the /16 VNet
  address_prefixes = [
    cidrsubnet(
      tolist(each.value.address_space)[0],
      11,
      2
    )
  ]
}

# VNet Peerings (Spoke → Hub and Hub → Spoke)
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                    = azurerm_virtual_network.spoke
  name                        = "${each.key}-to-hub"
  resource_group_name         = var.resource_group_name
  virtual_network_name        = each.value.name
  remote_virtual_network_id   = azurerm_virtual_network.hub.id
  allow_forwarded_traffic     = true
  allow_gateway_transit       = false
  use_remote_gateways         = false
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                    = azurerm_virtual_network.spoke
  name                        = "hub-to-${each.key}"
  resource_group_name         = var.resource_group_name
  virtual_network_name        = azurerm_virtual_network.hub.name
  remote_virtual_network_id   = each.value.id
  allow_forwarded_traffic     = true
  allow_gateway_transit       = false
  use_remote_gateways         = false
}

# Route table to force-tunnel spoke outbound via firewall
resource "azurerm_route_table" "spoke_rt" {
  for_each            = azurerm_virtual_network.spoke
  name                = "${each.key}-rt"
  resource_group_name = var.resource_group_name
  location            = var.location
  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "assoc" {
  for_each            = azurerm_subnet.spoke_workload
  subnet_id           = each.value.id
  route_table_id      = azurerm_route_table.spoke_rt[each.key].id
}
