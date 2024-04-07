
output azurerm_virtual_network  {
 value = azurerm_virtual_network.vnet
}
output azurerm_network_interface{
    value =  [for nic in azurerm_network_interface.nic : nic.id]
}
output "test" {
    value = "testsanket"
  
}