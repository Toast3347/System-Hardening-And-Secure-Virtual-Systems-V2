output "registry" {
  value       = "ghcr.io"
  description = "Container registry hostname used by the pipeline."
}

output "ghcr_namespace" {
  value       = local.ghcr_namespace
  description = "Image namespace, e.g. ghcr.io/<owner>."
}

output "backend_image" {
  value       = local.images.backend
  description = "Fully-qualified GHCR image name for the backend (without tag)."
}

output "frontend_image" {
  value       = local.images.frontend
  description = "Fully-qualified GHCR image name for the frontend (without tag)."
}

output "environments" {
  value       = [for e in github_repository_environment.env : e.environment]
  description = "GitHub Environments managed by this module."
}
