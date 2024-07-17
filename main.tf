terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.112.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#Criar Resouce Group para todos os recursos
resource "azurerm_resource_group" "rg" {
  name     = "dvilanova-rg"
  location = "West US 2"
}
