# Network Module: The Foundation of Enterprise Networking 🌐

Welcome to the Network module! This is where we build the **backbone** of our entire infrastructure. Think of this as the **highway system** for your cloud environment - everything else depends on it working correctly.

## 🎯 What Does This Module Do?

This module creates a **Hub-and-Spoke network topology** that's considered the gold standard for enterprise Azure networking. Here's what it accomplishes:

1. **🏢 Central Hub** - A central VNet that acts as a connection point
2. **🌟 Multiple Spokes** - Environment-specific VNets (dev, qa, prod)
3. **🔥 Centralized Security** - Azure Firewall for traffic inspection
4. **🚦 Traffic Control** - Route tables to manage data flow
5. **🔗 Secure Connectivity** - VNet peering for inter-network communication

## 🏗️ Architecture Deep Dive

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────┐
│             HUB VNET (10.0.0.0/16)             │
│                                                 │
│  ┌──────────────────┐   ┌─────────────────────┐ │
│  │  Azure Firewall  │   │   Gateway Subnet    │ │
│  │  (10.0.1.0/26)   │   │   (10.0.2.0/27)    │ │
│  │                  │   │                     │ │
│  │ ┌──────────────┐ │   │ ┌─────────────────┐ │ │
│  │ │ Public IP    │ │   │ │ VPN Gateway     │ │ │
│  │ │ (External)   │ │   │ │ (Future)        │ │ │
│  │ └──────────────┘ │   │ └─────────────────┘ │ │
│  └──────────────────┘   └─────────────────────┘ │
└─────────────────┬─────────────────┬─────────────┘
                  │                 │
        ┌─────────┼─────────────────┼─────────┐
        │         │                 │         │
        ▼         ▼                 ▼         ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│ DEV SPOKE   │ │  QA SPOKE   │ │ PROD SPOKE  │
│10.1.0.0/16  │ │10.2.0.0/16  │ │10.3.0.0/16  │
│             │ │             │ │             │
│ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │
│ │Workload │ │ │ │Workload │ │ │ │Workload │ │
│ │Subnet   │ │ │ │Subnet   │ │ │ │Subnet   │ │
│ │.1.0/24  │ │ │ │.1.0/24  │ │ │ │.1.0/24  │ │
│ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │
│             │ │             │ │             │
│ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │
│ │Private  │ │ │ │Private  │ │ │ │Private  │ │
│ │Endpoint │ │ │ │Endpoint │ │ │ │Endpoint │ │
│ │Subnet   │ │ │ │Subnet   │ │ │ │Subnet   │ │
│ │.0.64/27 │ │ │ │.0.64/27 │ │ │ │.0.64/27 │ │
│ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │
└─────────────┘ └─────────────┘ └─────────────┘
```

## 🧩 Resource Breakdown

Let's walk through each resource and understand **why** it exists:

### 1. Hub Virtual Network 🏢

```hcl
resource \"azurerm_virtual_network\" \"hub\" {\n  name                = \"${var.environment}-hub-vnet\"\n  resource_group_name = var.resource_group_name\n  location            = var.location\n  address_space       = [var.hub_address_space]  # Usually 10.0.0.0/16\n}
```

**Why do we need this?**\n- Acts as the **central connection point** for all environments\n- Houses **shared services** like firewall and VPN gateway\n- Enables **centralized security** and **monitoring**\n- **Simplifies routing** - one place to manage traffic rules

### 2. Hub Subnets 🔧

#### Azure Firewall Subnet
```hcl
resource \"azurerm_subnet\" \"hub_firewall\" {\n  name                 = \"AzureFirewallSubnet\"  # Name MUST be exact!\n  resource_group_name  = var.resource_group_name\n  virtual_network_name = azurerm_virtual_network.hub.name\n  address_prefixes     = [\"10.0.1.0/26\"]  # 64 IP addresses\n}
```

**Key Points:**\n- **Name is mandatory** - Azure requires exactly \"AzureFirewallSubnet\"\n- **Size matters** - /26 gives us 64 IPs (Azure reserves some)\n- **Dedicated purpose** - Only Azure Firewall can live here

#### Gateway Subnet
```hcl
resource \"azurerm_subnet\" \"hub_gateway\" {\n  name                 = \"GatewaySubnet\"  # Name MUST be exact!\n  resource_group_name  = var.resource_group_name\n  virtual_network_name = azurerm_virtual_network.hub.name\n  address_prefixes     = [\"10.0.2.0/27\"]  # 32 IP addresses\n}
```

**Future-proofing:**\n- **Reserved for VPN Gateway** (not implemented yet)\n- **Enables hybrid connectivity** to on-premises\n- **Name is mandatory** - Azure requirement

### 3. Azure Firewall 🔥

```hcl\n# Public IP for the firewall\nresource \"azurerm_public_ip\" \"fw_pip\" {\n  name                = \"${var.environment}-fw-pip\"\n  resource_group_name = var.resource_group_name\n  location            = var.location\n  allocation_method   = \"Static\"    # Must be static for firewall\n  sku                 = \"Standard\"  # Must be standard for firewall\n}\n\n# The firewall itself\nresource \"azurerm_firewall\" \"fw\" {\n  name                = \"${var.environment}-azurefw\"\n  resource_group_name = var.resource_group_name\n  location            = var.location\n  sku_name            = \"AZFW_VNet\"   # VNet-integrated firewall\n  sku_tier            = \"Standard\"   # Basic tier for this demo\n\n  ip_configuration {\n    name                 = \"fw-config\"\n    subnet_id            = azurerm_subnet.hub_firewall.id\n    public_ip_address_id = azurerm_public_ip.fw_pip.id\n  }\n}
```

**Security Benefits:**\n- **Centralized inspection** of all traffic\n- **Threat protection** with built-in intelligence\n- **Application rules** for fine-grained control\n- **Network rules** for port/protocol filtering\n- **Logging and monitoring** for compliance

### 4. Spoke Virtual Networks 🌟

```hcl
resource \"azurerm_virtual_network\" \"spoke\" {\n  for_each            = var.spoke_address_spaces  # Creates one per environment\n  name                = \"${var.environment}-${each.key}-vnet\"\n  resource_group_name = var.resource_group_name\n  location            = var.location\n  address_space       = [each.value]  # e.g., 10.1.0.0/16 for dev\n}
```

**The Magic of `for_each`:**\n- **Dynamic creation** based on input map\n- **Each environment** gets its own isolated network\n- **Scalable pattern** - add new environments by updating variables\n\n**Input looks like:**\n```hcl\nspoke_address_spaces = {\n  dev  = \"10.1.0.0/16\"  # 65,536 IP addresses\n  qa   = \"10.2.0.0/16\"  # 65,536 IP addresses  \n  prod = \"10.3.0.0/16\"  # 65,536 IP addresses\n}\n```

### 5. Spoke Subnets 🏠

#### Workload Subnet (The Main Stage)\n```hcl\nresource \"azurerm_subnet\" \"spoke_workload\" {\n  for_each            = azurerm_virtual_network.spoke\n  name                = \"WorkloadSubnet\"\n  resource_group_name = var.resource_group_name\n  virtual_network_name = each.value.name\n\n  # CIDR magic: carve out the second /24 from the /16 VNet\n  address_prefixes = [\n    cidrsubnet(\n      tolist(each.value.address_space)[0],  # Get the VNet CIDR\n      8,                                    # Extend mask by 8 bits (/16 → /24)\n      1                                     # Take the 2nd subnet (index 1)\n    )\n  ]\n}\n```\n\n**CIDR Subnet Calculation Explained:**\n- **VNet**: `10.1.0.0/16` (65,536 IPs)\n- **cidrsubnet()** splits this into smaller chunks\n- **Parameters**: (network, newbits, netnum)\n  - `network`: `10.1.0.0/16`\n  - `newbits`: `8` (makes it /24 instead of /16)\n  - `netnum`: `1` (gives us the 2nd chunk)\n- **Result**: `10.1.1.0/24` (256 IPs)\n\n**Visual breakdown:**\n```\n10.1.0.0/16 split into /24 subnets:\n├── 10.1.0.0/24   (netnum=0) - Reserved\n├── 10.1.1.0/24   (netnum=1) - WorkloadSubnet ← We use this\n├── 10.1.2.0/24   (netnum=2) - Available\n└── ... (254 more subnets)\n```\n\n#### Private Endpoint Subnet (The Security Zone)\n```hcl\nresource \"azurerm_subnet\" \"spoke_private_endpoint\" {\n  for_each            = azurerm_virtual_network.spoke\n  name                = \"PrivateEndpointSubnet\"\n  resource_group_name = var.resource_group_name\n  virtual_network_name = each.value.name\n  service_endpoints   = [\"Microsoft.Storage\"]  # Enable storage service endpoint\n\n  # CIDR magic: carve out a /27 subnet (32 IPs)\n  address_prefixes = [\n    cidrsubnet(\n      tolist(each.value.address_space)[0],  # Get the VNet CIDR\n      11,                                   # Extend mask by 11 bits (/16 → /27)\n      2                                     # Take the 3rd subnet (index 2)\n    )\n  ]\n}\n```\n\n**Why /27 for Private Endpoints?**\n- **Small subnet** (32 IPs) is perfect for private endpoints\n- **Each private endpoint** uses only 1 IP\n- **Saves address space** for other uses\n- **Security isolation** from workload subnet\n\n**Result**: `10.1.0.64/27` (32 IPs from 10.1.0.64 to 10.1.0.95)\n\n### 6. VNet Peering (The Highway System) 🛣️\n\n#### Spoke to Hub Connection\n```hcl\nresource \"azurerm_virtual_network_peering\" \"spoke_to_hub\" {\n  for_each                  = azurerm_virtual_network.spoke\n  name                      = \"${each.key}-to-hub\"\n  resource_group_name       = var.resource_group_name\n  virtual_network_name      = each.value.name\n  remote_virtual_network_id = azurerm_virtual_network.hub.id\n  \n  # Security settings\n  allow_forwarded_traffic   = true   # Allow firewall to route traffic\n  allow_gateway_transit     = false  # Hub doesn't provide gateway yet\n  use_remote_gateways       = false  # Spoke doesn't use hub gateway yet\n}\n```\n\n#### Hub to Spoke Connection\n```hcl\nresource \"azurerm_virtual_network_peering\" \"hub_to_spoke\" {\n  for_each                  = azurerm_virtual_network.spoke\n  name                      = \"hub-to-${each.key}\"\n  resource_group_name       = var.resource_group_name\n  virtual_network_name      = azurerm_virtual_network.hub.name\n  remote_virtual_network_id = each.value.id\n  \n  # Matching settings for bidirectional connectivity\n  allow_forwarded_traffic   = true\n  allow_gateway_transit     = false\n  use_remote_gateways       = false\n}\n```\n\n**Peering Properties Explained:**\n- **`allow_forwarded_traffic`**: Lets firewall route between spokes\n- **`allow_gateway_transit`**: Would let hub share VPN gateway\n- **`use_remote_gateways`**: Would let spoke use hub's gateway\n\n### 7. Route Tables (Traffic Director) 🚦\n\n```hcl\nresource \"azurerm_route_table\" \"spoke_rt\" {\n  for_each            = azurerm_virtual_network.spoke\n  name                = \"${each.key}-rt\"\n  resource_group_name = var.resource_group_name\n  location            = var.location\n  \n  # Force ALL internet traffic through the firewall\n  route {\n    name                   = \"default-route\"\n    address_prefix         = \"0.0.0.0/0\"         # All destinations\n    next_hop_type          = \"VirtualAppliance\"   # Custom routing device\n    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address\n  }\n}\n\n# Associate route table with workload subnets\nresource \"azurerm_subnet_route_table_association\" \"assoc\" {\n  for_each       = azurerm_subnet.spoke_workload\n  subnet_id      = each.value.id\n  route_table_id = azurerm_route_table.spoke_rt[each.key].id\n}\n```\n\n**Why Force Traffic Through Firewall?**\n- **Security inspection** of all outbound traffic\n- **Threat protection** against malicious sites\n- **Compliance logging** for audit requirements\n- **Centralized control** over internet access\n\n## 📤 Module Outputs (The API)\n\nThis module provides crucial information that other modules need:\n\n```hcl\n# Hub VNet ID for reference\noutput \"hub_vnet_id\" {\n  value = azurerm_virtual_network.hub.id\n}\n\n# Map of environment → spoke VNet ID\noutput \"spoke_vnet_ids\" {\n  value = { for k, v in azurerm_virtual_network.spoke : k => v.id }\n}\n\n# Firewall's public IP for DNS/monitoring\noutput \"firewall_public_ip\" {\n  value = azurerm_public_ip.fw_pip.ip_address\n}\n\n# Map of environment → private endpoint subnet ID\noutput \"spoke_private_endpoint_ids\" {\n  description = \"Map of environment → PrivateEndpointSubnet ID for each spoke\"\n  value       = {\n    for env, vnet in azurerm_virtual_network.spoke :\n    env => azurerm_subnet.spoke_private_endpoint[env].id\n  }\n}\n```\n\n## 🔗 How Other Modules Use This\n\n### Storage Module Connection\n```hcl\nmodule \"storage\" {\n  source = \"../../modules/storage\"\n  \n  # Uses our private endpoint subnets for secure access\n  private_endpoint_subnet_ids = module.network.spoke_private_endpoint_ids\n}\n```\n\n### Databricks Module Connection\n```hcl\nmodule \"databricks\" {\n  source = \"../../modules/databricks\"\n  \n  # Injects into our spoke VNet for custom networking\n  virtual_network_id  = module.network.spoke_vnet_ids[var.environment]\n  public_subnet_name  = \"WorkloadSubnet\"        # Our workload subnet\n  private_subnet_name = \"PrivateEndpointSubnet\"  # Our private endpoint subnet\n}\n```\n\n### Key Vault Module Connection\n```hcl\nmodule \"keyvault\" {\n  source = \"../../modules/keyvault\"\n  \n  # Uses our private endpoint subnet for secure access\n  private_endpoint_subnet_id = module.network.spoke_private_endpoint_ids[var.environment]\n}\n```\n\n## 📊 Variables Reference\n\n| Variable | Type | Description | Example |\n|----------|------|-------------|----------|\n| `environment` | string | Environment name | `\"dev\"` |\n| `location` | string | Azure region | `\"North Europe\"` |\n| `resource_group_name` | string | Resource group | `\"rg-contoso-infra-dev\"` |\n| `hub_address_space` | string | Hub VNet CIDR | `\"10.0.0.0/16\"` |\n| `spoke_address_spaces` | map(string) | Spoke VNet CIDRs | `{dev=\"10.1.0.0/16\", qa=\"10.2.0.0/16\"}` |\n\n## 🎯 Usage Example\n\n```hcl\nmodule \"network\" {\n  source = \"../../modules/network\"\n  \n  environment         = \"dev\"\n  location           = \"North Europe\"\n  resource_group_name = \"rg-contoso-infra-dev\"\n  hub_address_space  = \"10.0.0.0/16\"\n  \n  spoke_address_spaces = {\n    dev  = \"10.1.0.0/16\"\n    qa   = \"10.2.0.0/16\"\n    prod = \"10.3.0.0/16\"\n  }\n}\n```\n\n## 🔧 Advanced Customization\n\n### Custom Subnet Sizes\nYou can modify the `hub_subnet_prefixes` variable to customize subnet sizes:\n\n```hcl\nhub_subnet_prefixes = {\n  AzureFirewallSubnet = \"10.0.1.0/24\"  # Larger firewall subnet\n  GatewaySubnet       = \"10.0.2.0/26\"  # Smaller gateway subnet\n}\n```\n\n### Additional Spoke Environments\nAdd new environments by updating the spoke address spaces:\n\n```hcl\nspoke_address_spaces = {\n  dev     = \"10.1.0.0/16\"\n  qa      = \"10.2.0.0/16\"\n  staging = \"10.3.0.0/16\"  # New environment!\n  prod    = \"10.4.0.0/16\"\n}\n```\n\n## 🎓 Learning Takeaways\n\n1. **Hub-and-Spoke** provides centralized security and simplified management\n2. **VNet Peering** enables secure, low-latency connectivity\n3. **Route Tables** give you control over traffic flow\n4. **CIDR functions** automate subnet calculation\n5. **for_each** enables dynamic, scalable resource creation\n6. **Module outputs** create clean APIs between components\n\n## 🔄 Next Steps\n\n- Explore [Storage Module](../storage/README.md) to see how it uses these networks\n- Check [Key Vault Module](../keyvault/README.md) for private endpoint implementation\n- Review [Databricks Module](../databricks/README.md) for VNet injection patterns\n\nThis network foundation makes everything else possible! 🚀
