# =============================================================================
# Local minikube deployment of the ComicRealm backend (Postgres + .NET API).
# The original Azure resources are preserved below in a block comment so they
# can be re-enabled later by uncommenting them (and the provider in versions.tf).
# =============================================================================

locals {
  name_prefix = "${var.project}-${var.environment}"
  labels = {
    "app.kubernetes.io/part-of"    = var.project
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

resource "kubernetes_namespace" "this" {
  metadata {
    name   = local.name_prefix
    labels = local.labels
  }
}

# --- Postgres -----------------------------------------------------------------

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
  }

  data = {
    POSTGRES_DB       = var.postgres_database_name
    POSTGRES_USER     = var.postgres_admin_username
    POSTGRES_PASSWORD = var.postgres_admin_password
  }
}

resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgres-data"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.postgres_storage_size
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = merge(local.labels, { "app.kubernetes.io/name" = "postgres" })
  }

  spec {
    replicas = 1

    selector {
      match_labels = { "app.kubernetes.io/name" = "postgres" }
    }

    template {
      metadata {
        labels = merge(local.labels, { "app.kubernetes.io/name" = "postgres" })
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:17-alpine"

          port {
            container_port = 5432
            name           = "postgres"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.postgres.metadata[0].name
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_admin_username, "-d", var.postgres_database_name]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
  }

  spec {
    selector = { "app.kubernetes.io/name" = "postgres" }
    port {
      name        = "postgres"
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP"
  }
}

# --- Backend (.NET API) -------------------------------------------------------

locals {
  connection_string = format(
    "Host=%s.%s.svc.cluster.local;Port=5432;Database=%s;Username=%s;Password=%s",
    kubernetes_service.postgres.metadata[0].name,
    kubernetes_namespace.this.metadata[0].name,
    var.postgres_database_name,
    var.postgres_admin_username,
    var.postgres_admin_password,
  )
}

resource "kubernetes_secret" "backend" {
  metadata {
    name      = "backend-secrets"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = local.labels
  }

  data = {
    "ConnectionStrings__DefaultConnection" = local.connection_string
    "Jwt__SigningKey"                      = var.jwt_signing_key
  }
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "${local.name_prefix}-be"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = merge(local.labels, { "app.kubernetes.io/name" = "backend" })
  }

  spec {
    replicas = var.min_replicas

    selector {
      match_labels = { "app.kubernetes.io/name" = "backend" }
    }

    template {
      metadata {
        labels = merge(local.labels, { "app.kubernetes.io/name" = "backend" })
      }

      spec {
        container {
          name              = "backend"
          image             = var.backend_image
          image_pull_policy = var.image_pull_policy

          port {
            container_port = 8080
            name           = "http"
          }

          env {
            name  = "ASPNETCORE_ENVIRONMENT"
            value = var.aspnetcore_environment
          }

          env {
            name  = "ASPNETCORE_URLS"
            value = "http://+:8080"
          }

          # .NET binds string[] only from indexed env vars
          # (Cors__AllowedOrigins__0, __1, ...). A single comma-separated
          # value binds to null and the BE falls back to its hardcoded default.
          dynamic "env" {
            for_each = { for i, origin in var.allowed_cors_origins : i => origin }
            content {
              name  = "Cors__AllowedOrigins__${env.key}"
              value = env.value
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.backend.metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.postgres]

  lifecycle {
    ignore_changes = [spec[0].template[0].spec[0].container[0].image]
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name      = "${local.name_prefix}-be"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = merge(local.labels, { "app.kubernetes.io/name" = "backend" })
  }

  spec {
    selector = { "app.kubernetes.io/name" = "backend" }
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      node_port   = var.backend_node_port
    }
    type = "NodePort"
  }
}


# =============================================================================
# AZURE RESOURCES (commented out for local minikube testing)
# =============================================================================
/*
locals {
  # name_prefix         = "${var.project}-${var.environment}"
  resource_group_name = coalesce(var.resource_group_name, "${local.name_prefix}-rg")
  # ACR names must be globally unique, lowercase, 5-50 alphanumeric chars.
  acr_name = "${replace(local.name_prefix, "-", "")}acr${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
  numeric = true
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.name_prefix}-law"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_container_registry" "this" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

resource "azurerm_container_app_environment" "this" {
  name                       = "${local.name_prefix}-cae"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  tags                       = var.tags
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                          = "${local.name_prefix}-pg"
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  version                       = var.postgres_version
  administrator_login           = var.postgres_admin_username
  administrator_password        = var.postgres_admin_password
  sku_name                      = var.postgres_sku_name
  storage_mb                    = var.postgres_storage_mb
  zone                          = "1"
  public_network_access_enabled = true
  tags                          = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "AllowAllAzureServices"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_user_assigned_identity" "backend" {
  name                = "${local.name_prefix}-be-id"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_role_assignment" "backend_acr_pull" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
}

locals {
  connection_string = format(
    "Host=%s;Port=5432;Database=%s;Username=%s;Password=%s;SSL Mode=Require;Trust Server Certificate=true",
    azurerm_postgresql_flexible_server.this.fqdn,
    azurerm_postgresql_flexible_server_database.this.name,
    var.postgres_admin_username,
    var.postgres_admin_password,
  )

  effective_image = coalesce(
    var.container_image,
    "${azurerm_container_registry.this.login_server}/${var.project}-backend:${var.image_tag}",
  )
}

resource "azurerm_container_app" "backend" {
  name                         = "${local.name_prefix}-be"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = azurerm_resource_group.this.name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.backend.id]
  }

  registry {
    server   = azurerm_container_registry.this.login_server
    identity = azurerm_user_assigned_identity.backend.id
  }

  secret {
    name  = "connection-string"
    value = local.connection_string
  }

  secret {
    name  = "jwt-signing-key"
    value = var.jwt_signing_key
  }

  ingress {
    external_enabled = true
    target_port      = 8080
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
      name   = "backend"
      image  = local.effective_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = var.aspnetcore_environment
      }

      env {
        name  = "ASPNETCORE_URLS"
        value = "http://+:8080"
      }

      env {
        name        = "ConnectionStrings__DefaultConnection"
        secret_name = "connection-string"
      }

      env {
        name        = "Jwt__SigningKey"
        secret_name = "jwt-signing-key"
      }

      env {
        name  = "Cors__AllowedOrigins"
        value = join(",", var.allowed_cors_origins)
      }
    }
  }

  depends_on = [azurerm_role_assignment.backend_acr_pull]

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}
*/
