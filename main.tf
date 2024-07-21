# Configuração do Terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.112.0"
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
    destination_address_prefix = azurerm_subnet.subnet.address_prefixes[0]
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
    destination_address_prefix = azurerm_subnet.subnet.address_prefixes[0]
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
      "get",
      "list",
      "set",
      "delete",
    ]
  }
}

# Armazenamento da Chave Privada no Key Vault
resource "azurerm_key_vault_secret" "private_key_secret" {
  name         = "dvilanova-private-key"
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
  #Permitir que execute o script/comando na VM, private_key está usando a chave privada para se conectar na VM
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = data.azurerm_key_vault_secret.private_key.value
      host        = azurerm_public_ip.pip.ip_address
    }

    #Linhas de comando do terminal para a instalação do docker, docker compose e start do docker-compose.yml
    inline = [
      # Instalar dependências
      "sudo apt-get update",
      "sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      # Adicionar chave GPG do Docker
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      # Adicionar repositório do Docker
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable'",
      # Atualizar o apt e instalar o Docker
      "sudo apt-get update",
      "sudo apt-get install -y docker-ce",
      # Adicionar usuário ao grupo Docker
      "sudo usermod -aG docker azureuser",
      # Instalar Docker Compose
      "sudo curl -L 'https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose",
      # Permissão de execução para o arquivo docker-compose
      "sudo chmod +x /usr/local/bin/docker-compose",
      # Instalar Git
      "sudo apt-get install -y git",
      # Clonar repositório do GitHub
      "git clone https://github.com/diogovilanova/Desafio-Extra---DevOps.git /home/azureuser/Desafio-Extra",
      # Rodar o docker-compose
      "cd /home/azureuser/Desafio-Extra",
      "sudo docker-compose up -d"
    ]
  }
}