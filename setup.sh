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
