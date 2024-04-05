resource "azurerm_resource_group" "rg" {
    name     = var.resource_group_name
    location = var.location
}
#create azurerm_virtual_network 
resource "azurerm_virtual_network" "vnet" {
    name                = var.virtual_network_name
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    address_space       = var.address_space
    depends_on = [ azurerm_resource_group.rg ]
  
}
#create azurerm_subnet
resource "azurerm_subnet" "subnet" {
    for_each = { for idx, subnet in var.subnets : subnet.name => subnet }
    name                 = each.value.name
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes       = [each.value.address_prefix]
    depends_on = [ azurerm_virtual_network.vnet ]
}

#azurerm_public_ip
resource "azurerm_public_ip" "publicip" {
    for_each = { for vm in var.virtual_machines : "${vm.name}" => vm }
    name                = "networking-practice-publicip-${each.value.name}"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    allocation_method   = "Dynamic"
    domain_name_label   = "networkingpractice${each.value.name}"
    depends_on = [ azurerm_resource_group.rg ]
}
#azurerm_network_interface
resource "azurerm_network_interface" "nic" {
    for_each = { for vm in var.virtual_machines : "${vm.name}" => vm }
    name                = "networking-practice-nic-${each.value.name}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.subnet[each.value.subnet].id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.publicip[each.key].id
    }
    depends_on = [ azurerm_public_ip.publicip ]
}
resource "azurerm_network_security_group" "nsg" {
    name                = "networking-practice-nsg"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    security_rule {
        name                       = "HTTP"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    #3389
    security_rule {
        name                       = "RDP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
      security_rule {
        name                       = "SSH"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}


##azurerm_network_interface_security_group_association with all NIC

resource "azurerm_network_interface_security_group_association" "nsg_association" {
    for_each = azurerm_network_interface.nic
    network_interface_id      = each.value.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}
#azurerm_windows_virtual_machine
resource "azurerm_windows_virtual_machine" "vm" {
    for_each = { for vm in var.virtual_machines : "${vm.name}" => vm }
    name                = "${each.value.name}-${azurerm_resource_group.rg.location}"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    network_interface_ids = [azurerm_network_interface.nic[each.key].id]
    size                = each.value.size
    admin_username      = "adminuser"
    admin_password      = "Password1234!"
    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2019-Datacenter"
        version   = "latest"
    }
    depends_on = [ azurerm_network_interface.nic ]
}
#azurerm_virtual_machine_extension 
resource "azurerm_virtual_machine_extension" "installIIS" {
    for_each = { for vm in var.virtual_machines : "${vm.name}" => vm }
    name                 = "installIIS7-${each.value.name}"
    virtual_machine_id   = azurerm_windows_virtual_machine.vm[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    { 
      "commandToExecute": "powershell Add-WindowsFeature Web-Server; Set-Content -Path C:\\inetpub\\wwwroot\\Default.html -Value \\\"This is the Sanket Server $env:computername!\\\""
    } 
SETTINGS
    depends_on = [ azurerm_windows_virtual_machine.vm ]
}