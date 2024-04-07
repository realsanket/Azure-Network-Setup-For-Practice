
resource "azurerm_resource_group" "rg" {
    name     = "loadbalancer-rg"
    location = "Central India"
}
#create public ip for load balancer with standard sku
resource "azurerm_public_ip" "publicipcentralindia" {
    name                = "loadbalancer-publicip-centralindia"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    allocation_method   = "Static"
    sku                 = "Standard"
}
#create load balancer with standard sku
resource "azurerm_lb" "lbcentralindia" {
    name                = "loadbalancer-centralindia"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "Standard"
    frontend_ip_configuration {
        name                 = "PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.publicipcentralindia.id
    }
}
#create a backend pool
resource "azurerm_lb_backend_address_pool" "pool" {
    name                = "backendpool"
    loadbalancer_id     = azurerm_lb.lbcentralindia.id
}
#add virtual machines to backend pool
resource "azurerm_network_interface_backend_address_pool_association" "poolassociation" {
    count                    = 2
    network_interface_id     = module.test["rg2"].azurerm_network_interface[count.index]
    ip_configuration_name    = "internal"
    backend_address_pool_id  = azurerm_lb_backend_address_pool.pool.id
}
#let's crate a azure load balancer rule
resource "azurerm_lb_rule" "rule" {
    name                  = "web"
    loadbalancer_id       = azurerm_lb.lbcentralindia.id
    protocol              = "Tcp"
    frontend_port         = 80
    backend_port          = 80
    frontend_ip_configuration_name = "PublicIPAddress"
    backend_address_pool_ids        = [azurerm_lb_backend_address_pool.pool.id]
}
#so far natting is not working and can't assign virtual machine beacuse of
#Can't configure a value for "backend_ip_configuration_id":
#ADD THIS MANUALLY
resource "azurerm_lb_nat_rule" "natrule" {
    count                  = 2
    name                   = "RDP-${count.index}"
    resource_group_name    = azurerm_resource_group.rg.name
    loadbalancer_id        = azurerm_lb.lbcentralindia.id
    protocol               = "Tcp"
    frontend_port          = 5000 + count.index
    backend_port           = 3389
    frontend_ip_configuration_name = "PublicIPAddress"
    }


########### doing this for central us region

resource "azurerm_resource_group" "rg_centralus" {
    name     = "loadbalancer-rg-centralus"
    location = "Central US"
}

resource "azurerm_public_ip" "publicip_centralus" {
    name                = "loadbalancer-publicip-centralus2"
    resource_group_name = azurerm_resource_group.rg_centralus.name
    location            = azurerm_resource_group.rg_centralus.location
    allocation_method   = "Static"
    sku                 = "Standard"
}

resource "azurerm_lb" "lb_centralus" {
    name                = "loadbalancer-centralus2"
    resource_group_name = azurerm_resource_group.rg_centralus.name
    location            = azurerm_resource_group.rg_centralus.location
    sku                 = "Standard"

    frontend_ip_configuration {
        name                 = "PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.publicip_centralus.id
    }
}

resource "azurerm_lb_backend_address_pool" "pool_centralus" {
    name                = "backendpool-centralus"
    loadbalancer_id     = azurerm_lb.lb_centralus.id
}

resource "azurerm_network_interface_backend_address_pool_association" "poolassociation_centralus" {
    count                    = 2
    network_interface_id     = module.test["rg1"].azurerm_network_interface[count.index]
    ip_configuration_name    = "internal"
    backend_address_pool_id  = azurerm_lb_backend_address_pool.pool_centralus.id
}

resource "azurerm_lb_rule" "rule_centralus" {
    name                  = "web-centralus"
    loadbalancer_id       = azurerm_lb.lb_centralus.id
    protocol              = "Tcp"
    frontend_port         = 80
    backend_port          = 80
    frontend_ip_configuration_name = "PublicIPAddress"
    backend_address_pool_ids        = [azurerm_lb_backend_address_pool.pool_centralus.id]
}

resource "azurerm_lb_nat_rule" "natrule_centralus" {
    count                  = 2
    name                   = "RDP-centralus-${count.index}"
    resource_group_name    = azurerm_resource_group.rg_centralus.name
    loadbalancer_id        = azurerm_lb.lb_centralus.id
    protocol               = "Tcp"
    frontend_port          = 5000 + count.index
    backend_port           = 3389
    frontend_ip_configuration_name = "PublicIPAddress"
}