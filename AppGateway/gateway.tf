# Create a resource group
resource "azurerm_resource_group" "app_gateway_resource_group" {
  name     = "app_gateway_resource_group"
  location = "Central US"
}

# Create a public IP
resource "azurerm_public_ip" "app_gateway_public_ip" {
  name                = "app_gateway_public_ip"
  resource_group_name = azurerm_resource_group.app_gateway_resource_group.name
  location            = azurerm_resource_group.app_gateway_resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Define local variables
locals {
  resource_group_name_vnet = keys(local.vm_details)[0]
  virtual_network_name     = local.vm_details[local.resource_group_name_vnet].virtual_network.name
  vm_private_ip            = module.test["rg2"].azurerm_network_interface_private_ip_address
  web_app_domain           = [for webapp in module.appservice : webapp.azurerm_windows_web_app_hostname]
}

# Create a subnet
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "app_gateway_subnet"
  resource_group_name  = local.resource_group_name_vnet
  virtual_network_name = local.virtual_network_name
  address_prefixes     = ["10.0.3.0/24"]
}

# Create an application gateway
resource "azurerm_application_gateway" "network" {
  name                = "app_gateway"
  resource_group_name = azurerm_resource_group.app_gateway_resource_group.name
  location            = azurerm_resource_group.app_gateway_resource_group.location

  # Define SKU
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  # Define gateway IP configuration
  gateway_ip_configuration {
    name      = "app_gateway_ip_config"
    subnet_id = azurerm_subnet.gateway_subnet.id
  }

  # Define frontend port
  frontend_port {
    name = "frontend_port_80_http"
    port = 80
  }

  # Define frontend IP configuration
  frontend_ip_configuration {
    name                 = "app_gateway_frontend_ip"
    public_ip_address_id = azurerm_public_ip.app_gateway_public_ip.id
  }
  

  # Define backend address pools
  backend_address_pool {
    name         = "app_service_1_2_backend_pool"
    fqdns  = [local.web_app_domain[0], local.web_app_domain[1]]
  }
  backend_address_pool {
    name  = "app_servcie_3_4_backend_pool"
    fqdns = [local.web_app_domain[2], local.web_app_domain[3]]
  }
  backend_address_pool {
    name  ="app_service_5_6_backend_pool"
    fqdns = [local.web_app_domain[4], local.web_app_domain[5]]
  }

  # Define backend HTTP settings
  backend_http_settings {
    name                           = "app_gateway_backend_http_settings"
    cookie_based_affinity          = "Disabled"
    port                           = 80
    protocol                       = "Http"
    request_timeout                = 20
    pick_host_name_from_backend_address = true
  }

  # Define HTTP listener
  http_listener {
    name                           = "app_gateway_http_listener"
    frontend_ip_configuration_name = "app_gateway_frontend_ip"
    frontend_port_name             = "frontend_port_80_http"
    protocol                       = "Http"

  }

 

  rewrite_rule_set {
    name = "rewrite_rule_set_for_app_service_1_2"
    rewrite_rule {
      name          = "rewrite_rule_for_app_service_1_2"
      rule_sequence = 200
      condition {
        variable    = "var_uri_path"
        pattern     = "/image/(.*)"
        ignore_case = true
        negate      = false
      }
      url {
        path       = "{var_uri_path_1}"
        reroute    = false
        components = "path_only"
      }
    }
  }
  rewrite_rule_set {
    name = "rewrite_rule_set_for_app_service_3_4"
    rewrite_rule {
      name          = "rewrite_rule_for_app_service_3_4"
      rule_sequence = 200
      condition {
        variable    = "var_uri_path"
        pattern     = "/video/(.*)"
        ignore_case = true
        negate      = false
      }
      url {
        path       = "{var_uri_path_1}"
        reroute    = false
        components = "path_only"
      }
    }
  }
 

  # Define URL path map
  url_path_map {
    name = "default_url_path_map"
    default_backend_address_pool_name  = "app_service_5_6_backend_pool"
    default_backend_http_settings_name = "app_gateway_backend_http_settings"

    # Define path rules
    path_rule {
      name                           = "app_service_1_2_path_rule"
      paths                          = ["/image/*"]
      backend_address_pool_name      = "app_service_1_2_backend_pool"
      backend_http_settings_name     = "app_gateway_backend_http_settings"
      rewrite_rule_set_name          = "rewrite_rule_set_for_app_service_1_2"
    }
    path_rule {
      name                           = "app_service_3_4_path_rule"
      paths                          = ["/video/*"]
      backend_address_pool_name      = "app_servcie_3_4_backend_pool"
      backend_http_settings_name     = "app_gateway_backend_http_settings"
      rewrite_rule_set_name          = "rewrite_rule_set_for_app_service_3_4"
    }
  }

  # Define request routing rule
  request_routing_rule {
    name                           = "app_gateway_routing_rule"
    rule_type                      = "PathBasedRouting"
    http_listener_name             = "app_gateway_http_listener"
    backend_address_pool_name      = "app_service_5_6_backend_pool"
    backend_http_settings_name     = "app_gateway_backend_http_settings"
    priority                       = 2
    url_path_map_name              = "default_url_path_map"
  }

  ####################
  #uncomment the below code to enable for testing mulisite
  http_listener {
    name                           = "app_gateway_http_listener_2"
    frontend_ip_configuration_name = "app_gateway_frontend_ip"
    frontend_port_name             = "frontend_port_80_http"
    protocol                       = "Http"
    host_name = "www.xyz.com"
    
  }

  request_routing_rule {
    name                           = "app_gateway_routing_rule_2"
    rule_type                      = "Basic"
    http_listener_name             = "app_gateway_http_listener_2"
    backend_address_pool_name      = "app_service_1_2_backend_pool"
    backend_http_settings_name     = "app_gateway_backend_http_settings"
    priority                       = 1
    url_path_map_name = "default_url_path_map"
  }

  ####################
  #uncomment the below code to enable for testing internal load balancer
    frontend_ip_configuration {
    name                 = "app_gateway_frontend_ip_internal"
    subnet_id = azurerm_subnet.gateway_subnet.id
    private_ip_address    = "10.0.3.11"
    private_ip_address_allocation = "Static"

  }
}