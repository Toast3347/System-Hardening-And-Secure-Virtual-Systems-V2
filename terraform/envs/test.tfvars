# ============================================================
# envs/test.tfvars — ComicRealm Test
# ============================================================
# Usage:
#   terraform plan  -var-file=envs/test.tfvars
#   terraform apply -var-file=envs/test.tfvars
#
# Before running:
#   eval $(minikube docker-env)
#   docker build -t comicrealmbe:test ./ComicRealmBE
#   docker build \
#     --build-arg VITE_API_BASE_URL=http://192.168.49.2:31053/api \
#     -t comicrealmfe:test ./ComicRealmFE
# ============================================================

environment  = "test"
namespace    = "comic-test"
kube_context = "minikube"

minikube_ip  = "192.168.49.2"

# --- Images ---
be_image  = "comicrealmbe"
fe_image  = "comicrealmfe"
image_tag = "test"           # Pin to a fixed tag so test results are reproducible.

# --- PostgreSQL ---
postgres_db       = "comicrealm_test"  # Separate DB so test data doesn't touch dev.
postgres_user     = "comicrealm"
postgres_password = "comicrealm_test_pw"
postgres_storage  = "1Gi"

# --- ASP.NET ---
aspnet_environment = "Staging"
jwt_key            = "testSecretKey_must_be_long_enough_for_hmacsha256@654321"

# --- Backend (2 replicas to test load-balancing behaviour) ---
be_replicas       = 2
be_cpu_request    = "100m"
be_cpu_limit      = "500m"
be_memory_request = "128Mi"
be_memory_limit   = "384Mi"
be_node_port      = 31053   # Different port — test + dev can run at the same time.

# --- Frontend ---
fe_replicas       = 1
fe_cpu_request    = "50m"
fe_cpu_limit      = "200m"
fe_memory_request = "128Mi"
fe_memory_limit   = "256Mi"
fe_node_port      = 31173
