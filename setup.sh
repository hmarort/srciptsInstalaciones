#!/bin/bash

# Actualizar repositorios y paquetes
echo "Actualizando repositorios y paquetes..."
sudo apt update && sudo apt upgrade -y

# Instalar Apache2
echo "Instalando Apache2..."
sudo apt install -y apache2
sudo systemctl enable apache2
sudo systemctl start apache2

# Instalar PHP y extensiones necesarias para CodeIgniter 4
echo "Instalando PHP y extensiones necesarias..."
sudo apt install -y php libapache2-mod-php php-intl php-mbstring php-curl php-json php-xml php-zip

# Reiniciar Apache para cargar PHP
echo "Reiniciando Apache..."
sudo systemctl restart apache2

# Instalar Node.js y npm (requisito para Ionic)
echo "Instalando Node.js y npm..."
sudo apt install -y nodejs npm

# Instalar Ionic CLI globalmente
echo "Instalando Ionic CLI..."
sudo npm install -g @ionic/cli

# Instalar PostgreSQL
echo "Instalando PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable postgresql
sudo systemctl start postgresql

# Configurar PostgreSQL para conexiones remotas
echo "Configurando PostgreSQL..."
sudo sed -i 's/localhost/\*/g' /etc/postgresql/16/main/postgresql.conf
echo "host all all all md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
sudo systemctl restart postgresql

# Abrir el puerto 5432 en el firewall
echo "Abriendo el puerto 5432..."
sudo apt install -y ufw
sudo ufw allow 5432

# Instalar pgAdmin4
echo "Instalando pgAdmin4..."
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'
sudo apt install pgadmin4-web
sudo /usr/pgadmin4/bin/setup-web.sh

# Configurar PgAdmin4 en modo escritorio
echo "Configurando PgAdmin4..."
# No se requiere configuración adicional para el modo escritorio.

# Finalización
echo "Instalación completada. Asegúrate de configurar Apache y PgAdmin según tus necesidades."