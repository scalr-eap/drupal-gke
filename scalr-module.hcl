version = "v1"

variable "region" {
  policy = "cloud.locations"
  conditions = {
  cloud = "gce"
  }
}

variable "cluster_name" {
  global_variable = "name_fmt"
}

variable "service_name" {
  global_variable = "name_fmt"
}

variable "root_password" {
  global_variable = "sensitive_input"
}

variable "mysql_password" {
  global_variable = "sensitive_input"
}
