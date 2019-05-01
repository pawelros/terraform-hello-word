terraform {
  backend "azurerm" {
    storage_account_name = "etilterraform"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}

# define environments maintained by this terraform script
module "etil_environment_dev" {
  source      = "./modules/etil_environment"
  environment = "dev"
}

module "etil_environment_test" {
  source      = "./modules/etil_environment"
  environment = "test"
}
