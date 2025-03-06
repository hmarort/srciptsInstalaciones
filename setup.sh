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

# Instalar PgAdmin4 (modo web)
echo "Instalando PgAdmin4..."
curl https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/pgadmin-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/pgadmin-keyring.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/ubuntu $(lsb_release -cs) pgadmin4 main" | sudo tee /etc/apt/sources.list.d/pgadmin4.list
sudo apt update
sudo apt install -y pgadmin4-web

# Configurar PgAdmin4 en modo web
echo "Configurando PgAdmin4..."
sudo /usr/pgadmin4/bin/setup-web.sh

# Finalización
echo "Instalación completada. Asegúrate de configurar Apache y PgAdmin según tus necesidades."