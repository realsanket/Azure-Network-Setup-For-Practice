#create resource group for private dns
resource "azurerm_resource_group" "private_dns" {
  name="private_dns"
    location="East US"
}
resource "azurerm_private_dns_zone" "example" {
  name                = "google.com"
  resource_group_name = azurerm_resource_group.private_dns.name
}
