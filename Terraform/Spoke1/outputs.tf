output "spoke1_vnet_id" {
  value = azurerm_virtual_network.spoke1_vnet.id
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.spoke1_vm.name
}