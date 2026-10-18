resource "azurerm_resource_group" "RG01" {
    name = "RGEAST"
    location = "eastus"
tags = {
  enviroment = "Dev"
  project = "WebApp"
  owner = "Developers"
  cost-center = "DevDepartment"
}
}
#####################################################################################################################
resource "azurerm_virtual_network" "vnet01" {
  name = "RED1"
  location = azurerm_resource_group.RG01.location
  resource_group_name = azurerm_resource_group.RG01.name
  address_space = ["192.168.0.0/16"]
}
#####################################################################################################################
resource "azurerm_subnet" "SubNet1" {
    name = "Dev-subnet"
    virtual_network_name = azurerm_virtual_network.vnet01.name
    resource_group_name = azurerm_resource_group.RG01.name
    address_prefixes = ["192.168.10.0/24"]
}
#####################################################################################################################
resource "azurerm_network_interface" "NIC01" {
  name = "nic1"
  location = azurerm_resource_group.RG01.location
  resource_group_name = azurerm_resource_group.RG01.name

  ip_configuration  {
    name = "internal01"
    subnet_id = azurerm_subnet.SubNet1.id
    private_ip_address_allocation = "Dynamic"

  }

}
#####################################################################################################################
resource "azurerm_windows_virtual_machine" "VM01" {
  name = "vm1"
  location = azurerm_resource_group.RG01.location
  resource_group_name = azurerm_resource_group.RG01.name
  size = "Standard_D4_v5" 
  admin_username = "Yeurys1"
  admin_password = "123456@#$%!&(0uwiwiw)"
network_interface_ids = [
  azurerm_network_interface.NIC01.id,
]

os_disk {
  caching = "ReadWrite"
  storage_account_type = "Standard_LRS"
}

source_image_reference {
  publisher = "MicrosoftWindowsServer"
  sku = "2022-DataCenter"
  offer = "WindowsServer"
  version = "latest"
}

}
#####################################################################################################################
resource "azurerm_public_ip" "eastpip" {
  name = "pip01"
  location = azurerm_resource_group.RG01.location
  resource_group_name = azurerm_resource_group.RG01.name
  allocation_method = "Dynamic"
}
#####################################################################################################################
resource "azurerm_subnet" "vpngw01" {
  name = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet01.name
  resource_group_name = azurerm_resource_group.RG01.name
  address_prefixes = ["192.168.15.0/29"]
}

#####################################################################################################################
resource "azurerm_virtual_network_gateway" "VPN-EAST" {
  name = "GatewaySubnet"
  location = azurerm_resource_group.RG01.location
  resource_group_name = azurerm_resource_group.RG01.name

  type = "Vpn"
vpn_type = "RouteBased"
sku = "Basic"

ip_configuration {
  public_ip_address_id = azurerm_public_ip.eastpip.id
  subnet_id = azurerm_subnet.vpngw01.id
  private_ip_address_allocation = "Dynamic"
}

}

#####################################################################################################################
resource "azurerm_virtual_network_gateway_connection" "EAST-WEST" {
  name = "east-west"
  location = azurerm_resource_group.RG01.location
  resource_group_name = azurerm_resource_group.RG01.name

  type = "Vnet2Vnet"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.VPN-EAST.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.VPN-WEST.id
  shared_key = "YEURYS-KEY"
}
#####################################################################################################################












#####################################################################################################################
resource "azurerm_resource_group" "RG02" {
    name = "RGWEST"
    location = "westus"
tags = {
  enviroment = "test"
  project = "WebApp"
  owner = "Testers"
  cost-center = "TestDepartment"
}
}
#####################################################################################################################
resource "azurerm_virtual_network" "vnet02" {
  name = "RED2"
  location = azurerm_resource_group.RG02.location
  resource_group_name = azurerm_resource_group.RG02.name
  address_space = ["192.169.0.0/16"]
}
#####################################################################################################################
resource "azurerm_subnet" "SubNet2" {
    name = "Test-subnet"
    virtual_network_name = azurerm_virtual_network.vnet02.name
    resource_group_name = azurerm_resource_group.RG02.name
    address_prefixes = ["192.169.20.0/24"]
}
#####################################################################################################################
resource "azurerm_network_interface" "NIC02" {
  name = "nic2"
  location = azurerm_resource_group.RG02.location
  resource_group_name = azurerm_resource_group.RG02.name

  ip_configuration  {
    name = "internal02"
    subnet_id = azurerm_subnet.SubNet2.id
    private_ip_address_allocation = "Dynamic"

  }

}
#####################################################################################################################
resource "azurerm_windows_virtual_machine" "VM02" {
  name = "vm2"
  location = azurerm_resource_group.RG02.location
  resource_group_name = azurerm_resource_group.RG02.name
  size = "Standard_D4_v5" 
  admin_username = "Yeurys"
  admin_password = "123456@#$%^&*&^%^&*Q()"
network_interface_ids = [
  azurerm_network_interface.NIC02.id,
]

os_disk {
  caching = "ReadWrite"
  storage_account_type = "Standard_LRS"
}

source_image_reference {
  publisher = "MicrosoftWindowsServer"
  sku = "2022-DataCenter"
  offer = "WindowsServer"
  version = "latest"
}

}
#####################################################################################################################
resource "azurerm_public_ip" "westpip" {
  name = "pip02"
  location = azurerm_resource_group.RG02.location
  resource_group_name = azurerm_resource_group.RG02.name
  allocation_method = "Dynamic"
}
#####################################################################################################################
resource "azurerm_subnet" "vpngw02" {
  name = "GatewaySubnet"
  virtual_network_name = azurerm_virtual_network.vnet02.name
  resource_group_name = azurerm_resource_group.RG02.name
  address_prefixes = ["192.169.25.0/29"]
}

#####################################################################################################################
resource "azurerm_virtual_network_gateway" "VPN-WEST" {
  name = "west2east"
  location = azurerm_resource_group.RG02.location
  resource_group_name = azurerm_resource_group.RG02.name

  type = "Vpn"
vpn_type = "RouteBased"
sku = "Basic"

ip_configuration {
  public_ip_address_id = azurerm_public_ip.westpip.id
  subnet_id = azurerm_subnet.vpngw02.id
  private_ip_address_allocation = "Dynamic"
}

}
#####################################################################################################################
resource "azurerm_virtual_network_gateway_connection" "WEST-EAST" {
  name = "west-east"
  location = azurerm_resource_group.RG02.location
  resource_group_name = azurerm_resource_group.RG02.name

  type = "Vnet2Vnet"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.VPN-WEST.id
  peer_virtual_network_gateway_id = azurerm_virtual_network_gateway.VPN-EAST.id
  shared_key = "YEURYS-KEY"
}
#####################################################################################################################
