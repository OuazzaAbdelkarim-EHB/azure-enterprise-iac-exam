# Resource Group voor de Hub
resource "azurerm_resource_group" "hub" {
  name     = var.hub_rg_name
  location = var.location
}

# Virtual Network (VNet) voor de Hub
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "vnet-hub-abdelkarim"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
}

# Subnets: frontend-sn, backend-sn en AzureBastionSubnet
resource "azurerm_subnet" "frontend_sn" {
  name                 = "frontend-sn"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.0/26"]
}

resource "azurerm_subnet" "backend_sn" {
  name                 = "backend-sn"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.64/26"]
}

resource "azurerm_subnet" "bastion_sn" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.128/26"]
}

# Azure Container Registry (ACR) - SKU: Basic
resource "azurerm_container_registry" "hub_acr" {
  name                = "acrhubabdelkarim01"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Azure Key Vault (SKU: Standard)
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "hub_kv" {
  name                        = "kv-hub-abdelkarim01"
  location                    = azurerm_resource_group.hub.location
  resource_group_name         = azurerm_resource_group.hub.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }
}

# Azure Bastion (Developer SKU - vereist geen Public IP of ip_configuration)
resource "azurerm_bastion_host" "hub_bastion" {
  name               = "bastion-hub-abdelkarim"
  location           = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                = "Developer"
  virtual_network_id = azurerm_virtual_network.hub_vnet.id
}