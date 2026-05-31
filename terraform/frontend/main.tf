# =============================================================================
# Local minikube deployment of the ComicRealm frontend (Vue/Vite).
# Reuses the namespace created by the backend module (looked up via data).
# The original Azure resources are preserved below in a block comment.
# =============================================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  labels = {
    "app.kubernetes.io/part-of"    = var.project
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

# Look up the namespace + backend Service created by the backend module.
data "kubernetes_namespace_v1" "backend" {
  metadata {
    name = local.name_prefix
  }
}

data "kubernetes_service_v1" "backend" {
  metadata {
    name      = "${local.name_prefix}-be"
    namespace = data.kubernetes_namespace_v1.backend.metadata[0].name
  }
}

locals {
  # Inside the cluster, FE talks to BE via the in-cluster Service DNS.
  api_base_url = coalesce(
    var.vite_api_base_url_override,
    "http://${data.kubernetes_service_v1.backend.metadata[0].name}.${data.kubernetes_namespace_v1.backend.metadata[0].name}.svc.cluster.local:8080/api",
  )
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "${local.name_prefix}-fe"
    namespace = data.kubernetes_namespace_v1.backend.metadata[0].name
    labels    = merge(local.labels, { "app.kubernetes.io/name" = "frontend" })
  }

  spec {
    replicas = var.min_replicas

    selector {
      match_labels = { "app.kubernetes.io/name" = "frontend" }
    }

    template {
      metadata {
        labels = merge(local.labels, { "app.kubernetes.io/name" = "frontend" })
      }

      spec {
        container {
          name              = "frontend"
          image             = var.frontend_image
          image_pull_policy = var.image_pull_policy

          port {
            container_port = var.target_port
            name           = "http"
          }

          env {
            name  = "VITE_API_BASE_URL"
            value = local.api_base_url
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [spec[0].template[0].spec[0].container[0].image]
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name      = "${local.name_prefix}-fe"
    namespace = data.kubernetes_namespace_v1.backend.metadata[0].name
    labels    = merge(local.labels, { "app.kubernetes.io/name" = "frontend" })
  }

  spec {
    selector = { "app.kubernetes.io/name" = "frontend" }
    port {
      name        = "http"
      port        = var.target_port
      target_port = var.target_port
      node_port   = var.frontend_node_port
    }
    type = "NodePort"
  }
}


# =============================================================================
# AZURE RESOURCES (commented out for local minikube testing)
# =============================================================================
/*
locals {
  # name_prefix                 = "${var.project}-${var.environment}"
  backend_resource_group_name = coalesce(var.backend_resource_group_name, "${local.name_prefix}-rg")
  backend_container_app_name  = coalesce(var.backend_container_app_name, "${local.name_prefix}-be")
}

data "azurerm_resource_group" "backend" {
  name = local.backend_resource_group_name
}

data "azurerm_container_app_environment" "shared" {
  name                = "${local.name_prefix}-cae"
  resource_group_name = data.azurerm_resource_group.backend.name
}

data "azurerm_container_registry" "shared" {
  name                = one([for r in data.azurerm_resources.acr.resources : r.name])
  resource_group_name = data.azurerm_resource_group.backend.name
}

data "azurerm_resources" "acr" {
  resource_group_name = data.azurerm_resource_group.backend.name
  type                = "Microsoft.ContainerRegistry/registries"
}

data "azurerm_container_app" "backend" {
  name                = local.backend_container_app_name
  resource_group_name = data.azurerm_resource_group.backend.name
}

locals {
  api_base_url = coalesce(
    var.vite_api_base_url_override,
    "https://${data.azurerm_container_app.backend.latest_revision_fqdn}/api",
  )

  effective_image = coalesce(
    var.container_image,
    "${data.azurerm_container_registry.shared.login_server}/${var.project}-frontend:${var.image_tag}",
  )
}

resource "azurerm_user_assigned_identity" "frontend" {
  name                = "${local.name_prefix}-fe-id"
  location            = data.azurerm_resource_group.backend.location
  resource_group_name = data.azurerm_resource_group.backend.name
  tags                = var.tags
}

resource "azurerm_role_assignment" "frontend_acr_pull" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.frontend.principal_id
}

resource "azurerm_container_app" "frontend" {
  name                         = "${local.name_prefix}-fe"
  container_app_environment_id = data.azurerm_container_app_environment.shared.id
  resource_group_name          = data.azurerm_resource_group.backend.name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.frontend.id]
  }

  registry {
    server   = data.azurerm_container_registry.shared.login_server
    identity = azurerm_user_assigned_identity.frontend.id
  }

  ingress {
    external_enabled = true
    target_port      = var.target_port
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "frontend"
      image  = local.effective_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "VITE_API_BASE_URL"
        value = local.api_base_url
      }
    }
  }

  depends_on = [azurerm_role_assignment.frontend_acr_pull]

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}
*/
