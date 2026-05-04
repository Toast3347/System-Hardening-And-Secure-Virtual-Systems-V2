# ============================================================
# main.tf — ComicRealm (ComicRealmBE + ComicRealmFE + PostgreSQL)
# ============================================================
# Services in your docker-compose → what they become here:
#   postgres          → Deployment + Service + PVC + Secret
#   comicrealm-migrate → Kubernetes Job
#   comicrealm-seed   → Kubernetes Job (depends on migrate)
#   comicrealmbe      → Deployment + Service
#   comicrealmfe      → Deployment + Service
# ============================================================

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
  }
  required_version = ">= 1.6.0"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kube_context
}

# ============================================================
# NAMESPACE
# Each environment (dev/test/prod) gets its own isolated namespace.
# ============================================================
resource "kubernetes_namespace" "comic" {
  metadata {
    name = var.namespace
    labels = {
      app         = "comicrealm"
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

# ============================================================
# SECRET — PostgreSQL credentials
# Stored as a Kubernetes Secret so the password is never in
# plain-text ConfigMaps or environment variables in your .tf files.
# Both Postgres and the BE reference this same Secret.
# ============================================================
resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  type = "Opaque"

  data = {
    # These values come from your *.tfvars files (not hardcoded here).
    POSTGRES_DB       = var.postgres_db
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password

    # Full connection string for ASP.NET — matches your appsettings.json format.
    # "postgres" is the Kubernetes Service name defined below.
    CONNECTION_STRING = "Host=postgres;Port=5432;Database=${var.postgres_db};Username=${var.postgres_user};Password=${var.postgres_password}"
  }
}

# ============================================================
# POSTGRES — PersistentVolumeClaim
# Keeps your database data alive across pod restarts.
# Without this, every pod restart wipes the database.
# ============================================================
resource "kubernetes_persistent_volume_claim" "postgres_data" {
  metadata {
    name      = "postgres-data"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.postgres_storage
      }
    }
  }

  # Don't destroy the PVC when running terraform destroy — protects your data.
  lifecycle {
    prevent_destroy = false # Set to true in prod once you have real data.
  }
}

# ============================================================
# POSTGRES — Deployment
# ============================================================
resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.comic.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1 # Postgres must always be 1 replica (not safe to scale without clustering).

    selector {
      match_labels = { app = "postgres" }
    }

    strategy {
      type = "Recreate" # Recreate (not RollingUpdate) because PVC is ReadWriteOnce.
    }

    template {
      metadata {
        labels = { app = "postgres" }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:17-alpine"
          image_pull_policy = "IfNotPresent"

          port { container_port = 5432 }

          # Inject credentials from the Secret as environment variables.
          # This matches what postgres:17-alpine reads on startup.
          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }
          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }

          # Readiness probe — the migrate Job waits until this passes.
          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user, "-d", var.postgres_db]
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            failure_threshold     = 10
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user, "-d", var.postgres_db]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          resources {
            requests = { cpu = "100m", memory = "128Mi" }
            limits   = { cpu = "500m", memory = "512Mi" }
          }
        }

        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_data.metadata[0].name
          }
        }
      }
    }
  }
}

# ============================================================
# POSTGRES — Service (internal ClusterIP)
# Other pods reach Postgres at hostname "postgres" port 5432.
# This matches the Host=postgres in your connection string.
# ============================================================
resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  spec {
    selector = { app = "postgres" }
    port {
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP" # Internal only — Postgres is never exposed outside the cluster.
  }
}

# ============================================================
# MIGRATE JOB
# Replaces the comicrealm-migrate docker-compose service.
# Runs "dotnet ComicRealmBE.dll --migrate-only" once and exits.
# The BE Deployment uses an initContainer that waits for this Job.
#
# IMPORTANT: Kubernetes Jobs are not re-run on terraform apply.
# Delete the Job manually if you need to re-run migrations:
#   kubectl delete job comicrealm-migrate -n <namespace>
# ============================================================
resource "kubernetes_job" "migrate" {
  metadata {
    name      = "comicrealm-migrate"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  spec {
    template {
      metadata {
        labels = { app = "comicrealm-migrate" }
      }

      spec {
        restart_policy = "OnFailure"

        # Wait for Postgres to be ready before running migrations.
        init_container {
          name  = "wait-for-postgres"
          image = "postgres:17-alpine"
          image_pull_policy = "IfNotPresent"
          command = [
            "sh", "-c",
            "until pg_isready -h postgres -U ${var.postgres_user}; do echo waiting for postgres; sleep 2; done"
          ]
        }

        container {
          name  = "migrate"
          image = "${var.be_image}:${var.image_tag}"
          image_pull_policy = "Never" # Use image built locally into Minikube.

          command = ["dotnet", "ComicRealmBE.dll", "--migrate-only"]

          env {
            name  = "ASPNETCORE_ENVIRONMENT"
            value = var.aspnet_environment
          }
          env {
            name = "ConnectionStrings__DefaultConnection"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "CONNECTION_STRING"
              }
            }
          }
        }
      }
    }

    backoff_limit = 4
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
  }
}

# ============================================================
# SEED JOB
# Replaces the comicrealm-seed docker-compose service.
# Runs seed-db.sql against Postgres after migrations complete.
#
# Your seed SQL uses \copy to load comic_digital.csv.
# For Kubernetes we use the SQL-only approach (the CSV import
# via \copy requires the file to be in the pod — see README).
# ============================================================
resource "kubernetes_job" "seed" {
  metadata {
    name      = "comicrealm-seed"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  spec {
    template {
      metadata {
        labels = { app = "comicrealm-seed" }
      }

      spec {
        restart_policy = "OnFailure"

        # Wait for the migrate Job to complete before seeding.
        init_container {
          name  = "wait-for-migrate"
          image = "postgres:17-alpine"
          image_pull_policy = "IfNotPresent"
          command = [
            "sh", "-c",
            "until pg_isready -h postgres -U ${var.postgres_user}; do sleep 2; done"
          ]
        }

        container {
          name  = "seed"
          image = "postgres:17-alpine"
          image_pull_policy = "IfNotPresent"

          # Run only the user seed (INSERT statements — no \copy CSV import).
          # To also seed comics from CSV, use the README instructions.
          command = [
            "sh", "-c", <<-EOT
              PGPASSWORD=$POSTGRES_PASSWORD psql \
                -h postgres \
                -U $POSTGRES_USER \
                -d $POSTGRES_DB \
                -c "INSERT INTO users (email, password_hash, role, created_by, created_at, updated_at, is_active) SELECT 'superadmin@comicrealm.com', 'AQAAAAIAAYagAAAAELsSL5L3Gjqz5rFN/f2hGAeDye0+NrpdcCqPEgwpLRNlM1YWPwsr/5fkUJF9YpMbMg==', 0, NULL, NOW(), NOW(), true WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'superadmin@comicrealm.com');" \
                -c "INSERT INTO users (email, password_hash, role, created_by, created_at, updated_at, is_active) SELECT 'admin@comicrealm.com', 'AQAAAAIAAYagAAAAEIfUODokghnrLkzTCQOywjCFM1/f7s0B64DER2HNdl7dkLpVkEc1UOSAELOLDSXqtw==', 1, NULL, NOW(), NOW(), true WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@comicrealm.com');" \
                -c "INSERT INTO users (email, password_hash, role, created_by, created_at, updated_at, is_active) SELECT 'friend@comicrealm.com', 'AQAAAAIAAYagAAAAEIqeLBWYppTtuHBMub/pEiVXaxwZVSZA9BocEdxdfQl/FKSdOBVpkLuCJ9q8E4BVOQ==', 2, NULL, NOW(), NOW(), true WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'friend@comicrealm.com');"
            EOT
          ]

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }
          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
          env {
            name = "POSTGRES_DB"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "POSTGRES_DB"
              }
            }
          }
        }
      }
    }

    backoff_limit = 4
  }

  depends_on = [kubernetes_job.migrate]

  wait_for_completion = true

  timeouts {
    create = "3m"
  }
}

# ============================================================
# BACKEND (ComicRealmBE) — ConfigMap
# Non-secret config values injected into the BE pods.
# ============================================================
resource "kubernetes_config_map" "be_config" {
  metadata {
    name      = "comicrealmbe-config"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  data = {
    ASPNETCORE_ENVIRONMENT = var.aspnet_environment
    ASPNETCORE_URLS        = "http://+:8080"
    Jwt__Key               = var.jwt_key
    Jwt__Issuer            = "ComicRealm"
    Jwt__Audience          = "ComicRealm"
    # CORS: allow FE running on the NodePort.
    # Computed from minikube_ip + fe_node_port.
    Cors__AllowedOrigins__0 = "http://${var.minikube_ip}:${var.fe_node_port}"
  }
}

# ============================================================
# BACKEND (ComicRealmBE) — Deployment
# ============================================================
resource "kubernetes_deployment" "be" {
  metadata {
    name      = "comicrealmbe"
    namespace = kubernetes_namespace.comic.metadata[0].name
    labels = {
      app         = "comicrealmbe"
      environment = var.environment
    }
  }

  spec {
    replicas = var.be_replicas

    selector {
      match_labels = { app = "comicrealmbe" }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
    }

    template {
      metadata {
        labels = {
          app         = "comicrealmbe"
          environment = var.environment
        }
      }

      spec {
        # Wait for Postgres to be ready before the BE starts.
        init_container {
          name  = "wait-for-postgres"
          image = "postgres:17-alpine"
          image_pull_policy = "IfNotPresent"
          command = [
            "sh", "-c",
            "until pg_isready -h postgres -U ${var.postgres_user}; do echo waiting for postgres; sleep 2; done"
          ]
        }

        container {
          name              = "comicrealmbe"
          image             = "${var.be_image}:${var.image_tag}"
          image_pull_policy = "Never"

          port { container_port = 8080 }

          # Load all non-secret config from ConfigMap.
          env_from {
            config_map_ref {
              name = kubernetes_config_map.be_config.metadata[0].name
            }
          }

          # Load the DB connection string from the Secret.
          env {
            name = "ConnectionStrings__DefaultConnection"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres_credentials.metadata[0].name
                key  = "CONNECTION_STRING"
              }
            }
          }

          resources {
            requests = {
              cpu    = var.be_cpu_request
              memory = var.be_memory_request
            }
            limits = {
              cpu    = var.be_cpu_limit
              memory = var.be_memory_limit
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_job.migrate,
    kubernetes_job.seed,
  ]

  wait_for_rollout = true
}

# ============================================================
# BACKEND — Service (NodePort)
# Exposed outside the cluster so the FE (and your browser) can reach it.
# ============================================================
resource "kubernetes_service" "be" {
  metadata {
    name      = "comicrealmbe"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  spec {
    selector = { app = "comicrealmbe" }
    port {
      port        = 8080
      target_port = 8080
      node_port   = var.be_node_port
    }
    type = "NodePort"
  }
}

# ============================================================
# FRONTEND (ComicRealmFE) — ConfigMap
# VITE_API_BASE_URL is baked in at image build time, not here.
# This ConfigMap holds any runtime env vars the FE container needs.
# ============================================================
resource "kubernetes_config_map" "fe_config" {
  metadata {
    name      = "comicrealmfe-config"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  data = {
    # Vite dev server host binding.
    HOST = "0.0.0.0"
    PORT = "5173"
  }
}

# ============================================================
# FRONTEND (ComicRealmFE) — Deployment
# ============================================================
resource "kubernetes_deployment" "fe" {
  metadata {
    name      = "comicrealmfe"
    namespace = kubernetes_namespace.comic.metadata[0].name
    labels = {
      app         = "comicrealmfe"
      environment = var.environment
    }
  }

  spec {
    replicas = var.fe_replicas

    selector {
      match_labels = { app = "comicrealmfe" }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "0"
      }
    }

    template {
      metadata {
        labels = {
          app         = "comicrealmfe"
          environment = var.environment
        }
      }

      spec {
        container {
          name              = "comicrealmfe"
          image             = "${var.fe_image}:${var.image_tag}"
          image_pull_policy = "Never"

          port { container_port = 5173 }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.fe_config.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = var.fe_cpu_request
              memory = var.fe_memory_request
            }
            limits = {
              cpu    = var.fe_cpu_limit
              memory = var.fe_memory_limit
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 5173
            }
            initial_delay_seconds = 15
            period_seconds        = 10
            failure_threshold     = 6
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 5173
            }
            initial_delay_seconds = 30
            period_seconds        = 20
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment.be]

  wait_for_rollout = true
}

# ============================================================
# FRONTEND — Service (NodePort)
# ============================================================
resource "kubernetes_service" "fe" {
  metadata {
    name      = "comicrealmfe"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  spec {
    selector = { app = "comicrealmfe" }
    port {
      port        = 5173
      target_port = 5173
      node_port   = var.fe_node_port
    }
    type = "NodePort"
  }
}
