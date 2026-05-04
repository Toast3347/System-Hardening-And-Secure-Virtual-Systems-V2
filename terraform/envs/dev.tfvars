# ============================================================
# envs/dev.tfvars — ComicRealm Development
# ============================================================
# Usage (from inside the terraform/ folder):
#   terraform init
#   terraform plan  -var-file=envs/dev.tfvars
#   terraform apply -var-file=envs/dev.tfvars
#
# Before running:
#   1. eval $(minikube docker-env)
#   2. docker build -t comicrealmbe:dev ./ComicRealmBE
#   3. docker build -t comicrealmfe:dev ./ComicRealmFE
#   4. Run: minikube ip   → paste the result into minikube_ip below
# ============================================================

environment  = "dev"
namespace    = "comic-dev"
kube_context = "minikube"

# IMPORTANT: run 'minikube ip' and put the result here.
minikube_ip  = "192.168.49.2"

# --- Images ---
be_image  = "comicrealmbe"
fe_image  = "comicrealmfe"
image_tag = "dev"

# --- PostgreSQL ---
postgres_db       = "comicrealm"
postgres_user     = "comicrealm"
postgres_password = "comicrealm"   # Fine for local dev — change in prod!
postgres_storage  = "1Gi"

# --- ASP.NET ---
aspnet_environment = "Development"
jwt_key            = "superSecretKey_must_be_long_enough_for_hmacsha256@123456"

# --- Backend resources (small — it's your laptop) ---
be_replicas       = 1
be_cpu_request    = "100m"
be_cpu_limit      = "500m"
be_memory_request = "128Mi"
be_memory_limit   = "384Mi"
be_node_port      = 30053   # http://<minikube_ip>:30053/api

# --- Frontend resources ---
fe_replicas       = 1
fe_cpu_request    = "50m"
fe_cpu_limit      = "200m"
fe_memory_request = "128Mi"
fe_memory_limit   = "256Mi"
fe_node_port      = 30173   # http://<minikube_ip>:30173
