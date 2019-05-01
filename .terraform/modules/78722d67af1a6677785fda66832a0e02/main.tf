# Configure the Azure Provider
provider "azurerm" {
  version = "=1.25.0"
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "terraform"
  location = "West Europe"
}

# Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "etilterraform"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

resource "azurerm_storage_container" "blob-container" {
  name                  = "terraform-state"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  storage_account_name  = "${azurerm_storage_account.storage.name}"
  container_access_type = "private"
}

resource "azurerm_storage_blob" "blob" {
  name = "prod.terraform.tfstate"

  resource_group_name    = "${azurerm_resource_group.rg.name}"
  storage_account_name   = "${azurerm_storage_account.storage.name}"
  storage_container_name = "${azurerm_storage_container.blob-container.name}"

  type = "page"
  size = 5120
}