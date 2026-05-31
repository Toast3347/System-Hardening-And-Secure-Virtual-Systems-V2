variable "use_oidc" {
  description = "Authenticate the azurerm provider using OIDC (recommended for GitHub Actions)."
  type        = bool
  default     = true
}

variable "project" {
  description = "Short name used as a prefix for all resources. Must match the backend module."
  type        = string
  default     = "comicrealm"
}

variable "environment" {
  description = "Deployment environment. Must match the backend module."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region. Must match the backend module."
  type        = string
  default     = "westeurope"
}

variable "backend_resource_group_name" {
  description = "Resource group created by the backend module (looked up via data source)."
  type        = string
  default     = null
}

variable "backend_container_app_name" {
  description = "Name of the backend Container App (used to build VITE_API_BASE_URL automatically)."
  type        = string
  default     = null
}

variable "vite_api_base_url_override" {
  description = "Optional override for VITE_API_BASE_URL. If null, it is derived from the backend Container App FQDN + '/api'."
  type        = string
  default     = null
}

variable "container_image" {
  description = "Fully qualified frontend image. If null, a placeholder is used so the Container App can be created before the first build."
  type        = string
  default     = null
}

variable "image_tag" {
  description = "Tag pushed by CI. Combined with the shared ACR to compute the default image reference."
  type        = string
  default     = "latest"
}

variable "container_cpu" {
  description = "vCPU allocated to the FE container."
  type        = number
  default     = 0.25
}

variable "container_memory" {
  description = "Memory allocated to the FE container."
  type        = string
  default     = "0.5Gi"
}

variable "min_replicas" {
  description = "Minimum number of FE replicas."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of FE replicas."
  type        = number
  default     = 3
}

variable "target_port" {
  description = "Port the FE container listens on."
  type        = number
  default     = 5173
}

variable "tags" {
  description = "Tags applied to Azure resources. Unused on minikube."
  type        = map(string)
  default = {
    project = "comicrealm"
    managed = "terraform"
  }
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

variable "frontend_image" {
  description = "Image reference for the FE Deployment. Build inside the minikube docker daemon and reference by tag, e.g. 'comicrealm-frontend:local'."
  type        = string
  default     = "comicrealm-frontend:local"
}

variable "image_pull_policy" {
  description = "imagePullPolicy for the FE container. Use 'Never' or 'IfNotPresent' for images built inside the minikube docker daemon."
  type        = string
  default     = "IfNotPresent"
}

variable "frontend_node_port" {
  description = "NodePort exposing the frontend on the minikube VM (30000-32767). Set null to let Kubernetes pick."
  type        = number
  default     = 30173
}
