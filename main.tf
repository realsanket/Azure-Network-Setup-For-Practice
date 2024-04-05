# select az account 
terraform {
    required_providers {
        azurerm = {
        source  = "hashicorp/azurerm"
         version = "3.97.1"
        }
    }
}
provider "azurerm" {
    features {}
  
}

locals {
  yaml_file= yamldecode(file("${path.module}/test.yml"))["infra_details"]
  vm_details={for key,value in local.yaml_file:value.resource_group_name=>value}

}
module "test" {
    source = "./vmmodule"
    for_each = local.vm_details
    resource_group_name = each.value.resource_group_name
    location = each.value.location
    virtual_network_name = each.value.virtual_network.name
    address_space = each.value.virtual_network.address_space
    subnets = each.value.virtual_network.subnets
    virtual_machines = each.value.virtual_machines
}

