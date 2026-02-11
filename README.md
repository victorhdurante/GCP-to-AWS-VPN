# VPN Site-to-Site entre GCP e AWS

Este projeto configura uma VPN IPsec entre Google Cloud Platform e Amazon Web Services usando Terraform.

## Pré-requisitos

1. **Terraform** instalado (versão >= 1.0)
2. **gcloud CLI** configurado e autenticado
3. **AWS CLI** configurado com credenciais
4. Permissões necessárias em ambas as clouds

## Estrutura do Projeto

```
gcp-aws-vpn/
├── gcp/              # Recursos do GCP
├── aws/              # Recursos da AWS
├── variables.tf      # Variáveis globais
├── outputs.tf        # Outputs importantes
└── terraform.tfvars  # Seus valores personalizados
```

## Passos para Configuração

### 1. Configurar credenciais

**GCP:**
```bash
gcloud auth application-default login
export GOOGLE_PROJECT="vpn-to-aws-487114"
```

**AWS:**
```bash
aws configure
# ou usar variáveis de ambiente:
export AWS_ACCESS_KEY_ID="sua-key"
export AWS_SECRET_ACCESS_KEY="sua-secret"
export AWS_REGION="us-east-1"
```

### 2. Configurar variáveis

Edite o arquivo `terraform.tfvars` com seus valores.

### 3. Deploy

```bash
# Inicializar Terraform
terraform init

# Ver o plano de execução
terraform plan

# Aplicar as configurações
terraform apply
```

### 4. Testar conectividade

Após o deploy, você pode testar a conectividade criando VMs em ambas as clouds e fazendo ping entre elas.

## Arquitetura

```
┌─────────────────────────────────────┐
│             GCP                     │
│                                     │
│  VPC: 10.0.0.0/16                  │
│  ├── Subnet: 10.0.1.0/24           │
│  └── Cloud VPN Gateway             │
│       └── Tunnel 1 ────────────┐   │
│       └── Tunnel 2 ────────┐   │   │
└─────────────────────────────│───│───┘
                              │   │
                    IPsec     │   │
                              │   │
┌─────────────────────────────│───│───┐
│             AWS             │   │   │
│                             │   │   │
│  VPC: 172.16.0.0/16        │   │   │
│  ├── Subnet: 172.16.1.0/24 │   │   │
│  └── Virtual Private GW    │   │   │
│       └── Tunnel 1 ────────┘   │   │
│       └── Tunnel 2 ────────────┘   │
└─────────────────────────────────────┘
```

## Custos Estimados

- **GCP**: ~$0.05/hora por VPN gateway + tráfego de saída
- **AWS**: ~$0.05/hora por VPN connection + tráfego de dados

## Limpeza

Para destruir todos os recursos:

```bash
terraform destroy
```

## Troubleshooting

### Túneis não sobem
- Verifique se os IPs externos estão corretos
- Confira os shared secrets
- Verifique as regras de firewall
- Confirme as rotas em ambos os lados

### Conectividade não funciona
- Teste os túneis estarem UP
- Verifique rotas nas route tables
- Confirme security groups e firewall rules
- Teste ping entre as subnets
