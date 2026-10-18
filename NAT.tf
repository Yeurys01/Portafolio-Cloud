resource "azurerm_resource_group" "RG" {
    name = "LAB"
    location = "westeurope"
    tags = {
        enviroment = "LAB"
        project = "Nat"
        owner = "Yeurys"
        cost_center = "Yeurys-group"

    }
}

resource "azurerm_virtual_network" "VNET" {
    name = "virtual network 00"
    location = azurerm_resource_group.RG.location
    resource_group_name = azurerm_resource_group.RG.name
    address_space = ["192.168.0.0/16"]
  
}

resource "azurerm_subnet" "SUBNET" {
    name = "subnetA"
    resource_group_name = azurerm_resource_group.RG.name
    virtual_network_name = azurerm_virtual_network.VNET.name
    address_prefixes = ["192.168.20.0/24"]
}

resource "azurerm_network_interface" "NIC" {
    name = "nic01"
    location = azurerm_resource_group.RG.location
    resource_group_name = azurerm_resource_group.RG.name

    ip_configuration {
      name = "internal"
      subnet_id = azurerm_subnet.SUBNET.id
      private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_windows_virtual_machine" "Windows-VM" {
  name = "VM"
  location = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
size = "Standard_D4_v5"
admin_username = "yeurys"
admin_password = "@@wrewr34524fd&%#~&*@"
network_interface_ids = [
    azurerm_network_interface.NIC.id
]

os_disk {
  caching = "ReadWrite"
  storage_account_type = "Standard_LRS"
}

source_image_reference {
  publisher = "MicrosoftWindowsServer"
  offer = "WindowsServer"
  sku = "2022-datacenter"
  version = "latest"
}

}

resource "azurerm_nat_gateway" "NATGW" {
  name = "natgw"
  location = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  sku_name = "Standard"
  idle_timeout_in_minutes = 10
  zones = ["1"]
}

resource "azurerm_public_ip" "PIP" {
    name = "NAT-PIP"
    location = azurerm_resource_group.RG.location
    resource_group_name = azurerm_resource_group.RG.name
    allocation_method = "Static"
    sku = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "AsociacicionNatPIP" {
  nat_gateway_id = azurerm_nat_gateway.NATGW.id
  public_ip_address_id = azurerm_public_ip.PIP.id
}

resource "azurerm_subnet_nat_gateway_association" "AsociacionSubnetNat" {
    nat_gateway_id = azurerm_nat_gateway.NATGW.id
    subnet_id = azurerm_subnet.SUBNET.id
}
