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

resource "azapi_resource" "managed_environment" {
  name      = var.managed_environment_name
  location  = var.location
  parent_id = var.resource_group_id
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  tags      = local.tags
  
  body = jsonencode({
    properties = {
      daprAIInstrumentationKey = var.instrumentation_key
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = var.workspace_id
          sharedKey  = var.primary_shared_key
        }
      }
    }
  })

  lifecycle {
    ignore_changes = [
        tags
    ]
  }
}

resource "azapi_resource" "daprComponents" {
  for_each  = {for component in var.dapr_components: component.name => component}

  name      = each.key
  parent_id = azapi_resource.managed_environment.id
  type      = "Microsoft.App/managedEnvironments/daprComponents@2022-03-01"

  body = jsonencode({
    properties = {
      componentType   = each.value.componentType
      version         = each.value.version
      ignoreErrors    = each.value.ignoreErrors
      initTimeout     = each.value.initTimeout
      secrets         = each.value.secrets
      metadata        = each.value.metadata
      scopes          = each.value.scopes
    }
  })
}

resource "azapi_resource" "container_app" {
  for_each  = {for app in var.container_apps: app.name => app}

  name      = each.key
  location  = var.location
  parent_id = var.resource_group_id
  type      = "Microsoft.App/containerApps@2022-03-01"
  tags      = local.tags

  body = jsonencode({
    properties: {
      managedEnvironmentId  = azapi_resource.managed_environment.id
      configuration         = {
        ingress             = try(each.value.configuration.ingress, null)
        dapr                = try(each.value.configuration.dapr, null)
      }
      template              = each.value.template
    }
  })

  lifecycle {
    ignore_changes = [
        tags
    ]
  }
}