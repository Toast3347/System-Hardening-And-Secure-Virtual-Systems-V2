output "namespace" {
  value       = kubernetes_namespace.this.metadata[0].name
  description = "Kubernetes namespace hosting the backend stack."
}

output "backend_service_name" {
  value       = kubernetes_service.backend.metadata[0].name
  description = "ClusterDNS-resolvable name of the backend Service."
}

output "backend_cluster_url" {
  value       = "http://${kubernetes_service.backend.metadata[0].name}.${kubernetes_namespace.this.metadata[0].name}.svc.cluster.local:8080"
  description = "In-cluster URL of the backend (used by the FE module)."
}

output "backend_node_port" {
  value       = kubernetes_service.backend.spec[0].port[0].node_port
  description = "NodePort exposing the backend on the minikube VM. Use 'minikube service' to open it."
}

output "postgres_service_name" {
  value       = kubernetes_service.postgres.metadata[0].name
  description = "ClusterDNS-resolvable name of the Postgres Service."
}


# --- Azure outputs (commented out for local minikube testing) -----------------
/*
output "resource_group_name" {
  value       = azurerm_resource_group.this.name
  description = "Resource group containing the backend stack."
}

output "container_app_environment_name" {
  value       = azurerm_container_app_environment.this.name
  description = "Name of the Container Apps Environment (consumed by the frontend module as data)."
}

output "container_registry_name" {
  value       = azurerm_container_registry.this.name
  description = "Name of the shared ACR (consumed by the frontend module as data)."
}

output "container_registry_login_server" {
  value       = azurerm_container_registry.this.login_server
  description = "ACR login server, e.g. comicrealmdevacr12345.azurecr.io."
}

output "backend_fqdn" {
  value       = azurerm_container_app.backend.latest_revision_fqdn
  description = "Public FQDN of the deployed backend."
}

output "backend_url" {
  value       = "https://${azurerm_container_app.backend.latest_revision_fqdn}"
  description = "Public HTTPS URL of the deployed backend. Use this for VITE_API_BASE_URL in the frontend module."
}

output "postgres_fqdn" {
  value       = azurerm_postgresql_flexible_server.this.fqdn
  description = "FQDN of the Postgres Flexible Server."
}
*/
