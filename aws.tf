# ========================================
# AWS - VPC
# ========================================

resource "aws_vpc" "vpc" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.aws_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-subnet"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ========================================
# AWS - Customer Gateway (representa o GCP)
# ========================================

resource "aws_customer_gateway" "gcp" {
  bgp_asn    = 65000
  ip_address = google_compute_address.vpn_static_ip.address
  type       = "ipsec.1"

  tags = {
    Name = "${var.project_name}-cgw-gcp"
  }
}

# ========================================
# AWS - Virtual Private Gateway
# ========================================

resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-vgw"
  }
}

resource "aws_vpn_gateway_attachment" "vpn_attachment" {
  vpc_id         = aws_vpc.vpc.id
  vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
}

# ========================================
# AWS - VPN Connection
# ========================================

resource "aws_vpn_connection" "vpn" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.gcp.id
  type                = "ipsec.1"
  static_routes_only  = true

  tunnel1_preshared_key = var.tunnel1_preshared_key
  tunnel2_preshared_key = var.tunnel2_preshared_key

  tags = {
    Name = "${var.project_name}-vpn-connection"
  }
}

# Rotas estáticas para o GCP
resource "aws_vpn_connection_route" "gcp_route" {
  vpn_connection_id      = aws_vpn_connection.vpn.id
  destination_cidr_block = var.gcp_vpc_cidr
}

# ========================================
# AWS - Route Tables
# ========================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Propagar rotas do VPN Gateway
resource "aws_vpn_gateway_route_propagation" "private" {
  vpn_gateway_id = aws_vpn_gateway.vpn_gw.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "subnet" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.private.id
}

# Route para internet (opcional, para testes)
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# ========================================
# AWS - Security Groups
# ========================================

resource "aws_security_group" "allow_from_gcp" {
  name        = "${var.project_name}-allow-from-gcp"
  description = "Allow traffic from GCP"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "All traffic from GCP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  ingress {
    description = "SSH from anywhere (REMOVA EM PRODUCAO)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from anywhere"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-allow-from-gcp"
  }
}
