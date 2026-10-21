variable "rg_us_name" {
  type = string
}

variable "rg_eu_name" {
  type = string
}

variable "location_hub_us" {
  type = string
}

variable "location_spoke_us" {
  type = string
}

variable "location_hub_eu" {
  type = string
}

variable "location_spoke_eu" {
  type = string
}

variable "vnet1_hub_us_address" {
  type = list(string)
}

variable "vnet2_spoke_us_address" {
  type = list(string)
}

variable "vnet3_hub_eu_address" {
  type = list(string)
}

variable "vnet4_spoke_eu_address" {
  type = list(string)
}