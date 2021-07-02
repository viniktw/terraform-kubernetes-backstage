locals {
  domain_fqdn = "${var.app_name}.${var.my_domain}"
}

resource "kubernetes_secret" "backstage_secret" {
  metadata {
    name = "backstage-secrets"
    namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
  }
  data = {
    GITHUB_TOKEN = var.github_token
    AUTH_GITHUB_CLIENT_ID = var.github_auth_client_id
    AUTH_GITHUB_CLIENT_SECRET = var.github_auth_client_secret
  }
  type = "Opaque"
}

resource "kubernetes_config_map" "backstage_config" {
  metadata {
    name = "backstage-config"
    namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
  }

  data = {
    "app-config.yaml" = "${file("${path.module}/app-config.yaml")}"
  }
}

resource "kubernetes_deployment" "backstage_deployment" {
  metadata {
    name = "backstage"
    namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backstage"
      }
    }

    template {
      metadata {
        labels = {
          app = "backstage"
        }
      }
      spec {
        container {
          name = "backstage"
          # image = "martinaif/backstage-k8s-demo-backend:20210423T1550"
          image = var.my_backstage_image
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 7000
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.postgres_password.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.backstage_secret.metadata.0.name
            }
          }
          env {
            name = "POSTGRES_HOST"
            value = "${var.app_name}-db-service"
          }
          env {
            name = "POSTGRES_PORT"
            value = "5432"
          }
          volume_mount {
            mount_path = "/app/app-config.yaml"
            sub_path = "app-config.yaml"
            name = "appconfig"
            read_only = true

          }
        }
        volume {
          name = "appconfig"
          config_map {
            name = kubernetes_config_map.backstage_config.metadata.0.name
            # claim_name = kubernetes_persistent_volume_claim.db_persistent_volume_claim.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backstage_service" {
  metadata {
    name = "backstage"
    namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.backstage_deployment.spec.0.template.0.metadata.0.labels.app
    }
    port {
      port = 80
      target_port = 7000
    }
    type = "LoadBalancer"
  }
}


resource "kubernetes_ingress" "backstage_ingress" {
  metadata {
    name = "backstage"
    namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
    labels = {
      app = "BackstageIngress"
    }
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/*"
    }
  }
  spec {
    ingress_class_name = "public"

    rule {
      host = local.domain_fqdn

      http {
        path {
          backend {
            service_name = kubernetes_service.backstage_service.metadata.0.name
            service_port = 80
          }
          path = "/*"
        }
      }
    }

  }
}





#
