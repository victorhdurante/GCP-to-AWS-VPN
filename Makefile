.PHONY: help init plan apply destroy validate fmt clean status test-gcp test-aws

help: ## Mostra esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Inicializa o Terraform
	terraform init

validate: ## Valida a configuração do Terraform
	terraform validate

fmt: ## Formata os arquivos Terraform
	terraform fmt -recursive

plan: ## Mostra o plano de execução
	terraform plan

apply: ## Aplica as configurações
	terraform apply

destroy: ## Destrói todos os recursos
	terraform destroy

clean: ## Remove arquivos temporários do Terraform
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*

status: ## Verifica o status dos túneis VPN
	@echo "=== Status dos Túneis GCP ==="
	@gcloud compute vpn-tunnels list --project=$(shell terraform output -raw gcp_project_id 2>/dev/null || echo "vpn-to-aws-487114")
	@echo ""
	@echo "=== Status da VPN Connection AWS ==="
	@aws ec2 describe-vpn-connections --vpn-connection-ids $(shell terraform output -raw aws_vpn_connection_id 2>/dev/null)

test-gcp: ## Cria uma VM de teste no GCP
	@echo "Criando VM de teste no GCP..."
	gcloud compute instances create test-vm-gcp \
		--project=$(shell terraform output -raw gcp_project_id) \
		--zone=$(shell terraform output -raw gcp_region)-a \
		--machine-type=e2-micro \
		--subnet=$(shell terraform output -raw gcp_vpc_name)-subnet \
		--image-family=debian-11 \
		--image-project=debian-cloud \
		--tags=allow-ssh

test-aws: ## Mostra comando para criar VM de teste na AWS
	@echo "Para criar uma VM de teste na AWS, use:"
	@echo ""
	@echo "aws ec2 run-instances \\"
	@echo "  --image-id ami-0c55b159cbfafe1f0 \\"
	@echo "  --instance-type t2.micro \\"
	@echo "  --subnet-id $(shell terraform output -raw aws_subnet_id) \\"
	@echo "  --security-group-ids $(shell terraform output -raw aws_security_group_id) \\"
	@echo "  --key-name YOUR_KEY_NAME \\"
	@echo "  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-vm-aws}]'"

outputs: ## Mostra todos os outputs
	terraform output
