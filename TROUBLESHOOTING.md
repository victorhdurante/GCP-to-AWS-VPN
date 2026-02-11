# Guia de Troubleshooting - VPN GCP <-> AWS

## 1. Verificar Status dos Túneis

### GCP
```bash
# Listar todos os túneis
gcloud compute vpn-tunnels list --project=vpn-to-aws-487114

# Ver detalhes de um túnel específico
gcloud compute vpn-tunnels describe gcp-aws-vpn-tunnel1 \
  --region=us-central1 \
  --project=vpn-to-aws-487114

# Status esperado: "Tunnel is up and running"
```

### AWS
```bash
# Verificar status da VPN connection
aws ec2 describe-vpn-connections \
  --vpn-connection-ids <VPN_CONNECTION_ID>

# Procure por:
# "State": "available"
# "VgwTelemetry": [{
#   "Status": "UP",
#   "StatusMessage": "IPSec is up"
# }]
```

## 2. Problemas Comuns

### Túneis não sobem (Status: DOWN)

**Causas possíveis:**

1. **Shared secrets não coincidem**
   - Verifique se os PSK (Pre-Shared Keys) são idênticos em ambos os lados
   - No Terraform: `tunnel1_preshared_key` e `tunnel2_preshared_key`

2. **IPs externos incorretos**
   ```bash
   # Verificar IP do GCP
   gcloud compute addresses list --project=vpn-to-aws-487114
   
   # Deve corresponder ao Customer Gateway na AWS
   aws ec2 describe-customer-gateways
   ```

3. **Forwarding rules não criadas (GCP)**
   ```bash
   gcloud compute forwarding-rules list --project=vpn-to-aws-487114
   # Deve ter 3 regras: ESP, UDP 500, UDP 4500
   ```

4. **Firewall bloqueando tráfego VPN**
   - GCP: Verificar se há regras bloqueando UDP 500, UDP 4500, ESP (protocolo 50)
   - AWS: NACLs e Security Groups da VPC

### Túneis UP mas sem conectividade

**Causas possíveis:**

1. **Rotas não configuradas**
   
   GCP:
   ```bash
   gcloud compute routes list --project=vpn-to-aws-487114
   # Deve ter rotas apontando para os túneis VPN
   ```
   
   AWS:
   ```bash
   aws ec2 describe-route-tables
   # Verificar se há propagação do VPN Gateway
   ```

2. **Traffic selectors incorretos**
   - Verificar se `local_traffic_selector` e `remote_traffic_selector` cobrem os CIDRs corretos

3. **Firewall/Security Groups bloqueando tráfego entre redes**
   
   GCP:
   ```bash
   gcloud compute firewall-rules list --project=vpn-to-aws-487114
   ```
   
   AWS:
   ```bash
   aws ec2 describe-security-groups
   ```

4. **VMs sem rotas corretas**
   - As VMs devem estar nas subnets corretas
   - As route tables das subnets devem incluir as rotas VPN

## 3. Testes de Conectividade

### Ping entre VMs

1. **Criar VMs de teste**

   GCP:
   ```bash
   gcloud compute instances create test-vm-gcp \
     --zone=us-central1-a \
     --machine-type=e2-micro \
     --subnet=gcp-aws-vpn-subnet \
     --image-family=debian-11 \
     --image-project=debian-cloud
   ```

   AWS:
   ```bash
   aws ec2 run-instances \
     --image-id ami-0c55b159cbfafe1f0 \
     --instance-type t2.micro \
     --subnet-id <SUBNET_ID> \
     --security-group-ids <SG_ID>
   ```

2. **Obter IPs privados**
   ```bash
   # GCP
   gcloud compute instances describe test-vm-gcp \
     --zone=us-central1-a \
     --format='get(networkInterfaces[0].networkIP)'
   
   # AWS
   aws ec2 describe-instances \
     --instance-ids <INSTANCE_ID> \
     --query 'Reservations[0].Instances[0].PrivateIpAddress'
   ```

3. **Testar ping**
   ```bash
   # SSH na VM GCP
   gcloud compute ssh test-vm-gcp --zone=us-central1-a
   
   # Fazer ping para AWS
   ping <AWS_PRIVATE_IP>
   ```

### Traceroute

```bash
# Ver o caminho dos pacotes
traceroute <IP_DESTINO>

# Ou com mtr (mais detalhado)
mtr <IP_DESTINO>
```

### TCPdump

```bash
# Capturar pacotes ICMP
sudo tcpdump -i any icmp -n

# Capturar todo tráfego de/para uma rede
sudo tcpdump -i any net 172.16.0.0/16 -n
```

## 4. Logs e Monitoramento

### GCP - Cloud Logging

```bash
# Ver logs do VPN
gcloud logging read "resource.type=vpn_gateway" \
  --project=vpn-to-aws-487114 \
  --limit=50
```

### AWS - CloudWatch Logs

```bash
# Habilitar logs da VPN (se necessário)
aws ec2 create-vpn-connection \
  --options TunnelOptions=[{TunnelInsideCidr=169.254.10.0/30}]
```

## 5. Comandos Úteis de Diagnóstico

### Verificar configuração BGP (se usando)
```bash
# GCP
gcloud compute routers get-status <ROUTER_NAME> \
  --region=us-central1

# AWS
aws ec2 describe-vpn-connections \
  --vpn-connection-ids <VPN_ID> \
  --query 'VpnConnections[0].VgwTelemetry[*].[OutsideIpAddress,Status,StatusMessage]'
```

### Forçar re-negociação dos túneis

**Opção 1: Recriar os túneis**
```bash
terraform taint google_compute_vpn_tunnel.tunnel1
terraform taint google_compute_vpn_tunnel.tunnel2
terraform apply
```

**Opção 2: Recriar toda a VPN**
```bash
terraform destroy -target=google_compute_vpn_tunnel.tunnel1
terraform destroy -target=google_compute_vpn_tunnel.tunnel2
terraform apply
```

## 6. Checklist de Verificação

- [ ] Túneis mostram status "UP" em ambos os lados
- [ ] IPs do VPN Gateway correspondem nos Customer Gateways
- [ ] Shared secrets são idênticos
- [ ] Forwarding rules criadas no GCP (ESP, UDP 500, 4500)
- [ ] Rotas configuradas corretamente em ambos os lados
- [ ] Firewall rules permitem tráfego entre as redes
- [ ] Security Groups (AWS) permitem o tráfego necessário
- [ ] VMs estão nas subnets corretas
- [ ] Route tables das subnets incluem as rotas VPN
- [ ] Ping funciona entre VMs nas duas clouds

## 7. Recursos Adicionais

- [GCP Cloud VPN Documentation](https://cloud.google.com/network-connectivity/docs/vpn)
- [AWS Site-to-Site VPN Documentation](https://docs.aws.amazon.com/vpn/latest/s2svpn/)
- [GCP to AWS VPN Guide](https://cloud.google.com/architecture/build-ha-vpn-connections-google-cloud-aws)
