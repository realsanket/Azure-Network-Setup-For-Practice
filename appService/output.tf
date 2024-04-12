#please output app service default hostname
output azurerm_windows_web_app_hostname{
    value = azurerm_windows_web_app.example.default_hostname
}