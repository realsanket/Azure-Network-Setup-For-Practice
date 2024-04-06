variable "name" {
  description = "Name of the service plan"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group in which the service plan should be created"
  type        = string
}
variable "location" {
  description = "Location of the resource group in which the service plan should be created"
  type        = string
}