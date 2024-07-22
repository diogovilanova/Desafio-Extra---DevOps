#!/bin/bash
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
# Atualizar o apt e instalar o Docker e Docker Compose Plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Baixar o docker-compose.yml do GitHub
sudo curl -L -o /home/azureuser/docker-compose.yml https://github.com/diogovilanova/Desafio-Extra---DevOps/raw/main/docker-compose.yml
# Rodar o docker-compose
cd /home/azureuser
sudo docker compose up -d

