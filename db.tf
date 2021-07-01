# ============================
# PostgreSQL
# ============================

# password
resource "kubernetes_secret" "postgres_password" {
  metadata {
    name = "postgres-secrets"
    namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
  }
  data = {
    POSTGRES_USER = var.db_user
    POSTGRES_PASSWORD = var.db_password
  }
  type = "Opaque"
}

# storage
resource "kubernetes_persistent_volume" "db_storage_persistent_volume" {
  metadata {
    name = "postgres-storage"
    # namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
  }
  spec {
    storage_class_name = "microk8s-hostpath"
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      local {
        path = "/data" # TODO
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "kubernetes.io/hostname"
            operator = "In"
            # values = [ "microk8s-vm" ]
            values = [ "otacon" ] # TODO
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "db_persistent_volume_claim" {
  metadata {
    name = "${var.app_name}-db-volume-claim"
    namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
  }
  spec {
    storage_class_name = "microk8s-hostpath" # TODO
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "2Gi" #TODO
      }
    }
    volume_name = kubernetes_persistent_volume.db_storage_persistent_volume.metadata.0.name
  }
}

resource "kubernetes_deployment" "db_deployment" {
  metadata {
    name = "${var.app_name}-postgres"
    namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
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
          name = "postgres"
          # image = "postgres:13.2-alpine"
          image = "docker.io/bitnami/postgresql:11.9.0-debian-10-r16"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 5432
          }
          env_from {
            secret_ref {
              name = "postgres-secrets"
            }
          }
          volume_mount {
            # mount_path = "/var/lib/postgresql/data"
            mount_path = "/bitname/postgresql"
            name = "postgresdb"
          }
        }
        volume {
          name = "postgresdb"
          persistent_volume_claim {
            claim_name = "${var.app_name}-db-volume-claim"
            # claim_name = kubernetes_persistent_volume_claim.db_persistent_volume_claim.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "db_service" {
  metadata {
    name = "${var.app_name}-db-service"
    namespace = kubernetes_namespace.backstage_namespace.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.db_deployment.spec.0.template.0.metadata.0.labels.app
    }
    port {
      port = 5432
    }
  }
}
