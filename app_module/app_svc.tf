provider "google" {
  project     = var.project_id
  region      = var.region
}

#resource "google_compute_router" "app" {
#  name    = "app"
#  network = var.compute_network
#  project = var.project_id
#  region  = "us-central1"
#}
#
#resource "google_compute_router_nat" "compute_instance" {
#  name                               = "computeinstance"
#  router                             = google_compute_router.app.name
#  nat_ip_allocate_option             = "MANUAL_ONLY"
#  nat_ips                            = [google_compute_address.cloudnat.self_link]
#  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
#  project                            = var.project_id
#  region                             = "us-central1"
#
#  log_config {
#    enable = true
#    filter = "ERRORS_ONLY"
#  }
#}
#
#resource "google_compute_address" "cloudnat" {
#  project = var.project_id
#  name    = var.app_name
#  region  = "us-central1"
#}

#data "template_file" "startup" {
#  template = file("${path.module}/startup.sh")
#}

#data "google_compute_zones" "available" {
#  region = var.region
#}

resource "google_compute_instance" "app"  {
  count        = var.instances_count
  name         = "${var.app_name}-${count.index}"
  machine_type = "f1-micro"
  project      = var.project_id
  #zone         = data.google_compute_zones.available.names[count.index]
  zone         = var.zone

  boot_disk {
    initialize_params {
      size  = 20
      type  = "pd-standard"
      image = var.image
    }
  }

  network_interface {
    subnetwork = var.subnetwork

    #    access_config {
    #      // Include this section to give the VM an external ip address
    #    }
  }
  #metadata_startup_script = data.template_file.startup.rendered
  // Apply the firewall rule to allow health check and IAP 
  tags = [var.app_name]
}

resource "google_compute_instance_group" "app"  {
  #count        = var.instances_count
  project     = var.project_id
  name        = var.app_name
  description = "app instance group"
  instances   = google_compute_instance.app.*.self_link

  named_port {
    name = var.app_name
    port = var.app_port
  }

  lifecycle {
    create_before_destroy = true
  }

  zone = var.zone
}

