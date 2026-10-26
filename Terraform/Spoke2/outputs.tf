output "phpmyadmin_url" {
  value       = "http://${azurerm_container_group.phpmyadmin.fqdn}"
  description = "URL om phpMyAdmin te openen"
}

output "mysql_fqdn" {
  value       = azurerm_mysql_flexible_server.mysql.fqdn
  description = "De FQDN van de MySQL database"
}