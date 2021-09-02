variable "subnetwork" {}

variable "instances_count" {}

variable "project_id" {}

variable "region" {}

variable "compute_network" {}

variable "private_key" {
  description = "SSL certificate private key secret name"
  type        = string
}

variable "certificate" {
  description = "SSL certificate secret name"
  type        = string
}

variable "app_name" {
  description = "app_name"
  type        = string
}

variable "image" {}

variable "app_port" {}

variable "backend_protocol" {}

variable "domain_name" {}


