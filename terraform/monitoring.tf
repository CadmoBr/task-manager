resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
  depends_on = [null_resource.k3d_cluster]
}

# 1. Loki + Promtail
resource "helm_release" "loki_stack" {
  name       = "loki-stack"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "2.10.2"

  set {
    name  = "loki.enabled"
    value = "true"
  }

  set {
    name  = "promtail.enabled"
    value = "true"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# 2. Prometheus + Grafana
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "56.6.0"

  values = [
    <<-EOT
    grafana:
      adminPassword: "admin"
      service:
        type: NodePort
        nodePort: 30000
      sidecar:
        dashboards:
          enabled: true
          label: grafana_dashboard
          labelValue: "1"
          searchNamespace: ALL
      additionalDataSources:
        - name: Loki
          uid: loki
          type: loki
          url: http://loki-stack.monitoring.svc.cluster.local:3100
          access: proxy
          isDefault: false
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
    EOT
  ]

  depends_on = [kubernetes_namespace.monitoring, helm_release.loki_stack]
}