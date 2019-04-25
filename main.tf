# Configure the Azure Provider
provider "azurerm" {
version = "=1.25.0"
}

# Local variables
locals {
  service_prefix = "etil"
  environment = "test",
  sql_admin_username = "etil_admin"
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
    name     = "${local.environment}"
    location = "West Europe"
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
  administrator_login          = "${local.sql_admin_username}"
  administrator_login_password = "${random_string.password.result}"
}

resource "azurerm_sql_database" "auth-sql-database" {
  name                = "auth-${local.service_prefix}-${local.environment}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sql-server.name}"
}

resource "azurerm_sql_database" "import-sql-database" {
  name                = "import-${local.service_prefix}-${local.environment}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sql-server.name}"
}

resource "azurerm_sql_database" "etil-sql-database" {
  name                = "${local.service_prefix}-${local.environment}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  server_name         = "${azurerm_sql_server.sql-server.name}"
}

# Create Azure Cache for Redis instance
resource "azurerm_redis_cache" "redis" {
  name                = "${local.service_prefix}-${local.environment}",
  location            = "${azurerm_resource_group.rg.location}",
  resource_group_name = "${azurerm_resource_group.rg.name}",
  capacity            = 0,
  family              = "C",
  sku_name            = "Basic",
  enable_non_ssl_port = false,
  redis_configuration = {
  }
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
      ConnectionStrings__FContext = "${azurerm_sql_database.etil-sql-database.name}.database.windows.net;Initial Catalog=${azurerm_sql_database.etil-sql-database.name};Persist Security Info=True;User ID=${local.sql_admin_username};Password=${azurerm_sql_server.sql-server.administrator_login_password};MultipleActiveResultSets=True",
      ConnectionStrings__IContext = "${azurerm_sql_database.import-sql-database.name}.database.windows.net;Initial Catalog=${azurerm_sql_database.import-sql-database.name};Persist Security Info=True;User ID=${local.sql_admin_username};Password=${azurerm_sql_server.sql-server.administrator_login_password};MultipleActiveResultSets=True",
      ConnectionStrings__RContext = "${azurerm_redis_cache.redis.name}.redis.cache.windows.net:6380,password=${azurerm_redis_cache.redis.primary_access_key},ssl=True,abortConnect=False,allowAdmin=true",
      ConnectionStrings__AContext = "${azurerm_sql_database.auth-sql-database.name}.database.windows.net;Initial Catalog=${azurerm_sql_database.auth-sql-database.name};Persist Security Info=True;User ID=${local.sql_admin_username};Password=${azurerm_sql_server.sql-server.administrator_login_password};MultipleActiveResultSets=True",
  }
}
