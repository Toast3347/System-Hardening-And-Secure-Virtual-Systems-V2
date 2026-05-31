terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # --- Azure (commented out for local minikube testing) ---------------------
    # azurerm = {
    #   source  = "hashicorp/azurerm"
    #   version = "~> 4.10"
    # }
    # random = {
    #   source  = "hashicorp/random"
    #   version = "~> 3.6"
    # }
    # --------------------------------------------------------------------------

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
  }

  # Partial config. Select the env-specific state file with:
  #   terraform init -backend-config=envs/<env>.backend.hcl -reconfigure
  backend "local" {}

  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "comicrealmtfstate"
  #   container_name       = "tfstate"
  #   key                  = "backend.tfstate"
  #   use_oidc             = true
  # }
}

# --- Azure provider (commented out for local minikube testing) ----------------
# provider "azurerm" {
#   features {}
#   use_oidc = var.use_oidc
# }
# ------------------------------------------------------------------------------

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}
