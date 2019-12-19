resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_container_cluster.this.network
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = data.google_container_cluster.this.network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "drupal_dbi" {
  provider = "google-beta"
  database_version = "MYSQL_5_7"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  # First-generation instance regions are not the conventional
  # Google Compute Engine regions. See argument reference below.
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      private_network = data.google_container_cluster.this.network
    }

  }
}

resource "google_sql_database" "drupal_db" {
  name     = "drupal"
  instance = google_sql_database_instance.drupal_dbi.name
}

resource "google_sql_user" "users" {
  name     = "drupal"
  instance = google_sql_database_instance.drupal_dbi.name
  password = var.mysql_password
}

output "database_host_ip" {
  value = google_sql_database_instance.drupal_dbi.private_ip_address
}
