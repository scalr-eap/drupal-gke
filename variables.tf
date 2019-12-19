
variable mysql_password {}
variable root_password {}

variable "cluster_name" {
  type    = string
  description = "Cluster to deploy to"
}

variable "region" {
  description = "The GCE Region of the Cluster"
  type        = string
}

variable "service_name" {
  description = "Name to be given to the Wordpress service in GKE"
  type        = string
}
