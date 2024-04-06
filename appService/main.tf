
resource "azurerm_service_plan" "app_service_plan" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "F1"
  os_type             = "Windows"
}
#random_id
resource "random_id" "random" {
  byte_length = 8
}
# Create a windows app service
resource "azurerm_windows_web_app" "example" {
  name                = "${var.name}-${random_id.random.hex}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id = azurerm_service_plan.app_service_plan.id
  site_config {
    always_on = false
    
  } 
 lifecycle {
    ignore_changes = [
      site_config
    ]
  }
  depends_on = [azurerm_service_plan.app_service_plan]
 
}
#deploy static content to app service through az cli


resource "null_resource" "zip_and_save_command" {
  provisioner "local-exec" {
    command = <<EOF
      mkdir -p test && 
      mkdir -p test/${azurerm_windows_web_app.example.name} && 
      echo '<!DOCTYPE html><html><head><title>${azurerm_windows_web_app.example.name}</title></head><body><h1>${azurerm_windows_web_app.example.name}</h1><p>Location: ${var.location}</p></body></html>' > test/${azurerm_windows_web_app.example.name}/index.html && 
      cd test/${azurerm_windows_web_app.example.name} && 
      zip -r ../${azurerm_windows_web_app.example.name}.zip index.html && 
      cd - && 
      az webapp deployment source config-zip --resource-group ${var.resource_group_name} --name ${azurerm_windows_web_app.example.name} --src test/${azurerm_windows_web_app.example.name}.zip
    EOF
  }
}