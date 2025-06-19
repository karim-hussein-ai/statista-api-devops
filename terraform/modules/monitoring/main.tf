# Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
    labels = {
      name        = var.monitoring_namespace
      environment = var.environment
    }
  }
}

# Placeholder for monitoring resources
# This can be expanded to include Prometheus, Grafana, etc.
resource "null_resource" "monitoring_placeholder" {
  triggers = {
    cluster_name = var.cluster_name
    environment  = var.environment
  }

  provisioner "local-exec" {
    command = "echo 'Monitoring setup placeholder for ${var.cluster_name}'"
  }
} 