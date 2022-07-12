terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.3.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "0.4.0"
    }
  }
  experiments = [module_variable_optional_attrs]
}

provider "azurerm" {
  features {}
}

provider "azapi" {
}

resource "random_string" "resource_prefix" {
  length  = 6
  special = false
  upper   = false
  numeric  = false
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_prefix != "" ? var.resource_prefix : random_string.resource_prefix.result}${var.resource_group_name}"
  location = var.location
  tags     = var.tags
}

module "log_analytics_workspace" {
  source                           = "./modules/log_analytics"
  name                             = "${var.resource_prefix != "" ? var.resource_prefix : random_string.resource_prefix.result}${var.log_analytics_workspace_name}"
  location                         = var.location
  resource_group_name              = azurerm_resource_group.rg.name
  tags                             = var.tags
}

module "application_insights" {
  source                           = "./modules/application_insights"
  name                             = "${var.resource_prefix != "" ? var.resource_prefix : random_string.resource_prefix.result}${var.application_insights_name}"
  location                         = var.location
  resource_group_name              = azurerm_resource_group.rg.name
  tags                             = var.tags
  application_type                 = var.application_insights_application_type
  workspace_id                     = module.log_analytics_workspace.id
}

module "storage_account" {
  source                           = "./modules/storage_account"
  name                             = lower("${var.resource_prefix != "" ? var.resource_prefix : random_string.resource_prefix.result}${var.storage_account_name}")
  location                         = var.location
  resource_group_name              = azurerm_resource_group.rg.name
  tags                             = var.tags
  account_kind                     = var.storage_account_kind
  account_tier                     = var.storage_account_tier
  replication_type                 = var.storage_account_replication_type
}

module "container_app" {
  source                           = "./modules/container_apps"
  managed_environment_name         = "${var.resource_prefix != "" ? var.resource_prefix : random_string.resource_prefix.result}${var.managed_environment_name}"
  location                         = var.location
  resource_group_id                = azurerm_resource_group.rg.id
  tags                             = var.tags
  instrumentation_key              = module.application_insights.instrumentation_key
  workspace_id                     = module.log_analytics_workspace.workspace_id
  primary_shared_key               = module.log_analytics_workspace.primary_shared_key
  dapr_components                  = [{
                                      name            = var.dapr_component_name
                                      componentType   = var.dapr_component_type
                                      version         = var.dapr_component_version
                                      ignoreErrors    = var.dapr_ignore_errors
                                      initTimeout     = var.dapr_component_init_timeout
                                      secrets         = [
                                        {
                                          name        = "storageaccountkey"
                                          value       = module.storage_account.primary_access_key
                                        }
                                      ]
                                      metadata: [
                                        {
                                          name        = "accountName"
                                          value       = module.storage_account.name
                                        },
                                        {
                                          name        = "containerName"
                                          value       = var.container_name
                                        },
                                        {
                                          name        = "accountKey"
                                          secretRef   = "storageaccountkey"
                                        }
                                      ]
                                      scopes          = var.dapr_component_scopes
                                     }]
  container_apps                   = var.container_apps
}