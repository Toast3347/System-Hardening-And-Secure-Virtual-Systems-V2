# ============================================================
# outputs.tf — ComicRealm
# ============================================================
# Terraform prints these after every apply.
# They are also stored in terraform.tfstate so scripts can
# read them with: terraform output -raw <name>
# ============================================================

output "namespace" {
  description = "Kubernetes namespace that was deployed to."
  value       = kubernetes_namespace.comic.metadata[0].name
}

output "fe_url" {
  description = "Frontend URL — open this in your browser."
  value       = "http://${var.minikube_ip}:${var.fe_node_port}"
}

output "be_url" {
  description = "Backend API base URL — used by the frontend."
  value       = "http://${var.minikube_ip}:${var.be_node_port}"
}

output "be_openapi_url" {
  description = "Backend OpenAPI/Swagger endpoint (Development only)."
  value       = "http://${var.minikube_ip}:${var.be_node_port}/openapi"
}

output "be_node_port" {
  description = "NodePort the BE is exposed on."
  value       = kubernetes_service.be.spec[0].port[0].node_port
}

output "fe_node_port" {
  description = "NodePort the FE is exposed on."
  value       = kubernetes_service.fe.spec[0].port[0].node_port
}

output "be_image" {
  description = "Backend image that was deployed."
  value       = "${var.be_image}:${var.image_tag}"
}

output "fe_image" {
  description = "Frontend image that was deployed."
  value       = "${var.fe_image}:${var.image_tag}"
}

output "be_replicas" {
  description = "Number of backend replicas configured."
  value       = kubernetes_deployment.be.spec[0].replicas
}

output "fe_replicas" {
  description = "Number of frontend replicas configured."
  value       = kubernetes_deployment.fe.spec[0].replicas
}

output "quick_check_commands" {
  description = "Paste these into your terminal to verify the deployment."
  value       = <<-EOT
    kubectl get pods -n ${kubernetes_namespace.comic.metadata[0].name}
    kubectl get services -n ${kubernetes_namespace.comic.metadata[0].name}
    kubectl logs -n ${kubernetes_namespace.comic.metadata[0].name} deployment/comicrealmbe
    kubectl logs -n ${kubernetes_namespace.comic.metadata[0].name} deployment/comicrealmfe
  EOT
}
