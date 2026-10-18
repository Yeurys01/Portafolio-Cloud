resource "azurerm_resource_group" "rg"{
    name = "rg-lab-eastus"
    location = "eastus"

    tags = {
  enviroment = "LAB"
  project = "PRIVATE-ENDPOINT"
  owner = "Yeurys"
  cost_center = "departamento-Yeurys"
}

    }

resource "azurerm_virtual_network" "VNET-LAB" {
    name = "vnet1"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "SUBNET" {
    name = "subnet-lab"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.VNET-LAB.name
    address_prefixes = ["192.168.10.0/24"]
}

resource "azurerm_storage_account" "Blob-storage" {
    name = "yeurysblobstrg001"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    account_tier = "Standard"
    account_replication_type = "LRS"
public_network_access_enabled = false
}

resource "azurerm_private_dns_zone" "dns-privado" {
    name = "privatelink.blob.core.windows.net"
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns-link" {
    name = "private-dns-link"
    resource_group_name = azurerm_resource_group.rg.name
    private_dns_zone_name = azurerm_private_dns_zone.dns-privado.name
    virtual_network_id = azurerm_virtual_network.VNET-LAB.id
}

resource "azurerm_private_endpoint" "PE" {
    name = "PE-LAB"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    subnet_id = azurerm_subnet.SUBNET.id

    private_service_connection {
        name = "conexion-privada-storage"
        private_connection_resource_id =azurerm_storage_account.Blob-storage.id
        subresource_names = ["blob"]
        is_manual_connection = false
    }

    private_dns_zone_group {
        name = "dns-group-storage"
        private_dns_zone_ids = [azurerm_private_dns_zone.dns-privado.id]

    }
}

