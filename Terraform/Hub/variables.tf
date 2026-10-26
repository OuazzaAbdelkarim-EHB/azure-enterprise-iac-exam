variable "location" {
  type        = string
  default     = "francecentral"
  description = "Azure regio voor de hub"
}

variable "hub_rg_name" {
  type        = string
  default     = "rg-abdelkarim-hub"
  description = "Naam van de hub resource group"
}