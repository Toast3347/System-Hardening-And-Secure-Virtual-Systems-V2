# Terraform

Two independent root modules, each with its own state. Today they target
**local minikube** via the `kubernetes` provider. The original Azure
Container Apps resources are kept in `/* ... */` block comments inside
`main.tf` / `outputs.tf` and the `azurerm` provider is commented out in
`versions.tf` — uncomment them (and re-enable `tags`, `image_tag`, etc. in
`variables.tf`) to switch back to Azure.

```
terraform/
  backend/    # Namespace, Postgres (Deployment + Service + PVC), BE Deployment + Service
  frontend/   # Reuses the namespace via data sources; FE Deployment + Service
```

## Prerequisites

- [minikube](https://minikube.sigs.k8s.io/docs/start/) running (`minikube start`)
- `kubectl` configured for the `minikube` context (`kubectl config use-context minikube`)
- Docker available so you can build images into the minikube daemon
- Terraform >= 1.6

## Environments

Each module supports four envs — `dev`, `tst`, `acc`, `prd` — via per-env
tfvars + a partial `backend "local"` config that puts each env's state in
its own file.

```
terraform/
  backend/
    envs/
      dev.tfvars   dev.backend.hcl
      tst.tfvars   tst.backend.hcl
      acc.tfvars   acc.backend.hcl
      prd.tfvars   prd.backend.hcl
  frontend/
    envs/   (same layout)
```

Each env gets its own Kubernetes namespace (`comicrealm-dev`,
`comicrealm-tst`, …) and its own NodePort range, so they can run
side-by-side on the same minikube cluster.

| Env | Namespace          | BE NodePort | FE NodePort |
|-----|--------------------|-------------|-------------|
| dev | comicrealm-dev     | 30053       | 30173       |
| tst | comicrealm-tst     | 30153       | 30273       |
| acc | comicrealm-acc     | 30253       | 30373       |
| prd | comicrealm-prd     | 30353       | 30473       |

Pattern for any module / any env:

```powershell
cd terraform\backend
terraform init   -reconfigure -backend-config="envs/dev.backend.hcl"
terraform plan   -var-file="envs/dev.tfvars"
terraform apply  -var-file="envs/dev.tfvars"
```

Switching envs is `terraform init -reconfigure -backend-config=envs/<env>.backend.hcl`
followed by `terraform apply -var-file=envs/<env>.tfvars`. The `-reconfigure`
flag is what tells Terraform to swap state files.

Secrets in `prd.tfvars` (`postgres_admin_password`, `jwt_signing_key`) are
placeholders — override them per apply, e.g. via env vars:

```powershell
$env:TF_VAR_postgres_admin_password = "<from-vault>"
$env:TF_VAR_jwt_signing_key         = "<from-vault>"
terraform apply -var-file="envs/prd.tfvars"
```

## End-to-end local run (dev env)

```powershell
# 1. Start minikube
minikube start

# 2. Point your local docker at the minikube daemon so images are visible
#    inside the cluster without needing a registry.
& minikube -p minikube docker-env --shell powershell | Invoke-Expression

# 3. Build both images
docker build -t comicrealm-backend:local  .\ComicRealmBE
docker build -t comicrealm-frontend:local .\ComicRealmFE

# 4. Apply the backend module
cd terraform\backend
terraform init  -reconfigure -backend-config="envs/dev.backend.hcl"
terraform apply -var-file="envs/dev.tfvars"

# 5. Apply the frontend module
cd ..\frontend
terraform init  -reconfigure -backend-config="envs/dev.backend.hcl"
terraform apply -var-file="envs/dev.tfvars"
```

Open the services in a browser:

```powershell
minikube service comicrealm-dev-fe -n comicrealm-dev
minikube service comicrealm-dev-be -n comicrealm-dev
```

## Rebuilding after a code change

The Deployments use `lifecycle.ignore_changes = [..image]`, so a simple
rebuild + rollout is enough — no `terraform apply` needed:

```powershell
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
docker build -t comicrealm-backend:local .\ComicRealmBE
kubectl rollout restart deployment/comicrealm-dev-be -n comicrealm-dev
```

(Replace `dev` with the env you're working on.)

## Switching back to Azure

1. In `terraform/{backend,frontend}/versions.tf`, uncomment the `azurerm`
   (and `random` in the backend) provider blocks and the
   `provider "azurerm"` block; comment out the `kubernetes` provider.
2. In `terraform/{backend,frontend}/main.tf`, remove the `/* ... */`
   wrapping the Azure resources and comment out / delete the kubernetes
   resources.
3. In `outputs.tf`, do the same swap.
4. Replace `terraform.tfvars` with Azure-shaped values.

(Or keep two branches — easier than juggling comments.)
