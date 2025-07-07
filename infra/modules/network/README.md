# Network Module: The Foundation of Enterprise Networking 🌐

Welcome to the Network module\! This is where we build the **backbone** of our entire infrastructure. Think of it as the **highway system** for your cloud environment—everything else depends on it working correctly.

## 🎯 What Does This Module Do?

This module creates a **Hub-and-Spoke network topology**, which is the gold standard for enterprise Azure networking. Here's what it accomplishes:

1.  **🏢 Central Hub**: A central Virtual Network (VNet) that acts as a single point of connectivity.
2.  **🌟 Multiple Spokes**: Environment-specific VNets (e.g., dev, qa, prod) isolated from one another.
3.  **🔥 Centralized Security**: An Azure Firewall to inspect all inbound and outbound traffic.
4.  **🚦 Traffic Control**: Route tables to direct data flow precisely.
5.  **🔗 Secure Connectivity**: VNet peering to link the hub and spokes securely.

-----

## 🏗️ Architecture Deep Dive

```
               Internet
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│              HUB VNET (10.0.0.0/16)             │
│                                                 │
│ ┌──────────────────┐      ┌───────────────────┐ │
│ │  Azure Firewall  │      │   Gateway Subnet  │ │
│ │ (10.0.1.0/26)    │      │  (10.0.2.0/27)    │ │
│ │ ┌──────────────┐ │      │ ┌───────────────┐ │ │
│ │ │  Public IP   │ │      │ │  VPN Gateway  │ │ │
│ │ └──────────────┘ │      │ │   (Optional)  │ │ │
│ └──────────────────┘      └───────────────────┘ │
└─────────┬───────────────────┬─────────────────┘
          │                   │
  ┌───────┴────────┐ ┌────────┴────────┐
  │ VNet Peering   │ │ VNet Peering    │
  ▼                ▼ ▼                 ▼
┌─────────────┐  ┌─────────────┐   ┌─────────────┐
│  DEV SPOKE  │  │   QA SPOKE  │   │  PROD SPOKE │
│ 10.1.0.0/16 │  │ 10.2.0.0/16 │   │ 10.3.0.0/16 │
└─────────────┘  └─────────────┘   └─────────────┘
```

-----

## 🧩 Resource Breakdown

Let's walk through each resource and understand **why** it exists.

### 1\. Hub Virtual Network 🏢

Acts as the **central connection point** for all environments. It houses shared services like the firewall and VPN gateway, enabling centralized security and simplified routing.

```hcl
resource "azurerm_virtual_network" "hub" {
  name                = "${var.environment}-hub-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [var.hub_address_space] # e.g., "10.0.0.0/16"
}
```

### 2\. Hub Subnets 🔧

#### Azure Firewall Subnet

This subnet is dedicated exclusively to the Azure Firewall.

  - **Required Name**: Azure demands the name be exactly `AzureFirewallSubnet`.
  - **Sizing**: A `/26` provides 64 IP addresses, which is the recommended minimum size.

<!-- end list -->

```hcl
resource "azurerm_subnet" "hub_firewall" {
  name                 = "AzureFirewallSubnet" # This name is mandatory!
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/26"]
}
```

#### Gateway Subnet

This subnet is reserved for a VPN or ExpressRoute Gateway to enable hybrid connectivity with on-premises networks.

  - **Required Name**: Must be named `GatewaySubnet`.

<!-- end list -->

```hcl
resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet" # This name is mandatory!
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/27"]
}
```

### 3\. Azure Firewall 🔥

The firewall provides **centralized threat protection** by inspecting all traffic between spokes and the internet.

```hcl
# Public IP for the firewall
resource "azurerm_public_ip" "fw_pip" {
  name                = "${var.environment}-fw-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# The firewall resource
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
```

### 4\. Spoke Virtual Networks 🌟

These are the isolated networks for each environment (dev, qa, prod). We use a `for_each` loop to create them dynamically.

```hcl
resource "azurerm_virtual_network" "spoke" {
  for_each            = var.spoke_address_spaces # Creates one per key in the map
  name                = "${var.environment}-${each.key}-vnet"
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = [each.value] # e.g., "10.1.0.0/16" for dev
}
```

This is driven by a variable map:

```hcl
spoke_address_spaces = {
  dev  = "10.1.0.0/16"
  qa   = "10.2.0.0/16"
  prod = "10.3.0.0/16"
}
```

### 5\. Spoke Subnets 🏠

We use the `cidrsubnet` function to programmatically carve out subnets from each spoke's address space.

#### Workload Subnet

This is where your applications and virtual machines will live.

  - **Calculation**: `cidrsubnet("10.1.0.0/16", 8, 1)` takes the `/16` network, adds `8` bits to create `/24` subnets, and selects the second one (index `1`).
  - **Result**: `10.1.1.0/24`

<!-- end list -->

```hcl
resource "azurerm_subnet" "spoke_workload" {
  for_each             = azurerm_virtual_network.spoke
  name                 = "WorkloadSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(tolist(each.value.address_space)[0], 8, 1)]
}
```

#### Private Endpoint Subnet

A small, dedicated subnet for placing private endpoints, which provide secure access to PaaS services like Azure Storage and Key Vault.

  - **Calculation**: `cidrsubnet("10.1.0.0/16", 11, 2)` creates `/27` subnets (32 IPs) and selects the third one (index `2`).
  - **Result**: `10.1.0.64/27`

<!-- end list -->

```hcl
resource "azurerm_subnet" "spoke_private_endpoint" {
  for_each             = azurerm_virtual_network.spoke
  name                 = "PrivateEndpointSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = each.value.name
  address_prefixes     = [cidrsubnet(tolist(each.value.address_space)[0], 11, 2)]
}
```

### 6\. VNet Peering (The Highway System) 🛣️

Peering creates a direct, private connection between the hub and each spoke. A peering must be configured in both directions.

```hcl
# Spoke to Hub Connection
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                    = azurerm_virtual_network.spoke
  name                        = "${each.key}-to-hub"
  resource_group_name         = var.resource_group_name
  virtual_network_name        = each.value.name
  remote_virtual_network_id   = azurerm_virtual_network.hub.id
  allow_forwarded_traffic     = true # Critical for allowing the firewall to route traffic
}

# Hub to Spoke Connection
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                    = azurerm_virtual_network.spoke
  name                        = "hub-to-${each.key}"
  resource_group_name         = var.resource_group_name
  virtual_network_name        = azurerm_virtual_network.hub.name
  remote_virtual_network_id   = each.value.id
  allow_forwarded_traffic     = true
}
```

### 7\. Route Table (The Traffic Director) 🚦

This forces all outbound traffic from the spokes to go through the central Azure Firewall for inspection.

```hcl
resource "azurerm_route_table" "spoke_rt" {
  for_each            = azurerm_virtual_network.spoke
  name                = "${each.key}-rt"
  resource_group_name = var.resource_group_name
  location            = var.location

  # Default route to force ALL internet-bound traffic through the firewall
  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
}

# Associate the route table with each workload subnet
resource "azurerm_subnet_route_table_association" "workload_assoc" {
  for_each       = azurerm_subnet.spoke_workload
  subnet_id      = each.value.id
  route_table_id = azurerm_route_table.spoke_rt[each.key].id
}
```

-----

## 📤 Module Outputs

These outputs expose important resource IDs and IPs for other modules to use.

```hcl
output "hub_vnet_id" {
  description = "The resource ID of the Hub VNet."
  value       = azurerm_virtual_network.hub.id
}

output "spoke_vnet_ids" {
  description = "A map of environment names to Spoke VNet resource IDs."
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}

output "spoke_private_endpoint_subnet_ids" {
  description = "A map of environment names to Private Endpoint Subnet resource IDs."
  value       = { for k, v in azurerm_subnet.spoke_private_endpoint : k => v.id }
}

output "firewall_public_ip" {
  description = "The public IP address of the Azure Firewall."
  value       = azurerm_public_ip.fw_pip.ip_address
}
```

-----

## 🎓 Learning Takeaways

1.  **Hub-and-Spoke**: Provides centralized security and simplified management.
2.  **VNet Peering**: Enables secure, low-latency connectivity between networks.
3.  **Route Tables**: Give you granular control over traffic flow.
4.  **`for_each`**: Enables dynamic, scalable, and reusable resource creation.
5.  **`cidrsubnet`**: Automates IP address planning and avoids manual calculation errors.
6.  **Module Outputs**: Create clean contracts between different parts of your infrastructure.
