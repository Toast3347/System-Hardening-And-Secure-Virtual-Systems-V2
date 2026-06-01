# =============================================================================
# GitHub-side infrastructure for the ComicRealm container registry (GHCR).
#
# GHCR itself is provisioned implicitly on first `docker push`, but everything
# *around* it that the pipeline needs is managed here as code:
#   - Repo-level Actions permissions (allow packages: write so workflows can
#     push to ghcr.io without any extra PAT or manual setup).
#   - Per-environment GitHub Environments (dev/tst/acc/prd) used by the
#     workflows' `environment:` field so deploys are gated and auditable.
#   - Optional required-reviewers + branch policy on production environments.
#
# Apply this module once per repo; the workflows then run end-to-end without
# any manual GH UI clicks.
# =============================================================================

data "github_repository" "this" {
  full_name = "${var.github_owner}/${var.github_repository}"
}

data "github_user" "reviewers" {
  for_each = toset(var.production_reviewers)
  username = each.value
}

resource "github_actions_repository_permissions" "this" {
  repository      = data.github_repository.this.name
  enabled         = true
  allowed_actions = "all"
}

# Per-workflow `permissions:` blocks already grant `packages: write` to the
# default GITHUB_TOKEN at the job scope, so no repo-level setting is needed
# beyond enabling Actions above.

resource "github_repository_environment" "env" {
  for_each    = toset(var.environments)
  repository  = data.github_repository.this.name
  environment = each.value

  deployment_branch_policy {
    protected_branches     = contains(var.production_environments, each.value)
    custom_branch_policies = !contains(var.production_environments, each.value)
  }

  dynamic "reviewers" {
    for_each = contains(var.production_environments, each.value) ? [1] : []
    content {
      users = [for u in data.github_user.reviewers : u.id]
    }
  }
}

# Allow the `main` branch to deploy to non-production envs without protection.
resource "github_repository_environment_deployment_policy" "non_prod_main" {
  for_each       = toset([for e in var.environments : e if !contains(var.production_environments, e)])
  repository     = data.github_repository.this.name
  environment    = github_repository_environment.env[each.value].environment
  branch_pattern = "main"
}

locals {
  ghcr_namespace = lower("ghcr.io/${var.github_owner}")
  images = {
    backend  = "${local.ghcr_namespace}/${var.project}-backend"
    frontend = "${local.ghcr_namespace}/${var.project}-frontend"
  }
}
