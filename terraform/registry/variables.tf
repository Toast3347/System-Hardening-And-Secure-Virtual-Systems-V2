variable "github_owner" {
  description = "GitHub user or org that owns the repository hosting the GHCR packages."
  type        = string
}

variable "github_repository" {
  description = "Repository name (without owner) where the workflows live and where GHCR packages are scoped."
  type        = string
  default     = "System-Hardening-And-Secure-Virtual-Systems-V2"
}

variable "project" {
  description = "Short project name; used as the GHCR image-name prefix (e.g. comicrealm-backend)."
  type        = string
  default     = "comicrealm"
}

variable "environments" {
  description = "Deployment environments to create as GitHub Environments. The pipeline gates apply/push on these."
  type        = list(string)
  default     = ["dev", "tst", "acc", "prd"]

  validation {
    condition = length([
      for e in var.environments : e if !contains(["dev", "tst", "acc", "prd"], e)
    ]) == 0
    error_message = "environments must be a subset of: dev, tst, acc, prd."
  }
}

variable "production_environments" {
  description = "Subset of `environments` that should require a manual reviewer before deploys run."
  type        = list(string)
  default     = ["prd"]
}

variable "production_reviewers" {
  description = "GitHub usernames that can approve deploys to production environments."
  type        = list(string)
  default     = []
}
