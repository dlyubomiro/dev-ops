terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "books" {
  metadata {
    name = "books-namespace"
  }
}

resource "kubernetes_deployment" "books_api" {
  metadata {
    name      = "books-api"
    namespace = kubernetes_namespace.books.metadata[0].name
    labels = {
      app = "books-api"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "books-api"
      }
    }

    template {
      metadata {
        labels = {
          app = "books-api"
        }
      }

      spec {
        container {
          image = "books-api:latest"
          name  = "books-api"

          port {
            container_port = 8080
          }

          env {
            name = "DATABASE_URL"
            value_from {
              secret_key_ref {
                name = "books-secret"
                key  = "database-url"
              }
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "books_api" {
  metadata {
    name      = "books-api-service"
    namespace = kubernetes_namespace.books.metadata[0].name
  }

  spec {
    selector = {
      app = "books-api"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

