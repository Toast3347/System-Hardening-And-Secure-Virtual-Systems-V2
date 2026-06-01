terraform {
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.2"
    }
  }

  # Partial config. Select the env-specific state file with:
  #   terraform init -backend-config=envs/<env>.backend.hcl -reconfigure
  backend "local" {}
}

# Authenticates via the GITHUB_TOKEN env var (set by the workflow from the
# repo-scoped GH App / PAT secret). `owner` defaults to the token's owner.
provider "github" {
  owner = var.github_owner
}
