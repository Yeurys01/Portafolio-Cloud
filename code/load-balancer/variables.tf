variable "resource_group_name" {
  type = string
  default = "RG"
}

variable "vnet_name" {
  type = string
  default = "VNET"
}

variable "location" {
  type = string
  default = "eastus"
}

variable "vnet_address" {
  type = string
  default = "192.168.0.0/16"
}

variable "subnet_name" {
  type = string
  default = "SUBNET"
}

variable "subnet_prefixes" {
  type = list(string)
  default = [ "192.168.10.0/24", "192.168.20.0/24" ]
}

variable "LB_SKU" {
  type = string
  default = "Standard"
}

variable "pip_sku" {
  type = string
  default = "Standard"
}

variable "vm_size" {
  type = string
  default = "Standard_B2s"
}

variable "os_disk_type" {
  type = string
  default = "Standard_LRS"
}

variable "windows_sku" {
    type = string
    default = "2022-datacenter-azure-edition"
}

variable "admin_user" {
    type = string
}

variable "admin_pass" {
  type = string
  sensitive = true
}
