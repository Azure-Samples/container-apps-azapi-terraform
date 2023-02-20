variable "resource_prefix" {
  description = "Specifies a prefix for all the resource names."
  default     = "Astra"
  type        = string
}

variable "location" {
  description = "(Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  type        = string
  default     = "WestEurope"
}

variable "resource_group_name" {
   description = "Name of the resource group in which the resources will be created"
   default     = "RG"
}

variable "tags" {
  description = "(Optional) Specifies tags for all the resources"
  default     = {
    createdWith = "Terraform"
  }
}

variable "log_analytics_workspace_name" {
  description = "Specifies the name of the log analytics workspace"
  default     = "Workspace"
  type        = string
}

variable "log_analytics_retention_days" {
  description = "Specifies the number of days of the retention policy for the log analytics workspace."
  type        = number
  default     = 30
}

variable "application_insights_name" {
  description = "Specifies the name of the application insights resource."
  default     = "ApplicationInsights"
  type        = string
}

variable "application_insights_application_type" {
  description = "(Required) Specifies the type of Application Insights to create. Valid values are ios for iOS, java for Java web, MobileCenter for App Center, Node.JS for Node.js, other for General, phone for Windows Phone, store for Windows Store and web for ASP.NET. Please note these values are case sensitive; unmatched values are treated as ASP.NET by Azure. Changing this forces a new resource to be created."
  type        = string
  default     = "web"
}

variable "storage_account_name" {
  description = "(Optional) Specifies the name of the storage account"
  default     = "account"
  type        = string
}

variable "storage_account_replication_type" {
  description = "(Optional) Specifies the replication type of the storage account"
  default     = "LRS"
  type        = string

  validation {
    condition = contains(["LRS", "ZRS", "GRS", "GZRS", "RA-GRS", "RA-GZRS"], var.storage_account_replication_type)
    error_message = "The replication type of the storage account is invalid."
  }
}

variable "storage_account_kind" {
  description = "(Optional) Specifies the account kind of the storage account"
  default     = "StorageV2"
  type        = string

   validation {
    condition = contains(["Storage", "StorageV2"], var.storage_account_kind)
    error_message = "The account kind of the storage account is invalid."
  }
}

variable "storage_account_tier" {
  description = "(Optional) Specifies the account tier of the storage account"
  default     = "Standard"
  type        = string

   validation {
    condition = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "The account tier of the storage account is invalid."
  }
}

variable "managed_environment_name" {
  description = "(Required) Specifies the name of the managed environment."
  type        = string
  default     = "ManagedEnvironment"
}

variable "dapr_component_name" {
  description = "(Required) Specifies the name of the dapr component."
  type        = string
  default     = "statestore"
}

variable "dapr_component_type" {
  description = "(Required) Specifies the type of the dapr component."
  type        = string
  default     = "state.azure.blobstorage"
}

variable "dapr_ignore_errors" {
  description = "(Required) Specifies  if the component errors are ignored."
  type        = bool
  default     = false
}

variable "dapr_component_version" {
  description = "(Required) Specifies the version of the dapr component."
  type        = string
  default     = "v1"
}

variable "dapr_component_init_timeout" {
  description = "(Required) Specifies the init timeout of the dapr component."
  type        = string
  default     = "5s"
}

variable "dapr_component_scopes" {
  description = "(Required) Specifies the init timeout of the dapr component."
  type        = list
  default     = ["nodeapp"]
}

variable "container_name" {
  description = "Specifies the name of the container in the storage account."
  type        = string
  default     = "state"
}

variable "container_access_type" {
  description = "Specifies the access type of the container in the storage account."
  type        = string
  default     = "private"
}

variable "container_apps" {
  description = "Specifies the container apps in the managed environment."
  type = list(object({
    name                = string
    configuration       = object({
      ingress           = optional(object({
        external        = optional(bool)
        targetPort      = optional(number)
      }))
      dapr              = optional(object({
        enabled         = optional(bool)
        appId           = optional(string)
        appProtocol     = optional(string)
        appPort         = optional(number)
      }))
    })
    template           = object({
      containers       = list(object({
        image          = string
        name           = string
        env            = optional(list(object({
          name         = string
          value        = string
        })))
        resources      = optional(object({
          cpu          = optional(number)
          memory       = optional(string)
        }))
      }))
      scale            = optional(object({
        minReplicas    = optional(number)
        maxReplicas    = optional(number)
      }))
    })
  }))
  default             = [{
    name              = "nodeapp"
    configuration      = {
      ingress          = {
        external       = false
        targetPort     = 3000
      }
      dapr             = {
        enabled        = true
        appId          = "nodeapp"
        appProtocol    = "http"
        appPort        = 3000
      }
    }
    template          = {
      containers      = [{
        image         = "dapriosamples/hello-k8s-node:latest"
        name          = "hello-k8s-node"
        env           = [{
          name        = "APP_PORT"
          value       = 3000
        }]
        resources     = {
          cpu         = 0.5
          memory      = "1.0Gi"
        }
      }]
      scale           = {
        minReplicas   = 1
        maxReplicas   = 1
      }
    }
  },
  {
    name               = "pythonapp"
    configuration      = {
      dapr             = {
        enabled        = true
        appId          = "pythonapp"
      }
    }
    template          = {
      containers      = [{
        image         = "dapriosamples/hello-k8s-python:latest"
        name          = "hello-k8s-python"
        resources     = {
          cpu         = 0.5
          memory      = "1.0Gi"
        }
      }]
      scale           = {
        minReplicas   = 1
        maxReplicas   = 1
      }
    }
  }]
}