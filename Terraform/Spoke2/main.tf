resource "azurerm_resource_group" "spoke2" {
  name     = var.spoke2_rg_name
  location = var.location
}

# Spoke 2 VNet
resource "azurerm_virtual_network" "spoke2_vnet" {
  name                = "vnet-spoke2-abdelkarim"
  address_space       = ["10.0.2.0/24"]
  location            = azurerm_resource_group.spoke2.location
  resource_group_name = azurerm_resource_group.spoke2.name
}

resource "azurerm_subnet" "spoke2_backend" {
  name                 = "backend-sn"
  resource_group_name  = azurerm_resource_group.spoke2.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes     = ["10.0.2.0/26"]
}

resource "azurerm_subnet" "spoke2_db" {
  name                 = "db-sn"
  resource_group_name  = azurerm_resource_group.spoke2.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes     = ["10.0.2.64/26"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "mysql_delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Data source voor Hub remote state
data "terraform_remote_state" "hub" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate-backend"
    storage_account_name = "stgtfstateabdelkarim01"
    container_name       = "tfstate"
    key                  = "hub.tfstate"
  }
}

# VNet Peering: Hub <-> Spoke 2
resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                         = "hub-to-spoke2"
  resource_group_name          = "rg-abdelkarim-hub"
  virtual_network_name         = "vnet-hub-abdelkarim"
  remote_virtual_network_id    = azurerm_virtual_network.spoke2_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                         = "spoke2-to-hub"
  resource_group_name          = azurerm_resource_group.spoke2.name
  virtual_network_name         = azurerm_virtual_network.spoke2_vnet.name
  remote_virtual_network_id    = data.terraform_remote_state.hub.outputs.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Wachtwoord generatie voor MySQL
resource "random_password" "db_password" {
  length  = 16
  special = false # MySQL houdt soms niet van bepaalde speciale tekens in root pass
}

# Private DNS Zone voor MySQL Flexible Server
resource "azurerm_private_dns_zone" "mysql_dns" {
  name                = "abdelkarim.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.spoke2.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                  = "mysql-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.mysql_dns.name
  virtual_network_id    = azurerm_virtual_network.spoke2_vnet.id
  resource_group_name   = azurerm_resource_group.spoke2.name
}

# Azure Database for MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "mysql-server-abdelkarim"
  location               = azurerm_resource_group.spoke2.location
  resource_group_name    = azurerm_resource_group.spoke2.name
  administrator_login    = "mysqladmin"
  administrator_password = random_password.db_password.result
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  delegated_subnet_id    = azurerm_subnet.spoke2_db.id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql_dns.id
  zone                   = "1"

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql_dns_link]
}

# Azure Container Instance (ACI) met phpMyAdmin
resource "azurerm_container_group" "phpmyadmin" {
  name                = "aci-phpmyadmin"
  location            = azurerm_resource_group.spoke2.location
  resource_group_name = azurerm_resource_group.spoke2.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = "phpmyadmin-abdelkarim-exam"

  container {
    name   = "phpmyadmin"
    image  = "phpmyadmin/phpmyadmin"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      PMA_HOST = azurerm_mysql_flexible_server.mysql.fqdn
    }
  }
}