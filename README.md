---
page_type: sample
languages:
- azurecli
- bash
- terraform
- yaml
- json
products:
- azure
- azure-container-apps
- azure-storage
- azure-blob-storage
- azure-storage-accounts
- azure-monitor
- azure-log-analytics
- azure-application-insights

name:  Deploy a Dapr application to Azure Container Apps with Terraform and AzAPI Provider
description: This sample shows how to deploy a Dapr application to Azure Container Apps using Terraform modules and the AzAPI Provider.
urlFragment: container-apps-azapi-terraform
---

# Deploy a Dapr application to Azure Container Apps with Terraform and AzAPI Provider

[Dapr](https://dapr.io/) (Distributed Application Runtime) is a runtime that helps you build resilient stateless and stateful microservices. This sample shows how to deploy a [Dapr](https://dapr.io/) application to [Azure Container Apps](https://docs.microsoft.com/en-us/azure/container-apps/overview) using Terraform modules and the [AzAPI Provider](https://registry.terraform.io/providers/azure/azapi/latest/docs) instead of an Azure Resource Manager (ARM) or Bicep template like in the original sample [Tutorial: Deploy a Dapr application to Azure Container Apps with an Azure Resource Manager or Bicep template](https://docs.microsoft.com/en-us/azure/container-apps/microservices-dapr-azure-resource-manager?tabs=bash&pivots=container-apps-bicep).

In this sample you will learn how to:

- Use Terraform and [AzAPI Provider](https://registry.terraform.io/providers/azure/azapi/latest/docs) to deploy an microservice-based application to Azure Contains Apps.
- Create an Azure Blob Storage for use as a [Dapr](https://dapr.io/) state store
- Deploy an [Azure Container Apps environment](https://docs.microsoft.com/en-us/azure/container-apps/environment) to host one or more Azure Container Apps
- Deploy two [Dapr-enabled](https://docs.microsoft.com/en-us/azure/container-apps/dapr-overview?tabs=bicep1%2Cyaml) Azure Container Apps: one that produces orders and one that consumes orders and stores them
- Verify the interaction between the two microservices.

With Azure Container Apps, you get a [fully managed version of the Dapr APIs](./dapr-overview.md) when building microservices. When you use [Dapr](https://dapr.io/) in Azure Container Apps, you can enable sidecars to run next to your microservices that provide a rich set of capabilities. Available Dapr APIs include [Service to Service calls](https://docs.dapr.io/developing-applications/building-blocks/service-invocation/), [Pub/Sub](https://docs.dapr.io/developing-applications/building-blocks/pubsub/), [Event Bindings](https://docs.dapr.io/developing-applications/building-blocks/bindings/), [State Stores](https://docs.dapr.io/developing-applications/building-blocks/state-management/), and [Actors](https://docs.dapr.io/developing-applications/building-blocks/actors/).

In this sample, you deploy the same applications from the Dapr [Hello World](https://github.com/dapr/quickstarts/tree/master/tutorials/hello-world) quickstart.

The application consists of:

- A client (Python) container app to generate messages.
- A service (Node) container app to consume and persist those messages in a state store

The following architecture diagram illustrates the components that make up this tutorial:

![Architecture](./images/azure-container-apps-microservices-dapr.png)

## Prerequisites

- Install [Azure CLI](/cli/azure/install-azure-cli)
- An Azure account with an active subscription is required. If you don't already have one, you can [create an account for free](https://azure.microsoft.com/free/?WT.mc_id=A261C142F). If you don't have one, create a [free Azure account](https://azure.microsoft.com/free/) before you begin.
- [Visual Studio Code](https://code.visualstudio.com/) installed on one of the [supported platforms](https://code.visualstudio.com/docs/supporting/requirements#_platforms) along with the [HashiCorp Terraform](hhttps://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform).

## What is AzAPI Provider?

The [AzAPI Provider](https://registry.terraform.io/providers/azure/azapi/latest/docs) is a very thin layer on top of the Azure ARM REST APIs. This provider compliments the [AzureRM provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) by enabling the management of Azure resources that are not yet or may never be supported in the AzureRM provider such as private/public preview services and features. The [AzAPI provider](https://docs.microsoft.com/en-us/azure/developer/terraform/overview-azapi-provider) enables you to manage any Azure resource type using any API version. This provider complements the AzureRM provider by enabling the management of new Azure resources and properties (including private preview). For more information, see [Overview of the Terraform AzAPI provider](https://docs.microsoft.com/en-us/azure/developer/terraform/overview-azapi-provider).

## Terraform modules

This sample contains Terraform modules to create the following resources:

- [Microsoft.OperationalInsights/workspaces](https://docs.microsoft.com/en-us/azure/templates/microsoft.operationalinsights/workspaces): an [Azure Log Analytics](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-workspace-overview) workspace used to collect logs and metrics of the [Azure Container Apps environment](https://docs.microsoft.com/en-us/azure/container-apps/environment).
- [Microsoft.Insights/components](https://docs.microsoft.com/en-us/azure/templates/microsoft.insights/components): an [Azure Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview) used by the Azure Container Apps for logging and distributed tracing.
- [Microsoft.Storage/storageAccounts](https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts): this storage account is used to store state of the Dapr component. 
- [Microsoft.App/managedEnvironments](https://docs.microsoft.com/en-us/azure/templates/microsoft.app/managedenvironments): an [Azure Container Apps environment](https://docs.microsoft.com/en-us/azure/container-apps/environment) that will host two Azure Container Apps.
- [Microsoft.App/managedEnvironments/daprComponents](https://docs.microsoft.com/en-us/azure/templates/microsoft.app/managedenvironments/daprcomponents): a [state management Dapr component](https://docs.dapr.io/developing-applications/building-blocks/state-management/state-management-overview/) that hosts the orders created by the service application.
- [Microsoft.App/containerApps](https://docs.microsoft.com/en-us/azure/templates/microsoft.app/containerapps): two dapr-enabled Container Apps: [hello-k8s-node](https://hub.docker.com/r/dapriosamples/hello-k8s-node) and [hello-k8s-python](https://hub.docker.com/r/dapriosamples/hello-k8s-python)

The following table contains the code of the `modules/contains_apps/main.tf` Terraform module used to create the Azure Container Apps environment, Dapr components, and Container Apps.

```terraform
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
```

As you can see, the module uses an [azapi_resource](https://docs.microsoft.com/en-us/azure/developer/terraform/overview-azapi-provider) to create the resources. You can use an [azapi_resource](https://docs.microsoft.com/en-us/azure/developer/terraform/overview-azapi-provider) to fully manage any Azure (control plane) resource (API) with full CRUD. Example Use Cases:

- New preview service
- New feature added to existing service
- Existing feature or service not currently supported by the AzureRM provider

For more information, see [Overview of the Terraform AzAPI provider](https://docs.microsoft.com/en-us/azure/developer/terraform/overview-azapi-provider).

## Deploy the sample

All the resources deployed by the modules share the same name prefix. Make sure to configure a name prefix by setting a value for the `resource_prefix` variable defined in the `variables.tf` file. If you set the value of the `resource_prefix` variable to an empty string, the `main.tf` module will use a `random_string` resource to automatically create a name prefix for the Azure resources. You can use the `deploy.sh` bash script to deploy the sample:

```bash
#!/bin/bash

# Terraform Init
terraform init

# Terraform validate
terraform validate -compact-warnings

# Terraform plan
terraform plan -compact-warnings -out main.tfplan

# Terraform apply
terraform apply -compact-warnings -auto-approve main.tfplan
```
This command deploys the Terraform modules that create the following resources:

- The Container Apps environment and associated Log Analytics workspace for hosting the hello world Dapr solution.
- An Application Insights instance for Dapr distributed tracing.
- The `nodeapp` app server running on `targetPort: 3000` with dapr enabled and configured using: `"appId": "nodeapp"` and `"appPort": 3000`.
- The `daprComponents` object of `"type": "state.azure.blobstorage"` scoped for use by the `nodeapp` for storing state.
- The headless `pythonapp` with no ingress and Dapr enabled that calls the `nodeapp` service via dapr service-to-service communication.

## Verify the result

### Confirm successful state persistence

You can confirm that the services are working correctly by viewing data in your Azure Storage account.

1. Open the [Azure portal](https://portal.azure.com) in your browser.
1. Navigate to your storage account.
1. Select **Containers** from the menu on the left side.
1. Select **state**.
1. Verify that you can see the file named `order` in the container.
1. Select on the file.
1. Select the **Edit** tab.
1. Select the **Refresh** button to observe updates.

### View Logs

Data logged via a container app are stored in the `ContainerAppConsoleLogs_CL` custom table in the Log Analytics workspace. You can view logs through the Azure portal or from the command line. Wait a few minutes for the analytics to arrive for the first time before you query the logged data.

1. Open the [Azure portal](https://portal.azure.com) in your browser.
1. Navigate to your log analytics workspace.
1. Select **Logs** from the menu on the left side.
1. Run the following Kusto query.

```kql
ContainerAppConsoleLogs_CL 
| project TimeGenerated, ContainerAppName_s, Log_s
| order by TimeGenerated desc
```

The following images shows the type of response to expect from the command.

![Logs](./images/logs.png)

## Clean up resources

Once you are done, run the following command to delete your resource group along with all the resources you created in this tutorial.

```bash
az group delete \
  --resource-group $RESOURCE_GROUP
```

Since `pythonapp` continuously makes calls to `nodeapp` with messages that get persisted into your configured state store, it is important to complete these cleanup steps to avoid ongoing billable operations.

## Next steps

- [Azure Container Apps overview](https://docs.microsoft.com/en-us/azure/container-apps/overview)
- [Tutorial: Deploy a Dapr application to Azure Container Apps with an Azure Resource Manager or Bicep template](https://docs.microsoft.com/en-us/azure/container-apps/microservices-dapr-azure-resource-manager?tabs=bash&pivots=container-apps-bicep)
- [AzAPI provider](https://docs.microsoft.com/en-us/azure/developer/terraform/overview-azapi-provider)
- [Announcing Azure Terrafy and AzAPI Terraform Provider Previews](https://techcommunity.microsoft.com/t5/azure-tools-blog/announcing-azure-terrafy-and-azapi-terraform-provider-previews/ba-p/3270937)
