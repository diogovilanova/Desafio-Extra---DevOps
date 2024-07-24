# Deploy de WordPress na Azure com Terraform e Docker

Descrição do Desafio:

Você deve criar um script Terraform que realiza o seguinte:

1. Sobe uma máquina virtual (VM) na Azure.
2. Configura a VM para instalar Docker.
3. Sobe um container com o WordPress instalado na VM.

Instruções

1. Crie um repositório público no GitHub e adicione o código criado.
2. Inclua um README.md com instruções detalhadas sobre como executar o código.
3. Preencha o formulário do Google fornecendo o link para o repositório GitHub (sem compartilhar informações pessoais, o repositório precisa estar marcado como publico).

Requisitos de conclusão:  
Terraform: O script Terraform deve criar uma máquina virtual na Azure.  
Instalação do Docker: Utilize um script de inicialização para instalar o Docker na VM.  
Container com WordPress: Após a instalação do Docker, suba um container com o WordPress.  
Automatização Completa: Todo o processo deve ser automatizado com Terraform. Não deve ser necessário conectar-se manualmente à máquina para instalação e configuração.  

Pontos Extras  
Containers Separados: Configure containers separados para o WordPress e o banco de dados, garantindo a retenção de dados durante um upgrade do WordPress.  
Comentários no Código: Adicione comentários explicativos no código Terraform para indicar o que cada bloco faz.  
Arquivo docker-compose.yml: Forneça um arquivo docker-compose.yml para facilitar a criação dos containers.  
Senha do Banco de Dados: Configure a senha do usuário root do banco de dados para GAud4mZby8F3SD6P.  
Dockerfile para o Servidor Web: Forneça um arquivo Dockerfile para o servidor web, mesmo que use uma imagem pública com as dependências instaladas.

## Desenvolvimento

#### Importante: Antes de tudo entender o problema, a solução proposta, dividir o problema em tarefas menores e partir para a execução!

#### Objetivo: Automatizar o provisionamento de infraestrutura como codigo com terraform, conteinerizar para da resiliencia e isolamento para as aplicações.

### Instalação, criação e configuração pelo Docker.  
* apos instalação do docker utilizar o pull para baixar as imagens do mysql, wordpress e phpmyadmin.  
``sudo docker pull mysql && sudo docker pull wordpress && sudo docker pull phpmyadmin``  

* verificar se as imagens disponiveis e o ID.  
``sudo docker images``  

* vamos criar um ambiente para subir o mysql.  

* criando um volume para arquivos mysql.  
``sudo docker volume create arqmysql``  

* listar os volumes  
``sudo docker volume ls``  

* vamos criar uma rede para comunir dois containeres.
``sudo docker network create dvilanovarede``  

* vamos subir a maquina de mysql (vou explicar os parametros usados)  
``sudo docker run -d -v /arqmysql:/var/lib/mysql --name dvilanovamysql -e MYSQL_ROOT_PASSWORD=GAud4mZby8F3SD6P -p 3306:3306 --network dvilanovarede mysql``  

-d faz com que o processo seja em background.  
-v “volumeLocal:localDoContainer” Este parâmetro faz o volume funcionar, dizendo para que o volume receba os arquivos vindos da pasta ‘/var/lib/mysql’ que é onde as alterações do banco são salvas.  
--name Da um nome especificado para o nosso contêiner, no caso ‘dvilanovamysql’.  
-e parâmetros Neste parâmetro, podemos passar parâmetros para dentro do contêiner, para saber quais parâmetros podemos passar, devemos olhar na página do contêiner no docker hub. No nosso caso estamos passando a senha root como GAud4mZby8F3SD6P.  
-p “portaLocal:PortaDoContainer” faz com que uma porta do contêiner seja espelhada na máquina hospedeira, nos permitindo interagir com ela diretamente.  
--network rede onde especificamos que rede queremos que o contêiner faça parte no nosso caso dvilanovarede.  
E por fim chamamos a imagem, no caso o mysql.

* vamos entrar no contêiner mysql criado  
``sudo docker exec -it dvilanovamysql bash``  
``mysql -p GAud4mZby8F3SD6P``

* criação basica de um banco de dados  
``create database dvilanovadatabase``

* vamos criar o contêiner do wordpress.  
* criar um volume para os arquivos wordpress  
``sudo docker volume create arqwordpress``

* subir o container.  
``sudo docker run -d --name dvilanovawordpress --network  dvilanovarede -p 8081:80 -v arqwordpress:/var/www/html wordpress``  

acessar o wordpress: <http://localhost:8081>  
Nome do banco de dados: dvilanovadatabase  
Nome de usuário: root  
Senha: GAud4mZby8F3SD6P  
Servidor do banco de dados: dvilanovamysql  
Prefixo da tabela: wp\_

ps: antes de definir as portas sempre verifique se existe algum serviço em execução, por exemplo, tentei criar o wordpress na porta 80, porem ja existia o serviço do apache2.  

* identifiquei qual o serviço da porta.  
``sudo netstat -pna | grep <numero_da_porta>``

### Extra  
* instalar a imagem do phpmyadmin como interface para manipulação da linguagem SQL.  
``sudo docker pull phpmyadmin``

* criar um volume para os arquivos do phpmyadmin.  
``sudo docker volume create arqphpmyadmin``

* criar o container do phpmyadmin e vincular ao contêiner do mysql.  
``sudo docker run -d --name dvnphpmyadmin  --network dvilanovarede -e PMA_HOST=dvilanovamysql -p 8080:80 -v arqphpmyadmin:/etc/phpmyadmin/config.user.inc.php phpmyadmin``  

para acessar o phpmyadmin: http://localhost:8080/  
username: root  
password: GAud4mZby8F3SD6P  

### Instalação, criação e configuração pelo Docker Compose.
* criando/gerenciando os conteineres com o docker compose.  
* criando arquivo docker-compose.yml e utilizando o editor vscode.  

			services:
			#serviço que representa o container do WordPress.
			  wordpress:
				#a imagem do WordPress pelo Dockerfile. build: . (ele vai buscar o arquivo dockerfile dentro da pasta que está alocado o docker-compose, ja que vai ser no mesmo diretório GiHub)
				build: .
				#depende da inicialização de outro serviço para poder iniciar, no caso mysql
				depends_on:
				  - mysql
				#nome do container
				container_name: dvilanovawordpress
				#Conecta o container a uma rede Docker
				networks:
				  - dvilanovarede
				#mapeia a porta 8081 do host para a porta 80 do container, permitindo acesso via http ao serviço
				ports:
				  - "8081:80"
				#mapeia um volume docker para o arquivo no container, permitindo persistência de dados.
				volumes:
				  - arqwordpress:/var/www/html
				#configura o container para reiniciar sempre que ele parar ou o docker for reiniciado
				restart: always
				#variáveis de ambiente para configurar o wordpress
				environment:
				  WORDPRESS_DB_HOST: dvilanovamysql
				  WORDPRESS_DB_USER: root
				  WORDPRESS_DB_PASSWORD: GAud4mZby8F3SD6P
				  WORDPRESS_DB_NAME: dvilanovadatabase
			
			#serviço que representa o container do MySQL.  
			mysql:
				image: mysql
				container_name: dvilanovamysql
				environment:
				  MYSQL_ROOT_PASSWORD: GAud4mZby8F3SD6P
				  MYSQL_DATABASE: dvilanovadatabase
				networks:
				  - dvilanovarede
				ports:
				  - "3306:3306"
				volumes:
				  - arqmysql:/var/lib/mysql
				restart: always

			  phpmyadmin:
				image: phpmyadmin
				depends_on:
				  - mysql
				container_name: dvnphpmyadmin
				environment:
				  PMA_HOST: dvilanovamysql
				  MYSQL_ROOT_PASSWORD: GAud4mZby8F3SD6P
				networks:
				  - dvilanovarede
				ports:
				  - "8080:80"
				volumes:
				  - arqphpmyadmin:/etc/phpmyadmin/config.user.inc.php
				restart: always
				
			#criação da rede docker para comunicação entre os containers
			networks:
			  dvilanovarede:
			
			#criação dos volumes de cada container
			volumes:
			  arqwordpress:
			  arqphpmyadmin:
			  arqmysql:


### Criação do Dockerfile

		# Use a imagem oficial do WordPress como base
		FROM wordpress:latest

		# Optional: Defina variáveis de ambiente para configuração do WordPress, porem no docker-compose ja tem.
		# ENV WORDPRESS_DB_HOST=db:3306
		# ENV WORDPRESS_DB_USER=wordpress
		# ENV WORDPRESS_DB_PASSWORD=GAud4mZby8F3SD6P
		# ENV WORDPRESS_DB_NAME=wordpress

		# Exponha a porta padrão do WordPress
		EXPOSE 8081

		# Configure o ponto de entrada para iniciar o WordPress
		CMD ["apache2-foreground"]

### Criação do script (setup.sh) para automatização das configurações da VM

		#!/bin/bash

		set -e
		# Instalar dependências
		sudo apt-get update
		sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
		# Adicionar chave GPG do Docker
		sudo install -m 0755 -d /etc/apt/keyrings
		sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
		sudo chmod a+r /etc/apt/keyrings/docker.asc
		# Adicionar repositório do Docker
		echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
		$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		# Atualizar o apt
		sudo apt-get update
		# Instalar o Docker
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
		# Instalação do Docker Compose
		echo "Instalando Docker Compose..."
		sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
		# Permissões de execução para o Docker Compose
		sudo chmod +x /usr/local/bin/docker-compose
		# Baixar o docker-compose.yml e Dockerfile do GitHub
		sudo curl -L -o /home/azureuser/Dockerfile https://github.com/diogovilanova/Desafio-Extra---DevOps/raw/main/Dockerfile
		sudo curl -L -o /home/azureuser/docker-compose.yml https://github.com/diogovilanova/Desafio-Extra---DevOps/raw/main/docker-compose.yml
		# Verificar se o arquivo docker-compose.yml foi baixado
		echo "Arquivo docker-compose.yml:"
		ls -la /home/azureuser/docker-compose.yml
		# Mudar para o diretório correto
		echo "Mudando para o diretório /home/azureuser..."
		cd /home/azureuser
		# Verificar se a mudança de diretório foi bem-sucedida
		echo "Diretório atual após cd:"
		pwd
		# Rodar o docker-compose
		echo "Iniciando containers com Docker Compose..."
		sudo docker-compose up -d
		echo "Script concluído."

### Criação automatizada da VM azure com o Terraform e autenticação com o Azure CLI

* Instalação do azure CLI.
* Atualize o sistema.  
``sudo apt update``

* Instale os pacotes necessários.  
``sudo apt install ca-certificates curl apt-transport-https lsb-release gnupg``

* Adicione o repositório do Azure CLI.  
``curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash``

* Verifique se o Azure CLI foi instalado corretamente.  
``az --version``

* Instalção do Terraform.
* Atualize o Sistema e Instale Dependências.  
``sudo apt-get update && sudo apt-get install -y gnupg software-properties-common``

* Instale a Chave GPG da HashiCorp.  
``wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg``

* Adicione o Repositório HashiCorp.  
``echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list``

* Baixe as Informações do Pacote.  
``sudo apt update``

* Instale o Terraform.  
``sudo apt-get install terraform``

* Autenticação do Azure CLI

* Faça login no Azure CLI.  
``az login``  
Isso abrirá uma página da web para que você possa fazer login com suas credenciais do Azure. Após o login, o Azure CLI será autenticado.

* Verifique a assinatura padrão.  
``az account show``  
Certifique-se de que a assinatura correta está sendo usada.

* Entre na pasta do projeto pelo terminal.

* Entre com o seu editor, no meu caso utilizei o vscode e cri um arquivo main.tf

* Inicialize o diretório do Terraform e baixar as dependencias do terraform na pasta do projeto.  
``terraform init``

* Arquivo main.tf

			# Configuração do Terraform
			terraform {
			required_providers {
				azurerm = {
				source  = "hashicorp/azurerm"
				version = "3.112.0"
				}
				tls = {
				source  = "hashicorp/tls"
				version = "4.0.5"
				}
			}
			}

			# Configuração do Microsoft Azure provider
			provider "azurerm" {
			skip_provider_registration = true
			features {}
			}

			# Configuração do TLS Provider, necessário para gerar as Chaves SSH
			provider "tls" {
			}

			# Obter informações sobre o cliente Azure atual, incluindo tenant_id, object_id e subscription_id
			data "azurerm_client_config" "current" {}

			# Criação do Resource Group
			resource "azurerm_resource_group" "rg" {
			name     = "dvilanova-rg"
			location = "East US 2"
			}

			# Criação da Vnet (Virtual Network)
			resource "azurerm_virtual_network" "vnet" {
			name                = "dvilanova-vnet"
			address_space       = ["10.0.0.0/16"]
			location            = azurerm_resource_group.rg.location
			resource_group_name = azurerm_resource_group.rg.name
			}

			# Criação da Subnet
			resource "azurerm_subnet" "subnet" {
			name                 = "dvilanova-subnet"
			resource_group_name  = azurerm_resource_group.rg.name
			virtual_network_name = azurerm_virtual_network.vnet.name
			address_prefixes     = ["10.0.1.0/24"]
			}

			# Criação do Network Security Group (NSG) e Regras de Segurança
			resource "azurerm_network_security_group" "nsg" {
			name                = "dvilanova-nsg"
			location            = azurerm_resource_group.rg.location
			resource_group_name = azurerm_resource_group.rg.name

			security_rule {
				name                       = "AllowSSH"
				priority                   = 1001
				direction                  = "Inbound"
				access                     = "Allow"
				protocol                   = "Tcp"
				source_port_range          = "*"
				destination_port_range     = "22"
				source_address_prefix      = "*"
				destination_address_prefix = "*"
			}

			security_rule {
				name                       = "AllowHTTP"
				priority                   = 1002
				direction                  = "Inbound"
				access                     = "Allow"
				protocol                   = "Tcp"
				source_port_range          = "*"
				destination_port_range     = "80"
				source_address_prefix      = "*"
				destination_address_prefix = "*"
			}
			}

			# Associar NSG à Subnet
			resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
			subnet_id                 = azurerm_subnet.subnet.id
			network_security_group_id = azurerm_network_security_group.nsg.id
			}

			# Criação do Public IP
			resource "azurerm_public_ip" "pip" {
			name                = "dvilanova-pip"
			location            = azurerm_resource_group.rg.location
			resource_group_name = azurerm_resource_group.rg.name
			allocation_method   = "Dynamic"
			sku                 = "Basic"
			}

			# Criação NIC (Network Interface Card) e associação a subnet e public ip
			resource "azurerm_network_interface" "nic" {
			name                = "dvilanova-nic"
			location            = azurerm_resource_group.rg.location
			resource_group_name = azurerm_resource_group.rg.name

			ip_configuration {
				name                          = "internal"
				subnet_id                     = azurerm_subnet.subnet.id
				private_ip_address_allocation = "Dynamic"
				public_ip_address_id          = azurerm_public_ip.pip.id
			}
			}

			# Associar NSG à NIC
			resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
			network_interface_id      = azurerm_network_interface.nic.id
			network_security_group_id = azurerm_network_security_group.nsg.id
			}

			# Criação da Chave Privada TLS, gerando uma chave RSA com 4096 bits (Forte e Segura) para SSH
			resource "tls_private_key" "tls-private" {
			algorithm = "RSA"
			rsa_bits  = 4096
			}

			# Criação do Key Vault e Politica de acesso
			resource "azurerm_key_vault" "keyvault" {
			name                       = "dvilanova-kv"
			location                   = azurerm_resource_group.rg.location
			resource_group_name        = azurerm_resource_group.rg.name
			tenant_id                  = data.azurerm_client_config.current.tenant_id
			sku_name                   = "standard"
			purge_protection_enabled   = true # "false" para continuar na tier free, pois isso protege de soft Delete
			soft_delete_retention_days = 7    # Proteção de exclusão ativada 7 dias, mínimo

			access_policy {
				tenant_id = data.azurerm_client_config.current.tenant_id
				object_id = data.azurerm_client_config.current.object_id

				# Para um tier free diminua a quantidade de secret_permissions para get e list
				secret_permissions = [
				"Get",
				"List",
				"Set",
				"Delete",
				"Recover"
				]
			}
			}

			# Armazenamento da Chave Privada no Key Vault
			resource "azurerm_key_vault_secret" "private_key_secret" {
			name         = "dvilanova-priv-key"
			value        = tls_private_key.tls-private.private_key_pem
			key_vault_id = azurerm_key_vault.keyvault.id
			}

			# Recuperação da Chave Privada do Key Vault,
			data "azurerm_key_vault_secret" "private_key" {
			name         = azurerm_key_vault_secret.private_key_secret.name
			key_vault_id = azurerm_key_vault.keyvault.id
			}

			# Criação da VM (Virtual Machine)
			resource "azurerm_linux_virtual_machine" "vm" {
			name                = "dvilanova-vm"
			location            = azurerm_resource_group.rg.location
			resource_group_name = azurerm_resource_group.rg.name
			size                = "Standard_B1s"
			admin_username      = "azureuser"
			#admin_password                  = "Diogo@2024" # Desativado, pois usarei o SSH
			disable_password_authentication = true # Ativado, pois usarei autenticação SSH
			network_interface_ids           = [azurerm_network_interface.nic.id]

			os_disk {
				name                 = "osdisk"
				caching              = "ReadWrite"
				storage_account_type = "Standard_LRS"
			}

			source_image_reference {
				publisher = "Canonical"
				offer     = "0001-com-ubuntu-server-jammy"
				sku       = "22_04-lts"
				version   = "latest"
			}

			tags = {
				environment = "dev"
			}

			# Configurar a chave pública SSH gerada
			admin_ssh_key {
				username   = "azureuser"
				public_key = tls_private_key.tls-private.public_key_openssh
			}
			# Configuração do Custom Data para execução de script
			custom_data = filebase64("setup.sh")
			}

* Após editar o arquivo terraform main.tf, vamos executar o ``terraform plan`` e ``terraform apply``, mas antes de tudo execute o ``terraform init`` para atualizar o projeto com todas os recursos adicionados no main.tf.

* Novamente, inicialize o diretório do Terraform e baixar as dependencias do terraform na pasta do projeto.  
``terraform init``

* Verifique o plano de execução  
``terraform plan``  
depois executar o terraform plan para gerar um plano de execução das mudanças que o Terraform fará na infraestrutura. Além de retornar qualquer erro existente no seu arquivo main.tf no terminal.

* Aplique a configuração  
``terraform apply``  
depois executar o terraform apply para aplicar todas as mudanças.

PS: Lembre de registrar seu subscription com os seguintes Resource providers: Microsoft.Network, Microsoft.Compute, caso não faça isso dará erro ao executar o ``terraform apply``

* Registrar o Microsoft.Network  
``az provider register --namespace Microsoft.Compute``

* Registrar o Microsoft.Compute  
``az provider register --namespace Microsoft.Compute``

### Conectando na VM pelo terminal local

Logo após a criação vamos conectar na VM pelo terminal local, mas antes precisamos obter a Private Key para conseguir autenticar via SSH com o Azure Key Vault.

* Verificar se ainda estamos autenticados com o Azure CLI  
``az login``

* Em seguida, vamos recuperar a chave privada do Key Vault  
``az keyvault secret show --name dvilanova-priv-key --vault-name dvilanova-kv --query value -o tsv > private_key.pem``  
Esse comando vai salvar a chave privada no arquivo private_key.pem dentro do repositório do projeto.

* Dá permissões adequadas para a chave privada  
``chmod 600 private_key.pem``

* Usando a Azure CLI, execute o seguinte comando para obter o IP público da VM  
``az vm show --resource-group <nome-do-grupo-de-recursos> --name <nome-da-vm> --query "publicIpAddress" --output table``  
Substitua ``<resource-group-name>`` pelo nome do seu grupo de recursos e ``<vm-name>`` pelo nome da sua VM e o ``--output table`` exibirá a saída em uma tabela formatada que deve ser legível diretamente no terminal.  
Nesse caso ficaria:  
``az vm show --resource-group dvilanova-rg --name dvilanova-vm --query "publicIpAddress" --output table``
* Conectando na VM via SSH  
``ssh -i private_key.pem azureuser@<IP_PUBLICO_DA_VM>``  
utilize o ip público da sua VM no lugar de <IP_PUBLICO_DA_VM>. E como o arquivo private_key.pem está dentro do repositório do projeto ele vai autenticar automaticamente com a private key.

Como o terraform roda o ``setup.sh`` sua VM já vai ter o docker, docker-compose e seu sistema atualizado automaticamente, alem de baixar os arquivos Dockerfile e docker-compose.yml, executando os mesmo para fazer toda configuração e criação.