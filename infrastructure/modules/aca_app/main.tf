variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "container_app_environment_id" {
  type = string
}

variable "identity_id" {
  type = string
}

variable "image" {
  type = string
}

variable "container_port" {
  type    = number
  default = 80
}

variable "is_external_ingress" {
  type    = bool
  default = false
}

variable "ingress_enabled" {
  type    = bool
  default = true
}

variable "env_vars" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "cpu" {
  type    = number
  default = 0.25
}

variable "memory" {
  type    = string
  default = "0.5Gi"
}

variable "min_replicas" {
  type    = number
  default = 1
}

variable "max_replicas" {
  type    = number
  default = 5
}

variable "tags" {
  type = map(string)
}

resource "azurerm_container_app" "main" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  registry {
    server   = split("/", var.image)[0]
    identity = var.identity_id
  }

  dynamic "secret" {
    for_each = { for s in var.secrets : s.name => s.value }
    content {
      name  = secret.key
      value = secret.value
    }
  }

  template {
    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      dynamic "env" {
        for_each = var.secrets
        content {
          name        = env.value.name
          secret_name = env.value.name
        }
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  dynamic "ingress" {
    for_each = var.ingress_enabled ? [1] : []
    content {
      allow_insecure_connections = false
      external_enabled           = var.is_external_ingress
      target_port                = var.container_port
      traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

output "id" {
  value = azurerm_container_app.main.id
}

output "fqdn" {
  value = var.ingress_enabled ? azurerm_container_app.main.ingress[0].fqdn : null
}
