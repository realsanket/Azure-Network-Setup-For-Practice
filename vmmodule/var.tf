variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Location of the resource group"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "Address space of the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "List of subnets in the virtual network"
  type        = list(object({
    name           = string
    address_prefix = string
  }))
}

variable "virtual_machines" {
  description = "List of virtual machines to create"
  type        = list(object({
    name   = string
    subnet = string
    size   = string
  }))

}