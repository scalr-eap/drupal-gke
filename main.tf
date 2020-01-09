terraform {
  backend "remote" {
    hostname = "my.scalr.com"
    organization = "org-sfgari365m7sck0"
    workspaces {
      name = "drupal-gke"
    }
  }
}

provider "google" {
    region      = var.region
}

provider "google-beta" {
  region      = var.region
}

data "google_compute_zones" "available" {
}

data "google_container_cluster" "this" {
  name = "${var.cluster_name}"
  location = data.google_compute_zones.available.names[0]
}

data "google_client_config" "current" {}

provider "kubernetes" {
  load_config_file = false
  host = "${data.google_container_cluster.this.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth.0.cluster_ca_certificate)
  token = "${data.google_client_config.current.access_token}"
}

resource "kubernetes_secret" "mysql" {
  metadata {
    name = "${var.service_name}-mysql-pass"
  }

  data = {
    password = var.mysql_password
  }
}

resource "kubernetes_secret" "root" {
  metadata {
    name = "root-pass"
  }

  data = {
    password = var.root_password
  }
}

resource "kubernetes_network_policy" "this" {
  metadata {
    name      = "terraform-network-policy"
    namespace = "default"
  }

  spec {
    pod_selector {
          }

    ingress {
      ports {
        port     = "http"
        protocol = "TCP"
      }

      from {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }

    egress {} # single empty rule to allow all egress traffic

    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_pod" "this_pod" {
  metadata {
    name = "${var.service_name}-pod"
    labels = {
      App = "${var.service_name}-pod"
    }
  }
  spec {
    container {
      image = "drupal"
      name  = "${var.service_name}-ct"
      port {
        container_port = 80
      }
      env {
        name = "MYSQL_DATABASE"
        value = "drupal"
      }
      env {
        name = "MYSQL_USER"
        value = "drupal"
      }
      env {
        name  = "MYSQL_ROOT_HOST"
        value = google_sql_database_instance.drupal_dbi.private_ip_address
      }
      env {
        name  = "MYSQL_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.mysql.metadata[0].name
            key  = "password"
          }
        }
      }
      env {
        name  = "MYSQL_ROOT_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.root.metadata[0].name
            key  = "password"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "this_svc" {
  metadata {
    name = "${var.service_name}-svc"
  }
  spec {
    selector = {
      App = "${kubernetes_pod.this_pod.metadata.0.labels.App}"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = "${kubernetes_service.this_svc.load_balancer_ingress.0.ip}"
}

output "lb_hostname" {
  value = "${kubernetes_service.this_svc.load_balancer_ingress.0.hostname}"
}
