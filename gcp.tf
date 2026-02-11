# ========================================
# GCP - VPC Network
# ========================================

resource "google_compute_network" "vpc" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.gcp_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc.id
}

# ========================================
# GCP - Cloud VPN Gateway
# ========================================

resource "google_compute_address" "vpn_static_ip" {
  name   = "${var.project_name}-vpn-ip"
  region = var.gcp_region
}

resource "google_compute_vpn_gateway" "vpn_gateway" {
  name    = "${var.project_name}-vpn-gateway"
  network = google_compute_network.vpc.id
  region  = var.gcp_region
}

# ========================================
# GCP - Forwarding Rules (necessários para VPN Classic)
# ========================================

resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "${var.project_name}-fr-esp"
  region      = var.gcp_region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "${var.project_name}-fr-udp500"
  region      = var.gcp_region
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "${var.project_name}-fr-udp4500"
  region      = var.gcp_region
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

# ========================================
# GCP - VPN Tunnels
# ========================================

resource "google_compute_vpn_tunnel" "tunnel1" {
  name          = "${var.project_name}-tunnel1"
  region        = var.gcp_region
  peer_ip       = aws_vpn_connection.vpn.tunnel1_address
  shared_secret = var.tunnel1_preshared_key
  
  target_vpn_gateway      = google_compute_vpn_gateway.vpn_gateway.id
  local_traffic_selector  = [var.gcp_subnet_cidr]
  remote_traffic_selector = [var.aws_vpc_cidr]
  
  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  name          = "${var.project_name}-tunnel2"
  region        = var.gcp_region
  peer_ip       = aws_vpn_connection.vpn.tunnel2_address
  shared_secret = var.tunnel2_preshared_key
  
  target_vpn_gateway      = google_compute_vpn_gateway.vpn_gateway.id
  local_traffic_selector  = [var.gcp_subnet_cidr]
  remote_traffic_selector = [var.aws_vpc_cidr]
  
  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

# ========================================
# GCP - Routes
# ========================================

resource "google_compute_route" "route1" {
  name                = "${var.project_name}-route1"
  network             = google_compute_network.vpc.name
  dest_range          = var.aws_vpc_cidr
  priority            = 1000
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel1.id
}

resource "google_compute_route" "route2" {
  name                = "${var.project_name}-route2"
  network             = google_compute_network.vpc.name
  dest_range          = var.aws_vpc_cidr
  priority            = 1001
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel2.id
}

# ========================================
# GCP - Firewall Rules
# ========================================

# Permitir tráfego da AWS para GCP
resource "google_compute_firewall" "allow_from_aws" {
  name    = "${var.project_name}-allow-from-aws"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.aws_vpc_cidr]
}

# Permitir SSH para debug (REMOVA EM PRODUÇÃO)
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.project_name}-allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
