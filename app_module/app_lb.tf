
resource "google_compute_address" "app" {
  name         = "${var.app_name}-internal-ip"
  subnetwork   = var.subnetwork
  address_type = "INTERNAL"
  region       = var.region
}

resource "google_compute_forwarding_rule" "app" {
  name                  = var.app_name
  provider              = google-beta
  region                = var.region
  project               = var.project_id
  #depends_on            = [google_compute_subnetwork.proxy_subnet]
  ip_address             = google_compute_address.app.address
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.app.id
  network               = var.compute_network
  subnetwork            = var.subnetwork
  network_tier          = "PREMIUM"
}


resource "google_compute_region_target_https_proxy" "app" {
  region           = var.region
  name             = var.app_name
  url_map          = google_compute_region_url_map.app.id
  ssl_certificates = [google_compute_region_ssl_certificate.app.id]
}

data "google_secret_manager_secret_version" "key" {
  secret = var.private_key
}

data "google_secret_manager_secret_version" "cert" {
  secret = var.certificate
}

resource "google_compute_region_ssl_certificate" "app" {
  region      = var.region
  name        = var.app_name
  private_key = data.google_secret_manager_secret_version.key.secret_data
  certificate = data.google_secret_manager_secret_version.cert.secret_data
}

resource "google_compute_region_url_map" "app" {
  region      = var.region
  name        = var.app_name
  description = "a description"

  default_service = google_compute_region_backend_service.app.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_region_backend_service.app.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_region_backend_service.app.id
    }
  }
}

resource "google_compute_region_backend_service" "app" {
  region      = var.region
  name        = var.app_name
  protocol    = var.backend_protocol
  load_balancing_scheme = "INTERNAL_MANAGED"
  #load_balancing_scheme = "INTERNAL"
  timeout_sec = 10
   
   backend {
    group = google_compute_instance_group.app.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  health_checks = [google_compute_region_health_check.app.id]
}

resource "google_compute_region_health_check" "app" {
  name                = "${var.app_name}-tcp-health-check"
  check_interval_sec  = 1
  timeout_sec         = 1
  healthy_threshold   = 4
  unhealthy_threshold = 4
  tcp_health_check {
    port_name          = var.app_name
    port_specification = "USE_NAMED_PORT"
  }
}

resource "google_dns_managed_zone" "private-zone" {
  name        = var.app_name
  dns_name    = "${var.domain_name}."
  description = "private DNS zone"
  visibility = "private"
  private_visibility_config {
    networks {
      network_url = var.compute_network
    }
    #networks {
    #  network_url = google_compute_network.network-2.id
    #}
  }
}

resource "google_dns_record_set" "private" {
  project      = var.project_id
  name         = "${var.domain_name}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private-zone.name
  rrdatas      = [google_compute_address.app.address]
}