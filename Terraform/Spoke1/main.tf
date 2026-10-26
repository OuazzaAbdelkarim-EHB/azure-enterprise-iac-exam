resource "azurerm_resource_group" "spoke1" {
  name     = var.spoke1_rg_name
  location = var.location
}

# Spoke 1 VNet
resource "azurerm_virtual_network" "spoke1_vnet" {
  name                = "vnet-spoke1-abdelkarim"
  address_space       = ["10.0.1.0/24"]
  location            = azurerm_resource_group.spoke1.location
  resource_group_name = azurerm_resource_group.spoke1.name
}

resource "azurerm_subnet" "spoke1_backend" {
  name                 = "backend-sn"
  resource_group_name  = azurerm_resource_group.spoke1.name
  virtual_network_name = azurerm_virtual_network.spoke1_vnet.name
  address_prefixes     = ["10.0.1.0/26"]
}

# Data source om het Hub VNet ID op te halen via remote state
data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate-backend"
    storage_account_name = "stgtfstateabdelkarim01"
    container_name       = "tfstate"
    key                  = "hub.tfstate"
  }
}

# VNet Peering: Hub <-> Spoke 1
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                         = "hub-to-spoke1"
  resource_group_name          = "rg-abdelkarim-hub"
  virtual_network_name         = "vnet-hub-abdelkarim"
  remote_virtual_network_id    = azurerm_virtual_network.spoke1_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                         = "spoke1-to-hub"
  resource_group_name          = azurerm_resource_group.spoke1.name
  virtual_network_name         = azurerm_virtual_network.spoke1_vnet.name
  remote_virtual_network_id    = data.terraform_remote_state.hub.outputs.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Random password generatie voor de VM
resource "random_password" "vm_password" {
  length  = 16
  special = true
}

# Wachtwoord opslaan in de centrale Key Vault (die in de Hub staat)
resource "azurerm_key_vault_secret" "vm_password_secret" {
  name         = "spoke1-vm-password"
  value        = random_password.vm_password.result
  key_vault_id = "/subscriptions/3dc9629e-0f65-4d5b-a46f-f82c0141bda0/resourceGroups/rg-abdelkarim-hub/providers/Microsoft.KeyVault/vaults/kv-hub-abdelkarim01"
}

# Network Interface voor de Linux VM (zonder Public IP)
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-spoke1-vm"
  location            = azurerm_resource_group.spoke1.location
  resource_group_name = azurerm_resource_group.spoke1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "spoke1_vm" {
  name                  = "vm-spoke1-linux"
  resource_group_name   = azurerm_resource_group.spoke1.name
  location              = azurerm_resource_group.spoke1.location
  size                  = "Standard_B1ls"
  admin_username        = "azureuser"
  admin_password        = random_password.vm_password.result
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.vm_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}