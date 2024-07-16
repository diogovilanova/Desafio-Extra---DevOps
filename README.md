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

### Instalação e configuração pelo Docker.  
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
``sudo docker run -d --name dvilanovawordpress --network  dvilanovarede -p 80:80 -v arqwordpress:/var/www/html wordpress``  

acessar o wordpress: <http://localhost/dvilanovawordpress>  
Nome do banco de dados: dvilanovadatabase  
Nome de usuário: root  
Senha: GAud4mZby8F3SD6P  
Servidor do banco de dados: dvilanovamysql  
Prefixo da tabela: wp\_

ps: tive que parar o processo do apache2, pois estava usando a porta 80, só assim consegui criar o container do wordpress na porta 80.  

* identifiquei qual o serviço da porta 80.  
``sudo netstat -pna | grep 80`` 

* parei o serviço.  
``sudo service apache2 stop``

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

* criando/gerenciando os conteineres com o docker compose.  
* criando arquivo docker-compose.yml e utilizando o editor vscode.  

			version: '3.8'

			services:
			#serviço que representa o container do WordPress.
			  wordpress:
				#a imagem oficial do WordPress.
				image: wordpress
				#depende da inicialização de outro serviço para poder iniciar, no caso mysql
				depends_on:
				  - mysql
				#nome do container
				container_name: dvilanovawordpress
				#Conecta o container a uma rede Docker
				networks:
				  - dvilanovarede
				#mapeia a porta 80 do host para a porta 80 do container, permitindo acesso via http ao serviço
				ports:
				  - "80:80"
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