output "acr_login_server" {
  value       = azurerm_container_registry.hub_acr.login_server
  description = "De volledige server login naam van de ACR"
}

output "hub_vnet_id" {
  value       = azurerm_virtual_network.hub_vnet.id
  description = "De ID van het Hub VNet"
}