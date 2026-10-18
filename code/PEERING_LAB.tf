


resource "azurerm_resource_group" "RG1" {
name = "rg1-lab-webapp-westus"
location = "westus"
tags = {
  enviroment = "lab"
  project = "webapp"
  owner = "lab-group"
  cost_center = "departamento-lab"
}

}
############################################################################################
resource "azurerm_virtual_network" "vnet1" {
name =  "virtual-network-1"
location = azurerm_resource_group.RG1.location
resource_group_name = azurerm_resource_group.RG1.name
address_space = [ "192.168.0.0/16" ]

}
############################################################################################
resource "azurerm_subnet" "subnet1" {
  name = "vnet1-subnet"
  resource_group_name = azurerm_resource_group.RG1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes = ["192.168.10.0/24"]
}
############################################################################################
resource "azurerm_network_interface" "nic1" {
  count = 50
  name = "vm-nic1-${count.index}"
  location = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name
  
  ip_configuration {
    name = "internal1"
    subnet_id = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}
############################################################################################
resource "azurerm_windows_virtual_machine" "vm1" {
  count = 50
  name = "vm-west-${count.index}"
 resource_group_name = azurerm_resource_group.RG1.name
  location = azurerm_resource_group.RG1.location
size = "Standard_D4_v5"
admin_username = "Yeurys1"
admin_password = "yeurys123#@!"
network_interface_ids = [
azurerm_network_interface.nic1[count.index].id,
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
############################################################################################

resource "azurerm_virtual_network_peering" "vnet1-2" {
  name = "peering-1to2"
resource_group_name = azurerm_resource_group.RG1.name
virtual_network_name = azurerm_virtual_network.vnet1.name
remote_virtual_network_id = azurerm_virtual_network.vnet2.id
  allow_forwarded_traffic   = true
}
############################################################################################
resource "azurerm_route_table" "route_table2" {
  name                = "route-table-west"
  location            = azurerm_resource_group.RG1.location
  resource_group_name = azurerm_resource_group.RG1.name

  route {
    name                   = "route-to-firewall-east"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall1.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "asociacion_subnet1" {
  subnet_id      = azurerm_subnet.subnet1.id
  route_table_id = azurerm_route_table.route_table2.id
}
############################################################################################























############################################################################################

resource "azurerm_resource_group" "RG2" {
name = "rg2-lab-webapp-eastus"
location = "eastus"
tags = {
  enviroment = "lab"
  project = "webapp"
  owner = "lab-group"
  cost_center = "departamento-lab"
}
}
############################################################################################
resource "azurerm_virtual_network" "vnet2" {
name =  "virtual-network-2"
location = azurerm_resource_group.RG2.location
resource_group_name = azurerm_resource_group.RG2.name
address_space = [ "192.169.0.0/16" ]
}
############################################################################################
resource "azurerm_subnet" "subnet2" {
  name = "vnet2-subnet"
  resource_group_name = azurerm_resource_group.RG2.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes = ["192.169.20.0/24"]
}
############################################################################################
resource "azurerm_subnet" "subnet3" {
  name = "AzureFirewallSubnet"
  resource_group_name = azurerm_resource_group.RG2.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes = ["192.169.22.0/26"]
}
###################################################################################
resource "azurerm_public_ip" "firewall_ip"{
name = "firewall-ip1"
location = azurerm_resource_group.RG2.location
resource_group_name = azurerm_resource_group.RG2.name
allocation_method = "Static"
sku = "Standard"
}

############################################################################################
resource "azurerm_firewall" "firewall1" {
  name                = "firewall1"
  location            = azurerm_resource_group.RG2.location
  resource_group_name = azurerm_resource_group.RG2.name
sku_name = "AZFW_VNet"
  sku_tier = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subnet3.id
    public_ip_address_id = azurerm_public_ip.firewall_ip.id
    
  }
}
############################################################################################
resource "azurerm_firewall_network_rule_collection" "internet_rule" {
  name                = "allow-internet-traffic"
  azure_firewall_name = azurerm_firewall.firewall1.name
  resource_group_name = azurerm_resource_group.RG2.name
  priority = 200 
  action  = "Allow"

  rule {
    name                  = "allow-http-https"
    source_addresses      = ["192.168.10.0/24", "192.169.20.0/24"] 
    destination_addresses = ["*"] 
    destination_ports     = ["80", "443"] 
    protocols             = ["TCP"]
  }
}
############################################################################################
resource "azurerm_route_table" "route_table1" {
  name                = "route-table1"
  location            = azurerm_resource_group.RG2.location
  resource_group_name = azurerm_resource_group.RG2.name

  route {
    name = "route-to0firewall"
    address_prefix = "0.0.0.0/0"
    next_hop_type = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall1.ip_configuration[0].private_ip_address

   
  }
}

############################################################################################
 resource "azurerm_subnet_route_table_association" "asociacion_subnet2" {
  subnet_id      = azurerm_subnet.subnet2.id
  route_table_id = azurerm_route_table.route_table1.id
}
############################################################################################

resource "azurerm_network_interface" "nic2" {
 count = 50
  name = "vm-nic2-${count.index}"
  location = azurerm_resource_group.RG2.location
  resource_group_name = azurerm_resource_group.RG2.name
  
  ip_configuration {
    name = "internal2"
    subnet_id = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}
############################################################################################
resource "azurerm_windows_virtual_machine" "vm2" {
 count = 50
  name = "vm-east-${count.index}"
 resource_group_name = azurerm_resource_group.RG2.name
  location = azurerm_resource_group.RG2.location
size = "Standard_D4_v5"
admin_username = "Yeurys2"
admin_password = "yeurys123#@!"
network_interface_ids = [
azurerm_network_interface.nic2[count.index].id,
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
############################################################################################
resource "azurerm_virtual_network_peering" "vnet2-1" {
  name = "peering-2to1"
resource_group_name = azurerm_resource_group.RG2.name
virtual_network_name = azurerm_virtual_network.vnet2.name
remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  allow_forwarded_traffic   = true
}
#########################################################################################

