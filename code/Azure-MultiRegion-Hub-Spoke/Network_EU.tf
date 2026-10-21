resource "azurerm_resource_group" "rg_eu" {
  name = var.rg_eu_name
  location = var.location_hub_eu
}

resource "azurerm_virtual_network" "vnet3_hub_eu" {
    name = "vnet-hub-eu"
    location = azurerm_resource_group.rg_eu.location
    resource_group_name = azurerm_resource_group.rg_eu.name
    address_space = var.vnet3_hub_eu_address
}

resource "azurerm_subnet" "vnet3_gw_subnet" {
  name = "GatewaySubnet"
  resource_group_name = azurerm_resource_group.rg_eu.name
  virtual_network_name = azurerm_virtual_network.vnet3_hub_eu.name
  address_prefixes = ["10.3.254.0/24"]
}

resource "azurerm_subnet" "vnet3_shared_subnet" {
  name                 = "subnet-shared-services"
  resource_group_name  = azurerm_resource_group.rg_eu.name
  virtual_network_name = azurerm_virtual_network.vnet3_hub_eu.name
  address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_virtual_network" "vnet4_spoke_eu" {
  name                = "vnet-spoke-eu"
  location            = var.location_spoke_eu 
  resource_group_name = azurerm_resource_group.rg_eu.name
  address_space       = var.vnet4_spoke_eu_address
}

resource "azurerm_subnet" "vnet4_private_subnet" {
  name                 = "subnet-private-outbound"
  resource_group_name  = azurerm_resource_group.rg_eu.name
  virtual_network_name = azurerm_virtual_network.vnet4_spoke_eu.name
  address_prefixes     = ["10.4.1.0/24"]
}

resource "azurerm_virtual_network_peering" "peering_hub_to_spoke_eu" {
    name = "peering-Hub-to-Spoke-EU"
    resource_group_name = azurerm_resource_group.rg_eu.name
    virtual_network_name = azurerm_virtual_network.vnet3_hub_eu.name
    remote_virtual_network_id = azurerm_virtual_network.vnet4_spoke_eu.id
    allow_gateway_transit = true
    allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "peering_spoke_to_hub_eu" {
    name = "peering-Spoke-to-Hub-EU"
    resource_group_name = azurerm_resource_group.rg_eu.name
    virtual_network_name = azurerm_virtual_network.vnet4_spoke_eu.name
    remote_virtual_network_id = azurerm_virtual_network.vnet3_hub_eu.id
    use_remote_gateways = true
    allow_forwarded_traffic = true
    depends_on = [ azurerm_virtual_network_peering.peering_hub_to_spoke_eu ]
}
##########################################################################################################
resource "azurerm_public_ip_prefix" "prefix_eu" {
  name = "pip-prefix-eu"
  resource_group_name = azurerm_resource_group.rg_eu.name
  location = azurerm_resource_group.rg_eu.location
  sku = "Standard"
  prefix_length = 30
}

resource "azurerm_public_ip" "pip_vpngw_eu" {
  name = "pip-vpngw-eu"
  location = azurerm_resource_group.rg_eu.location
  resource_group_name = azurerm_resource_group.rg_eu.name
  allocation_method = "Static"
  sku = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.prefix_eu.id
}

resource "azurerm_virtual_network_gateway" "vpngw_eu" {
  name = "vpngw-hub-eu"
  location = azurerm_resource_group.rg_eu.location
  resource_group_name = azurerm_resource_group.rg_eu.name
  type = "Vpn"
  vpn_type = "RouteBased"
  sku = "VpnGw1"

  ip_configuration {
    name = "vpngw-config-eu"
    subnet_id = azurerm_subnet.vnet3_gw_subnet.id
    public_ip_address_id = azurerm_public_ip.pip_vpngw_eu.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_network_gateway_connection" "conn_eu_to_us" {
  name = "s2s-eu-to-us"
  location = azurerm_resource_group.rg_eu.location
  resource_group_name = azurerm_resource_group.rg_eu.name
  type = "Vnet2Vnet"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpngw_eu.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.vpngw_us.id
  shared_key = "yeurys12345@#$%"
}

resource "azurerm_public_ip" "pip_natgw" {
  name = "pip-natgw-eu"
  location = azurerm_resource_group.rg_eu.location
  resource_group_name = azurerm_resource_group.rg_eu.name
  allocation_method = "Static"
  sku = "Standard"
  public_ip_prefix_id = azurerm_public_ip_prefix.prefix_eu.id
}

resource "azurerm_nat_gateway" "natgw_eu" {
  name = "natgw-spoke-eu"
  location = azurerm_resource_group.rg_eu.location
  resource_group_name = azurerm_resource_group.rg_eu.name
  sku_name = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  nat_gateway_id = azurerm_nat_gateway.natgw_eu.id
  public_ip_address_id = azurerm_public_ip.pip_natgw.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_nat_assoc" {
  subnet_id = azurerm_subnet.vnet4_private_subnet.id
  nat_gateway_id = azurerm_nat_gateway.natgw_eu.id
}

resource "azurerm_network_interface" "nic_eu" {
  name                = "nic-private-eu-01"
  location            = azurerm_resource_group.rg_eu.location
  resource_group_name = azurerm_resource_group.rg_eu.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnet4_private_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm_eu" {
  name                  = "vm-priv-eu-01"
  resource_group_name   = azurerm_resource_group.rg_eu.name
  location              = azurerm_resource_group.rg_eu.location
  size                  = "Standard_B2s"
  admin_username        = "adminuser"
  admin_password        = "P@ssw0rd1234!"
  network_interface_ids = [azurerm_network_interface.nic_eu.id]

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