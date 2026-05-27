# ============================================================
# main.tf — ComicRealm (ComicRealmBE + ComicRealmFE + PostgreSQL)
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

resource "kubernetes_secret" "postgres_credentials" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  type = "Opaque"

  data = {
    POSTGRES_DB       = var.postgres_db
    POSTGRES_USER     = var.postgres_user
    POSTGRES_PASSWORD = var.postgres_password

    CONNECTION_STRING = "Host=postgres;Port=5432;Database=${var.postgres_db};Username=${var.postgres_user};Password=${var.postgres_password}"
  }
}

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
}

# ============================================================
# POSTGRES
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
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        security_context {
          run_as_user     = 999
          run_as_group    = 999
          run_as_non_root = true

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name              = "postgres"
          image             = "postgres:17-alpine"
          image_pull_policy = "Always"

          security_context {
            allow_privilege_escalation = false

            capabilities {
              drop = ["ALL", "NET_RAW"]
            }
          }

          port {
            container_port = 5432
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

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user, "-d", var.postgres_db]
            }

            initial_delay_seconds = 10
            period_seconds        = 5
          }

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user, "-d", var.postgres_db]
            }

            initial_delay_seconds = 30
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
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

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

# ============================================================
# BACKEND CONFIG
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

    Cors__AllowedOrigins__0 = "http://${var.minikube_ip}:${var.fe_node_port}"
  }
}

# ============================================================
# BACKEND
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
      match_labels = {
        app = "comicrealmbe"
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
        security_context {
          run_as_non_root = true

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        init_container {
          name              = "wait-for-postgres"
          image             = "postgres:17-alpine"
          image_pull_policy = "Always"

          command = [
            "sh",
            "-c",
            "until pg_isready -h postgres -U ${var.postgres_user}; do echo waiting for postgres; sleep 2; done"
          ]
        }

        container {
          name              = "comicrealmbe"
          image             = "${var.be_image}:${var.image_tag}"
          image_pull_policy = "Always"

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true

            capabilities {
              drop = ["ALL", "NET_RAW"]
            }
          }

          port {
            container_port = 8080
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.be_config.metadata[0].name
            }
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

          readiness_probe {
            http_get {
              path = "/swagger"
              port = 8080
            }

            initial_delay_seconds = 15
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/swagger"
              port = 8080
            }

            initial_delay_seconds = 30
            period_seconds        = 20
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
}

resource "kubernetes_service" "be" {
  metadata {
    name      = "comicrealmbe"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  spec {
    selector = {
      app = "comicrealmbe"
    }

    port {
      port        = 8080
      target_port = 8080
      node_port   = var.be_node_port
    }

    type = "NodePort"
  }
}

# ============================================================
# FRONTEND CONFIG
# ============================================================

resource "kubernetes_config_map" "fe_config" {
  metadata {
    name      = "comicrealmfe-config"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  data = {
    HOST = "0.0.0.0"
    PORT = "5173"
  }
}

# ============================================================
# FRONTEND
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
      match_labels = {
        app = "comicrealmfe"
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
        security_context {
          run_as_non_root = true

          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name              = "comicrealmfe"
          image             = "${var.fe_image}:${var.image_tag}"
          image_pull_policy = "Always"

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true

            capabilities {
              drop = ["ALL", "NET_RAW"]
            }
          }

          port {
            container_port = 5173
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.fe_config.metadata[0].name
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 5173
            }

            initial_delay_seconds = 15
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 5173
            }

            initial_delay_seconds = 30
            period_seconds        = 20
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
        }
      }
    }
  }
}

resource "kubernetes_service" "fe" {
  metadata {
    name      = "comicrealmfe"
    namespace = kubernetes_namespace.comic.metadata[0].name
  }

  spec {
    selector = {
      app = "comicrealmfe"
    }

    port {
      port        = 5173
      target_port = 5173
      node_port   = var.fe_node_port
    }

    type = "NodePort"
  }
}