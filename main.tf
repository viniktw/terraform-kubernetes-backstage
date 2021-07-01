terraform {
  backend "kubernetes" {
    secret_suffix = "state"
    load_config_file = true
    config_path = "./kube_config"
  }
}

provider "kubernetes" {
  config_path = "kube_config"
  config_context = "microk8s"
  config_context_cluster = "microk8s-cluster"
}

# Namespace
resource "kubernetes_namespace" "backstage_namespace" {
  metadata {
    name = var.app_name
  }
}
