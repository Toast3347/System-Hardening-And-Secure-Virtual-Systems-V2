variable "use_oidc" {
  description = "Authenticate the azurerm provider using OIDC (recommended for GitHub Actions)."
  type        = bool
  default     = true
}

variable "project" {
  description = "Short name used as a prefix for all resources."
  type        = string
  default     = "comicrealm"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod). Used in resource names."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all backend resources."
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group for the backend stack. Created if it does not exist."
  type        = string
  default     = null
}

variable "container_image" {
  description = "Fully qualified backend image, e.g. <acr>.azurecr.io/comicrealm-backend:<tag>. If null, a placeholder image is used so the Container App can be created before the first build."
  type        = string
  default     = null
}

variable "image_tag" {
  description = "Tag pushed by CI. Used together with the ACR created here to compute the default image reference."
  type        = string
  default     = "latest"
}

variable "container_cpu" {
  description = "vCPU allocated to the BE container."
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory allocated to the BE container (e.g. 1.0Gi)."
  type        = string
  default     = "1.0Gi"
}

variable "min_replicas" {
  description = "Minimum number of BE replicas."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of BE replicas."
  type        = number
  default     = 3
}

variable "aspnetcore_environment" {
  description = "Value of ASPNETCORE_ENVIRONMENT injected into the BE container."
  type        = string
  default     = "Production"
}

variable "jwt_signing_key" {
  description = "JWT signing key consumed by AuthService. Inject via TF_VAR_jwt_signing_key or a secret-managed tfvars file; no default is provided."
  type        = string
  sensitive   = true
  default     = null
  validation {
    condition     = var.jwt_signing_key != null && length(var.jwt_signing_key) >= 32
    error_message = "jwt_signing_key must be supplied (>=32 chars). Use TF_VAR_jwt_signing_key sourced from your secret store."
  }
}

variable "postgres_admin_username" {
  description = "Administrator username for Postgres Flexible Server."
  type        = string
  default     = "comicrealm"
}

variable "postgres_admin_password" {
  description = "Administrator password for Postgres. Inject via TF_VAR_postgres_admin_password from your secret store; no default is provided."
  type        = string
  sensitive   = true
  default     = null
  validation {
    condition     = var.postgres_admin_password != null && length(var.postgres_admin_password) >= 12
    error_message = "postgres_admin_password must be supplied (>=12 chars). Use TF_VAR_postgres_admin_password sourced from your secret store."
  }
}

variable "postgres_database_name" {
  description = "Application database name."
  type        = string
  default     = "comicrealm"
}

variable "postgres_sku_name" {
  description = "Postgres Flexible Server SKU."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "Postgres Flexible Server storage in MB."
  type        = number
  default     = 32768
}

variable "postgres_version" {
  description = "Postgres major version."
  type        = string
  default     = "16"
}

variable "allowed_cors_origins" {
  description = "Additional CORS origins to allow in addition to the deployed FE."
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Minikube / local kubernetes variables
# -----------------------------------------------------------------------------

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file the kubernetes provider should use."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "kubeconfig context to target (e.g. 'minikube')."
  type        = string
  default     = "minikube"
}

variable "backend_image" {
  description = "Image reference for the BE Deployment. Build inside the minikube daemon (eval $(minikube -p minikube docker-env)) and reference by tag, e.g. 'comicrealm-backend:local'."
  type        = string
  default     = "comicrealm-backend:local"
}

variable "image_pull_policy" {
  description = "imagePullPolicy for the BE container. Use 'Never' or 'IfNotPresent' when the image lives only in the minikube docker daemon."
  type        = string
  default     = "IfNotPresent"
}

variable "backend_node_port" {
  description = "NodePort exposing the backend on the minikube VM (30000-32767). Set null to let Kubernetes pick."
  type        = number
  default     = 30053
}

variable "postgres_storage_size" {
  description = "Persistent volume claim size for Postgres in-cluster."
  type        = string
  default     = "2Gi"
}

variable "tags" {
  description = "Tags applied to Azure resources. Unused on minikube."
  type        = map(string)
  default = {
    project = "comicrealm"
    managed = "terraform"
  }
}
