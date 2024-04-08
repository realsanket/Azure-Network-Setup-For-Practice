# select az account 
terraform {
    required_providers {
        azurerm = {
        source  = "hashicorp/azurerm"
         version = "3.97.1"
        }
        random = {
        source  = "hashicorp/random"
        version = "3.1.0"
        }
 null = {
      source = "hashicorp/null"
      version = "3.2.2"
    }
    }
}
provider "azurerm" {
    features {}
  
}

locals {
  yaml_file= yamldecode(file("${path.module}/test.yml"))["infra_details"]
  vm_details={for key,value in local.yaml_file:value.resource_group_name=>value}

 app_service = try(merge([for value in local.yaml_file : {
  for webapp in value.webapp : webapp => {
    location = value.location
    resource_group_name = value.resource_group_name
    name = webapp
  }
}]...), {})

}
module "test" {
    source = "../vmmodule"
    for_each = local.vm_details
    resource_group_name = each.value.resource_group_name
    location = each.value.location
    virtual_network_name = each.value.virtual_network.name
    address_space = each.value.virtual_network.address_space
    subnets = each.value.virtual_network.subnets
    virtual_machines = try(each.value.virtual_machines, [])
}

module "appservice" {
  source = "../appService"
  for_each = local.app_service
  name                = each.key
  resource_group_name = each.value["resource_group_name"]
  location            = each.value["location"]
  depends_on = [ module.test]
}
resource "null_resource" "delete_test_folder" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "rm -rf test"
  }
  depends_on = [ module.appservice, module.test]
}