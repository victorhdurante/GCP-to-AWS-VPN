# ========================================
# Variáveis GCP
# ========================================

variable "gcp_project_id" {
  description = "ID do projeto GCP"
  type        = string
  default     = "vpn-to-aws-487114"
}

variable "gcp_region" {
  description = "Região do GCP"
  type        = string
  default     = "us-central1"
}

variable "gcp_vpc_cidr" {
  description = "CIDR da VPC no GCP"
  type        = string
  default     = "10.0.0.0/16"
}

variable "gcp_subnet_cidr" {
  description = "CIDR da subnet no GCP"
  type        = string
  default     = "10.0.1.0/24"
}

# ========================================
# Variáveis AWS
# ========================================

variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR da VPC na AWS"
  type        = string
  default     = "172.16.0.0/16"
}

variable "aws_subnet_cidr" {
  description = "CIDR da subnet na AWS"
  type        = string
  default     = "172.16.1.0/24"
}

# ========================================
# Variáveis VPN
# ========================================

variable "vpn_shared_secret" {
  description = "Shared secret para os túneis VPN (mínimo 8 caracteres)"
  type        = string
  sensitive   = true
  default     = "MySecretKey12345"  # MUDE ISSO!
}

variable "tunnel1_preshared_key" {
  description = "Pre-shared key para túnel 1"
  type        = string
  sensitive   = true
  default     = "tunnel1secret1234"  # MUDE ISSO!
}

variable "tunnel2_preshared_key" {
  description = "Pre-shared key para túnel 2"
  type        = string
  sensitive   = true
  default     = "tunnel2secret5678"  # MUDE ISSO!
}

# ========================================
# Tags e Labels
# ========================================

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "gcp-aws-vpn"
}
