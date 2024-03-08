provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_compute_zones" "this" {
  region  = var.region
  project = var.project_id
}

locals {
  type   = ["public", "private"]
  zones = data.google_compute_zones.this.names
}

# VPC
resource "google_compute_network" "vpc_network" {
  project                                     = var.project_id
  name                                        = "${var.name}-vpc"
  delete_default_routes_on_create             = false
  auto_create_subnetworks                     = false
  routing_mode                                = "REGIONAL"
}

# SUBNETS
resource "google_compute_subnetwork" "subnetwork" {
  project                                     = var.project_id
  name                                        = "${var.name}-subnetwork"
  ip_cidr_range                               = var.ip_cidr_range
  region                                      = var.region
  network                                     = google_compute_network.vpc_network.id
}

# FIREWALL RULES
resource "google_compute_firewall" "internal_rules" {
  project                                     = var.project_id
  name                                        = "internal-${var.name}-rule"
  network                                     = google_compute_network.vpc_network.id
  description                                 = "Creates firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
  }

  allow {
    protocol  = "udp"
  }

  allow {
    protocol  = "icmp"
  }

  source_ranges = ["10.240.0.0/24","10.200.0.0/16"]
}

resource "google_compute_firewall" "external_rules" {
  project                                     = var.project_id
  name                                        = "external-${var.name}-rule"
  network                                     = google_compute_network.vpc_network.id
  description                                 = "Creates firewall rule targeting tagged instances"

  allow {
    protocol  = "tcp"
    ports = ["22"]
  }
  allow {
    protocol  = "tcp"
    ports = ["6443"]
  }
  allow {
    protocol  = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

# PUBLIC IP
resource "google_compute_address" "ip_address" {
  name                                        = "public-${var.name}-ip"
  region                                      = var.region
  address_type = "EXTERNAL"
}

# KUBERNETES CONTROLLERS
data "google_compute_default_service_account" "default" {
}


resource "google_compute_instance" "controlers" {
  count           = 3
  name            = "k8s-cp-${count.index}"
  machine_type    = "e2-standard-2"
  can_ip_forward  = true
  zone            = "us-west1-c"

  tags = ["k8scp-${count.index}","kubernetes-the-hard-way","controller"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network     = google_compute_network.vpc_network.id
    subnetwork  = google_compute_subnetwork.subnetwork.id
    network_ip  = "10.240.0.1${count.index}"
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = data.google_compute_default_service_account.default.email
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }
}

# KUBERNETES WORKERS

resource "google_compute_instance" "workers" {
  count           = 3
  name            = "k8s-wrk-${count.index}"
  machine_type    = "e2-standard-2"
  can_ip_forward  = true
  zone            = "us-west1-c"

  metadata = {
    pod-cidr  = "10.200.${count.index}}.0/24"
    }

  tags = ["k8wrk-${count.index}","kubernetes-the-hard-way","controller"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network     = google_compute_network.vpc_network.id
    subnetwork  = google_compute_subnetwork.subnetwork.id
    network_ip  = "10.240.0.2${count.index}"
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = data.google_compute_default_service_account.default.email
    scopes = ["compute-rw","storage-ro","service-management","service-control","logging-write","monitoring"]
  }
}