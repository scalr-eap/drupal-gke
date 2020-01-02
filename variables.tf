
variable mysql_password {
#  sensitive = true
}
variable root_password {
#    sensitive = true
}

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
