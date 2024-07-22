#!/bin/bash
# Caminho para o script principal
SCRIPT_PATH="/home/azureuser/startup_script.sh"

# Função para verificar se há uma conexão SSH
check_ssh_connection() {
  while ! nc -z localhost 22; do
    echo "Esperando conexão SSH..."
    sleep 10
  done
}

# Baixar o script principal e dar permissão
wget -O $SCRIPT_PATH (github)
chmod +x $SCRIPT_PATH

# Esperar pela conexão SSH
check_ssh_connection

# Executar o script principal
#!/bin/bash
# Instalar dependências
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
# Adicionar chave GPG do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Adicionar repositório do Docker
sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable'
# Atualizar o apt e instalar o Docker
sudo apt-get update
sudo apt-get install -y docker-ce
# Adicionar usuário ao grupo Docker
sudo usermod -aG docker azureuser
# Instalar Docker Compose
sudo curl -L 'https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose
# Permissão de execução para o arquivo docker-compose
sudo chmod +x /usr/local/bin/docker-compose
# Instalar Git
sudo apt-get install -y git
# Clonar repositório do GitHub
git clone https://github.com/diogovilanova/Desafio-Extra---DevOps.git /home/azureuser/Desafio-Extra
# Rodar o docker-compose
cd /home/azureuser/Desafio-Extra
sudo docker-compose up -d

