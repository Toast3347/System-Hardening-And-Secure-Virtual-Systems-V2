# ============================================================
# variables.tf — ComicRealm
# ============================================================
# Declares every input. Values come from envs/*.tfvars.
# ============================================================

# ----------------------------------------------------------
# Environment identity
# ----------------------------------------------------------

variable "kube_context" {
  description = "kubectl context to use. Run 'kubectl config get-contexts' to list."
  type        = string
  default     = "minikube"
}

variable "environment" {
  description = "Deployment environment: dev, test, or prod."
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "namespace" {
  description = "Kubernetes namespace. Each environment gets its own (comic-dev, comic-test, comic-prod)."
  type        = string
}

variable "minikube_ip" {
  description = "IP returned by 'minikube ip'. Used to build CORS allowed origin and output URLs."
  type        = string
  default     = "192.168.49.2"
}

# ----------------------------------------------------------
# PostgreSQL
# ----------------------------------------------------------

variable "postgres_db" {
  description = "PostgreSQL database name."
  type        = string
  default     = "comicrealm"
}

variable "postgres_user" {
  description = "PostgreSQL username."
  type        = string
  default     = "comicrealm"
}

variable "postgres_password" {
  description = "PostgreSQL password. Never commit the real value — override in tfvars and keep tfvars out of git."
  type        = string
  sensitive   = true
}

variable "postgres_storage" {
  description = "Size of the PersistentVolumeClaim for Postgres data."
  type        = string
  default     = "1Gi"
}

# ----------------------------------------------------------
# Container images
# ----------------------------------------------------------

variable "be_image" {
  description = "Backend image name (without tag). Built with: docker build -t <name>:<tag> ./ComicRealmBE"
  type        = string
  default     = "comicrealmbe"
}

variable "fe_image" {
  description = "Frontend image name (without tag). Built with: docker build -t <name>:<tag> ./ComicRealmFE"
  type        = string
  default     = "comicrealmfe"
}

variable "image_tag" {
  description = "Tag for both images. Use 'dev' locally, pin to a SHA or version in prod."
  type        = string
  default     = "dev"
}

# ----------------------------------------------------------
# ASP.NET / JWT
# ----------------------------------------------------------

variable "aspnet_environment" {
  description = "ASPNETCORE_ENVIRONMENT value. Controls which appsettings file is loaded."
  type        = string
  default     = "Development"
  validation {
    condition     = contains(["Development", "Staging", "Production"], var.aspnet_environment)
    error_message = "aspnet_environment must be Development, Staging, or Production."
  }
}

variable "jwt_key" {
  description = "JWT signing key. Must be at least 32 characters. Keep secret."
  type        = string
  sensitive   = true
  default     = "superSecretKey_must_be_long_enough_for_hmacsha256@123456"
}

# ----------------------------------------------------------
# Backend scaling and resources
# ----------------------------------------------------------

variable "be_replicas" {
  description = "Number of ComicRealmBE pod replicas."
  type        = number
  default     = 1
  validation {
    condition     = var.be_replicas >= 1
    error_message = "be_replicas must be at least 1."
  }
}

variable "be_cpu_request" {
  description = "CPU guaranteed for each BE pod. Format: '100m' = 0.1 core."
  type        = string
  default     = "100m"
}

variable "be_cpu_limit" {
  description = "CPU hard ceiling per BE pod."
  type        = string
  default     = "500m"
}

variable "be_memory_request" {
  description = "Memory guaranteed for each BE pod."
  type        = string
  default     = "128Mi"
}

variable "be_memory_limit" {
  description = "Memory hard ceiling per BE pod. .NET needs at least 128Mi."
  type        = string
  default     = "256Mi"
}

variable "be_node_port" {
  description = "NodePort for the BE service (30000-32767). Access via http://<minikube_ip>:<be_node_port>"
  type        = number
  validation {
    condition     = var.be_node_port >= 30000 && var.be_node_port <= 32767
    error_message = "be_node_port must be in the range 30000-32767."
  }
}

# ----------------------------------------------------------
# Frontend scaling and resources
# ----------------------------------------------------------

variable "fe_replicas" {
  description = "Number of ComicRealmFE pod replicas."
  type        = number
  default     = 1
  validation {
    condition     = var.fe_replicas >= 1
    error_message = "fe_replicas must be at least 1."
  }
}

variable "fe_cpu_request" {
  description = "CPU guaranteed for each FE pod."
  type        = string
  default     = "50m"
}

variable "fe_cpu_limit" {
  description = "CPU hard ceiling per FE pod."
  type        = string
  default     = "200m"
}

variable "fe_memory_request" {
  description = "Memory guaranteed for each FE pod."
  type        = string
  default     = "128Mi"
}

variable "fe_memory_limit" {
  description = "Memory hard ceiling per FE pod."
  type        = string
  default     = "256Mi"
}

variable "fe_node_port" {
  description = "NodePort for the FE service (30000-32767). Open http://<minikube_ip>:<fe_node_port> in browser."
  type        = number
  validation {
    condition     = var.fe_node_port >= 30000 && var.fe_node_port <= 32767
    error_message = "fe_node_port must be in the range 30000-32767."
  }
}
