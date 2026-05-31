output "frontend_service_name" {
  value       = kubernetes_service.frontend.metadata[0].name
  description = "Name of the frontend Service."
}

output "frontend_node_port" {
  value       = kubernetes_service.frontend.spec[0].port[0].node_port
  description = "NodePort exposing the frontend on the minikube VM. Use 'minikube service' to open it."
}

output "api_base_url" {
  value       = local.api_base_url
  description = "VITE_API_BASE_URL baked into the FE container."
}


# --- Azure outputs (commented out for local minikube testing) -----------------
/*
output "frontend_fqdn" {
  value       = azurerm_container_app.frontend.latest_revision_fqdn
  description = "Public FQDN of the deployed frontend."
}

output "frontend_url" {
  value       = "https://${azurerm_container_app.frontend.latest_revision_fqdn}"
  description = "Public HTTPS URL of the deployed frontend."
}
*/
