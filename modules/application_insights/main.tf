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

locals {
  module_tag = {
    "module" = basename(abspath(path.module))
  }
  tags = merge(var.tags, local.module_tag)
}

resource "azurerm_application_insights" "resource" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
  application_type    = "web"
  workspace_id        = var.workspace_id

  lifecycle {
    ignore_changes = [
        tags
    ]
  }
}