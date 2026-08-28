resource "kubernetes_namespace" "app" {
  metadata {
    name = "app"
  }
  depends_on = [null_resource.k3d_cluster]
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    POSTGRES_USER     = "admin"
    POSTGRES_PASSWORD = "admin"
    POSTGRES_DB       = "task_manager"
  }

  type = "Opaque"
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:15-alpine"

          port {
            container_port = 5432
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.postgres.metadata[0].name
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_secret.postgres]
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }
  }
  depends_on = [kubernetes_deployment.postgres]
}

resource "kubernetes_deployment" "task_manager" {
  metadata {
    name      = "task-manager"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "task-manager"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "task-manager"
      }
    }

    template {
      metadata {
        labels = {
          app = "task-manager"
        }
      }

      spec {
        container {
          name              = "task-manager"
          image             = "task-manager:latest"
          image_pull_policy = "Never"

          port {
            name           = "http"
            container_port = 3000
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }

          env {
            name  = "DATABASE_HOST"
            value = "postgres"
          }

          env {
            name  = "DATABASE_PORT"
            value = "5432"
          }

          env {
            name  = "DATABASE_NAME"
            value = "task_manager"
          }

          env {
            name = "DATABASE_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "DATABASE_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.postgres.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_service.postgres, null_resource.task_manager_image]
}

resource "kubernetes_service" "task_manager" {
  metadata {
    name      = "task-manager"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "task-manager"
    }
  }

  spec {
    selector = {
      app = "task-manager"
    }

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
      node_port   = 30001
    }

    type = "NodePort"
  }
  depends_on = [kubernetes_deployment.task_manager]
}

resource "null_resource" "task_manager_servicemonitor" {
  depends_on = [
    kubernetes_service.task_manager,
    helm_release.kube_prometheus_stack
  ]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/servicemonitor.yaml"
  }
}