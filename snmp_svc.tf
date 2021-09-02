provider "google" {
  project     = var.project_id
  region      = var.region
}

variable "app_name" {
  type = string
  default = "snmptest-svc"
}

variable "compute_network" {
   type = string
   default = "projects/testing-324703/global/networks/dev"
}

variable "subnetwork" {
  type = string
  default = "projects/testing-324703/regions/us-central1/subnetworks/subnet1"
}

variable  "project_id" {
 type = string
 default = "testing-324703"
}

variable "app_port" {
  type = string
  default = 80
}

variable "region" {
  type = string
  default = "us-central1"
}


module "snmp_svc" {
    source = "../app_module/"
    subnetwork = var.subnetwork
    project_id    = var.project_id
    region      = var.region
    compute_network = var.compute_network
    instances_count = 3
    private_key = "private_key"
    certificate = "cert"
    app_name = var.app_name
    image = "centos-7-v20210701"
    app_port = var.app_port
    backend_protocol= "HTTP"
    domain_name = "example.com"
}

resource "google_compute_firewall" "iap_ssh" {
  project   = var.project_id
  name      = "${var.app_name}-allow-ingress-from-iap"
  network   = var.compute_network
  priority  = 1001
  direction = "INGRESS"
  source_ranges = [
    "35.235.240.0/20"
  ]
  target_tags = [var.app_name]
  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

resource "google_compute_firewall" "http-server" {
  name    = "${var.app_name}-allow-http"
  network = var.compute_network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = [var.app_port]
  }

  // Allow HTTP traffic from GCP to instances with an http-server tag for health check 
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = [var.app_name]
}