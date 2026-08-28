resource "kubernetes_config_map" "task_manager_dashboard" {
  metadata {
    name      = "grafana-dashboard-task-manager"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "task-manager.json" = file("${path.module}/dashboards/task-manager.json")
  }

  depends_on = [helm_release.kube_prometheus_stack]
}