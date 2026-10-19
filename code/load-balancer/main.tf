resource "azurerm_resource_group" "RG" {
  name = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "VNET" {
  name = var.vnet_name
  location = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  address_space = [ var.vnet_address ]
}

resource "azurerm_subnet" "SUBNET" {
  count = length(var.subnet_prefixes)
  name = "subnet-${count.index + 1}"
  resource_group_name = azurerm_resource_group.RG.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes = [var.subnet_prefixes[count.index]]
}

resource "azurerm_network_security_group" "NSG" {
  name = "NSG-01"
  location = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  security_rule {
    name = "permitir_http"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-association" {
  count = length(var.subnet_prefixes)
  subnet_id = azurerm_subnet.SUBNET[count.index].id
  network_security_group_id = azurerm_network_security_group.NSG.id
}

resource "azurerm_public_ip" "IP-Publica" {
  name = "pip-01"
  location = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method = "Static"
  sku = var.pip_sku
}

resource "azurerm_lb" "LB" {
  name = "Public-LB"
  location = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  sku = var.LB_SKU

  frontend_ip_configuration {
    name = "Public-IP"
    public_ip_address_id = azurerm_public_ip.IP-Publica.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend-pool" {
  name = "Backend_Pool"
  loadbalancer_id = azurerm_lb.LB.id
}

resource "azurerm_lb_probe" "health-probe" {
  name = "Health-Probe-01"
  loadbalancer_id = azurerm_lb.LB.id
  port = 80
  protocol = "Http"
  request_path = "/"
}

resource "azurerm_lb_rule" "lb-rule" {
  name = "http-rule"
  loadbalancer_id = azurerm_lb.LB.id
  protocol = "Tcp"
  frontend_port = 80
  backend_port = 80
  frontend_ip_configuration_name = "Public-IP"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend-pool.id]
  probe_id = azurerm_lb_probe.health-probe.id
}

resource "azurerm_network_interface" "NICS" {
  count = length(var.subnet_prefixes)
  name = "nic-vm${count.index + 1}"
  location = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name = "internal"
    subnet_id  = azurerm_subnet.SUBNET[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nic-to-pool" {
  count  = length(var.subnet_prefixes)
  network_interface_id = azurerm_network_interface.NICS[count.index].id
  ip_configuration_name = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend-pool.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  count = length(var.subnet_prefixes)
  name = "vm-web-0${count.index + 1}"
  resource_group_name = azurerm_resource_group.RG.name
  location = azurerm_resource_group.RG.location
  size = var.vm_size
  admin_username = var.admin_user
  admin_password = var.admin_pass
  network_interface_ids = [
    azurerm_network_interface.NICS[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer = "WindowsServer"
    sku = var.windows_sku
    version   = "latest"
  }
}