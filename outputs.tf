# ========================================
# Outputs GCP
# ========================================

output "gcp_vpc_name" {
  description = "Nome da VPC no GCP"
  value       = google_compute_network.vpc.name
}

output "gcp_vpc_id" {
  description = "ID da VPC no GCP"
  value       = google_compute_network.vpc.id
}

output "gcp_subnet_cidr" {
  description = "CIDR da subnet no GCP"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "gcp_vpn_gateway_ip" {
  description = "IP público do VPN Gateway no GCP"
  value       = google_compute_address.vpn_static_ip.address
}

output "gcp_tunnel1_status" {
  description = "Status do túnel 1 no GCP"
  value       = google_compute_vpn_tunnel.tunnel1.detailed_status
}

output "gcp_tunnel2_status" {
  description = "Status do túnel 2 no GCP"
  value       = google_compute_vpn_tunnel.tunnel2.detailed_status
}

# ========================================
# Outputs AWS
# ========================================

output "aws_vpc_id" {
  description = "ID da VPC na AWS"
  value       = aws_vpc.vpc.id
}

output "aws_vpc_cidr" {
  description = "CIDR da VPC na AWS"
  value       = aws_vpc.vpc.cidr_block
}

output "aws_subnet_id" {
  description = "ID da subnet na AWS"
  value       = aws_subnet.subnet.id
}

output "aws_vpn_connection_id" {
  description = "ID da VPN Connection na AWS"
  value       = aws_vpn_connection.vpn.id
}

output "aws_tunnel1_address" {
  description = "Endereço do túnel 1 da AWS"
  value       = aws_vpn_connection.vpn.tunnel1_address
}

output "aws_tunnel2_address" {
  description = "Endereço do túnel 2 da AWS"
  value       = aws_vpn_connection.vpn.tunnel2_address
}

output "aws_security_group_id" {
  description = "ID do Security Group"
  value       = aws_security_group.allow_from_gcp.id
}

# ========================================
# Informações de Conectividade
# ========================================

output "vpn_summary" {
  description = "Resumo da configuração VPN"
  value = {
    gcp_network       = google_compute_network.vpc.name
    gcp_subnet        = var.gcp_subnet_cidr
    gcp_vpn_ip        = google_compute_address.vpn_static_ip.address
    aws_vpc           = aws_vpc.vpc.id
    aws_subnet        = var.aws_subnet_cidr
    aws_tunnel1_ip    = aws_vpn_connection.vpn.tunnel1_address
    aws_tunnel2_ip    = aws_vpn_connection.vpn.tunnel2_address
    vpn_connection_id = aws_vpn_connection.vpn.id
  }
}

# ========================================
# Comandos úteis para teste
# ========================================

output "test_commands" {
  description = "Comandos para testar a VPN"
  value = <<-EOT
    
    === VERIFICAR STATUS DOS TÚNEIS ===
    
    GCP:
    gcloud compute vpn-tunnels describe ${google_compute_vpn_tunnel.tunnel1.name} --region=${var.gcp_region}
    gcloud compute vpn-tunnels describe ${google_compute_vpn_tunnel.tunnel2.name} --region=${var.gcp_region}
    
    AWS:
    aws ec2 describe-vpn-connections --vpn-connection-ids ${aws_vpn_connection.vpn.id}
    
    === CRIAR VMs DE TESTE ===
    
    GCP VM:
    gcloud compute instances create test-vm-gcp \
      --zone=${var.gcp_region}-a \
      --machine-type=e2-micro \
      --subnet=${google_compute_subnetwork.subnet.name} \
      --image-family=debian-11 \
      --image-project=debian-cloud
    
    AWS EC2:
    # Use o console da AWS ou CLI para criar uma instância
    # Subnet: ${aws_subnet.subnet.id}
    # Security Group: ${aws_security_group.allow_from_gcp.id}
    
    === TESTAR CONECTIVIDADE ===
    
    Do GCP para AWS:
    ping <IP_PRIVADO_AWS_INSTANCE>
    
    Da AWS para GCP:
    ping <IP_PRIVADO_GCP_INSTANCE>
    
  EOT
}
