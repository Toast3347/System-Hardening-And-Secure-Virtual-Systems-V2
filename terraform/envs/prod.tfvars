# ============================================================
# envs/prod.tfvars — ComicRealm Production (local Minikube)
# ============================================================
# Usage:
#   terraform plan  -var-file=envs/prod.tfvars
#   terraform apply -var-file=envs/prod.tfvars
#
# Before running:
#   eval $(minikube docker-env)
#   docker build -t comicrealmbe:v1.0.0 ./ComicRealmBE
#   docker build \
#     --build-arg VITE_API_BASE_URL=http://192.168.49.2:32053/api \
#     -t comicrealmfe:v1.0.0 ./ComicRealmFE
#
# Rules for prod:
#   - Never use image_tag = "dev" or "latest" — always a pinned version.
#   - Change postgres_password to something strong.
#   - Change jwt_key to a strong random string (32+ chars).
# ============================================================

environment  = "prod"
namespace    = "comic-prod"
kube_context = "minikube"

minikube_ip  = "192.168.49.2"

# --- Images --- always pin prod to a specific version tag ---
be_image  = "comicrealmbe"
fe_image  = "comicrealmfe"
image_tag = "v1.0.0"

# --- PostgreSQL ---
postgres_db       = "comicrealm_prod"
postgres_user     = "comicrealm"
postgres_password = "CHANGE_ME_strong_prod_password_here!"
postgres_storage  = "5Gi"

# --- ASP.NET ---
aspnet_environment = "Production"
jwt_key            = "CHANGE_ME_strong_jwt_key_at_least_32_chars_long@prod!"

# --- Backend (3 replicas for availability) ---
be_replicas       = 3
be_cpu_request    = "200m"
be_cpu_limit      = "1000m"
be_memory_request = "256Mi"
be_memory_limit   = "512Mi"
be_node_port      = 32053

# --- Frontend (2 replicas) ---
fe_replicas       = 2
fe_cpu_request    = "100m"
fe_cpu_limit      = "400m"
fe_memory_request = "256Mi"
fe_memory_limit   = "512Mi"
fe_node_port      = 32173
