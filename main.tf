# Configure the Azure Provider
provider "azurerm" {
version = "=1.25.0"
}

# Local variables
locals {
  service_prefix = "etil"
  environment = "test"
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
    name     = "${local.environment}"
    location = "West Europe"
}

# Create an app service plan
resource "azurerm_app_service_plan" "sp" {
  name                = "app-service-plan"
  resource_group_name = "${azurerm_resource_group.rg.name}",
  location            = "${azurerm_resource_group.rg.location}"
  sku = {
      tier = "Free",
      size = "B1"
      }
}

# Create an app service
resource "azurerm_app_service" "as" {
  name                  = "${local.service_prefix}-${local.environment}"
  resource_group_name   = "${azurerm_resource_group.rg.name}",
  app_service_plan_id   = "${azurerm_app_service_plan.sp.id}",
  location              = "${azurerm_resource_group.rg.location}",
  app_settings = {
      ConnectionStrings__FContext = "",
      ConnectionStrings__IContext = "",
      ConnectionStrings__RContext = "",
      ConnectionStrings__AContext = "",
  }
}

# Create a SQL server with a database

resource "random_string" "password" {
  length = 16
  special = true
  #override_special = "/@\" "
}

resource "azurerm_sql_server" "sql-server" {
  name                         = "${local.service_prefix}-${local.environment}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  location                     = "${azurerm_resource_group.rg.location}"
  version                      = "12.0"
  administrator_login          = "etil_admin"
  administrator_login_password = "${random_string.password.result}"
}

resource "azurerm_sql_database" "auth-sql-database" {
  name                = "auth-${local.service_prefix}-${local.environment}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sql-server.name}"
}