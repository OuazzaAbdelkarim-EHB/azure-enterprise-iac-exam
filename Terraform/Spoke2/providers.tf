terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-backend"
    storage_account_name = "stgtfstateabdelkarim01"
    container_name       = "tfstate"
    key                  = "spoke2.tfstate"
  }
}

provider "azurerm" {
  features {}
}