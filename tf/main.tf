# Odpowiednik k8s/netpol-postgres.yaml: do Postgresa tylko orders-api na TCP 5432.
resource "kubernetes_network_policy_v1" "postgres_allow_orders_api" {
  metadata {
    name      = "${var.release}-postgres-allow-orders-api"
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = "postgres"
      "app.kubernetes.io/instance"  = var.release
      "app.kubernetes.io/component" = "postgres"
      "app.kubernetes.io/part-of"   = "kantyna"
    }
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name"     = "postgres"
        "app.kubernetes.io/instance" = var.release
      }
    }

    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/name"     = "orders-api"
            "app.kubernetes.io/instance" = var.release
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = "5432"
      }
    }
  }
}
