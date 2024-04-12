
output azurerm_virtual_network  {
 value = azurerm_virtual_network.vnet
}
output azurerm_network_interface{
    value =  [for nic in azurerm_network_interface.nic : nic.id]
}
output "test" {
    value = "testsanket"
  
}
#please output network interface private ip address
output azurerm_network_interface_private_ip_address{
    value = [for nic in azurerm_network_interface.nic : nic.private_ip_address]
}
