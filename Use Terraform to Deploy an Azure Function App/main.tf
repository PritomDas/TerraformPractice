terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.21.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.1"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

provider "null" {
  # Configuration options
}

# VARS
#============================
variable "resource_group_name" {}

variable "location" {}

# RANDOM NAMES
#============================

resource "random_id" "storage_account" {
  byte_length = 8
}

resource "random_id" "func_name" {
  byte_length = 8
}

# STORAGE ACCOUNT
#============================

resource "azurerm_storage_account" "sa" {
  name                      = "cadevops${lower(random_id.storage_account.hex)}"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  enable_https_traffic_only = true
}

# SERVICE PLAN
#============================

resource "azurerm_service_plan" "asp" {
  name                = "cloudacademydevops-asp"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

# FUNCTION APP
#============================

resource "azurerm_linux_function_app" "cloudacademydevops_func" {
  name                = "app${lower(random_id.storage_account.hex)}"
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
  }

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  tags = {
    org = "cloudacademy"
    app = "devops"
  }
}
# OUTPUTS
#============================

output "app_name" {
  value       = azurerm_linux_function_app.cloudacademydevops_func.name
  description = "Deployed function app name"
}
