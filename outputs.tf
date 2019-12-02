output "metrics_server_service_name" {
  value = kubernetes_service.metrics_server.metadata.0.name
}

output "metrics_server_service_namespace" {
  value = kubernetes_service.metrics_server.metadata.0.namespace
}