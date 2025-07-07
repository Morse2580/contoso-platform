# Network module output values
output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "spoke_vnet_ids" {
  value = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}

output "firewall_public_ip" {
  value = azurerm_public_ip.fw_pip.ip_address
}

output "spoke_private_endpoint_ids" {
  description = "Map of environment → PrivateEndpointSubnet ID for each spoke"
  value       = {
    for env, vnet in azurerm_virtual_network.spoke :
    env => azurerm_subnet.spoke_private_endpoint[env].id
  }
}
