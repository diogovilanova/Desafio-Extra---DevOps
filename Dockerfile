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
