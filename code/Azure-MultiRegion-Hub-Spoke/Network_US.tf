resource "azurerm_resource_group" "rg_us" {
  name = var.rg_us_name
  location = var.location_hub_us
}

resource "azurerm_virtual_network" "vnet1_hub_us" {
  name = "vnet-hub-us"
  resource_group_name = azurerm_resource_group.rg_us.name
  location = azurerm_resource_group.rg_us.location
  address_space = var.vnet1_hub_us_address 
}

resource "azurerm_subnet" "vnet1_gw_subnet" {
  name = "GatewaySubnet"
  resource_group_name = azurerm_resource_group.rg_us.name
  virtual_network_name = azurerm_virtual_network.vnet1_hub_us.name
  address_prefixes = ["10.1.254.0/24"]
}

resource "azurerm_subnet" "vnet1_fw_subnet" {
  name = "AzureFirewallSubnet"
  resource_group_name = azurerm_resource_group.rg_us.name
  virtual_network_name = azurerm_virtual_network.vnet1_hub_us.name
  address_prefixes = [ "10.1.253.0/24" ]
}
#######################################################################################################################
resource "azurerm_virtual_network" "vnet2_spoke_us" {
    name = "vnet-spoke-us"
    resource_group_name = azurerm_resource_group.rg_us.name
    location = var.location_spoke_us
    address_space = var.vnet2_spoke_us_address
}

resource "azurerm_subnet" "vnet2_web_subnet" {
  name = "subnet-web-backend"
  resource_group_name = azurerm_resource_group.rg_us.name
  virtual_network_name = azurerm_virtual_network.vnet2_spoke_us.name
  address_prefixes = ["10.2.1.0/24"]
}

resource "azurerm_virtual_network_peering" "peering_hub_to_spoke_us" {
  name = "peering-Hub-to-Spoke-US"
  resource_group_name = azurerm_resource_group.rg_us.name
  virtual_network_name = azurerm_virtual_network.vnet1_hub_us.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2_spoke_us.id
  allow_gateway_transit = true
  allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "peering_spoke_to_hub_us" {
  name = "peering-Spoke-to-Hub-US"
  resource_group_name = azurerm_resource_group.rg_us.name
  virtual_network_name = azurerm_virtual_network.vnet2_spoke_us.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1_hub_us.id
  use_remote_gateways = true
  allow_forwarded_traffic = true
  depends_on = [ azurerm_virtual_network_peering.peering_hub_to_spoke_us]
}
#######################################################################################################################
resource "azurerm_public_ip_prefix" "prefix_us" {
  name = "pip-prefix-us"
 location = azurerm_resource_group.rg_us.location
 resource_group_name = azurerm_resource_group.rg_us.name
 prefix_length = 30
 sku = "Standard"
}

resource "azurerm_public_ip" "pip_fw_us" {
  name = "pip-firewall-us"
  location = azurerm_resource_group.rg_us.location
  resource_group_name = azurerm_resource_group.rg_us.name
  allocation_method = "Static"
  sku = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.prefix_us.id
}

resource "azurerm_firewall" "fw_us" {
  name = "fw-hub-us"
  location = azurerm_resource_group.rg_us.location
  resource_group_name = azurerm_resource_group.rg_us.name
  sku_tier = "Standard"
  sku_name = "AZFW_VNet"

  ip_configuration {
    name = "fw-config"
    subnet_id = azurerm_subnet.vnet1_fw_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_fw_us.id
  }
}

resource "azurerm_route_table" "rt_spoke_us" {
  name = "rt-spoke-us"
  location = azurerm_resource_group.rg_us.location
  resource_group_name = azurerm_resource_group.rg_us.name
  bgp_route_propagation_enabled = true

  route {
    name                   = "route-to-eu"
    address_prefix         = "10.3.0.0/16" 
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.fw_us.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "rt_assoc_spoke_us" {
  subnet_id = azurerm_subnet.vnet2_web_subnet.id
  route_table_id = azurerm_route_table.rt_spoke_us.id
}
#######################################################################################################################
resource "azurerm_public_ip" "pip_vpngw_us" {
  name = "pip-vpngw-us"
  location = azurerm_resource_group.rg_us.location
  resource_group_name = azurerm_resource_group.rg_us.name
  allocation_method = "Static"
  sku = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.prefix_us.id
}

resource "azurerm_virtual_network_gateway" "vpngw_us" {
  name = "vpngw-hub-us"
  location = azurerm_resource_group.rg_us.location
  resource_group_name = azurerm_resource_group.rg_us.name
  type = "Vpn"
  vpn_type = "RouteBased"
  sku = "VpnGw1"

  ip_configuration {
    name = "vpngw-config-us"
    subnet_id = azurerm_subnet.vnet1_gw_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_vpngw_us.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_network_gateway_connection" "conn_us_to_eu" {
  name = "s2s-us-to-eu"
  location = azurerm_resource_group.rg_us.location
  resource_group_name = azurerm_resource_group.rg_us.name
  type = "Vnet2Vnet"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpngw_us.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpngw_eu.id
  shared_key = "yeurys12345@#$%"
}
#################################################################################################################
resource "azurerm_public_ip" "pip_lb" {
  name = "pip-lb-us"
  location = azurerm_resource_group.rg_us.location
  resource_group_name = azurerm_resource_group.rg_us.name
  allocation_method = "Static"
  sku = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.prefix_us.id
}

resource "azurerm_lb" "lb_us" {
  name = "lb-public-us"
  location = azurerm_resource_group.rg_us.location
  resource_group_name = azurerm_resource_group.rg_us.name
  sku = "Standard"

  frontend_ip_configuration {
    name = "Public-IP-Frontend"
    public_ip_address_id = azurerm_public_ip.pip_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "pool_us" {
  name = "Backend-Pool-US"
  loadbalancer_id = azurerm_lb.lb_us.id
}

resource "azurerm_network_interface" "nics_us" {
  count               = 2
  name                = "nic-web-us-0${count.index + 1}"
  location            = azurerm_resource_group.rg_us.location
  resource_group_name = azurerm_resource_group.rg_us.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnet2_web_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_to_lb" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.nics_us[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool_us.id
}

resource "azurerm_windows_virtual_machine" "vms_us" {
  count                 = 2
  name                  = "vm-web-us-0${count.index + 1}"
  resource_group_name   = azurerm_resource_group.rg_us.name
  location              = azurerm_resource_group.rg_us.location
  size                  = "Standard_B2s"
  admin_username        = "adminuser"
  admin_password        = "P@ssw0rd1234!" 
  network_interface_ids = [azurerm_network_interface.nics_us[count.index].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}