#!/bin/bash

# Actualizar repositorios y paquetes
echo "Actualizando repositorios y paquetes..."
sudo apt update && sudo apt upgrade -y

# Instalar dependencias para Android Studio
echo "Instalando dependencias necesarias..."
sudo apt install -y wget tar unzip lib32z1 openjdk-11-jdk

# Configurar variables de Java
echo "Configurando variables de entorno Java..."
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> ~/.bashrc

# Instalar Android Studio
echo "Descargando Android Studio..."
cd ~
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2024.3.1.13/android-studio-2024.3.1.13-linux.tar.gz
sudo tar -xvzf android-studio-*-linux.tar.gz -C /opt/
sudo chown -R $USER:$USER /opt/android-studio
rm android-studio-*-linux.tar.gz

# Configurar variables de Android
echo "Configurando variables de Android..."
echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >> ~/.bashrc
echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >> ~/.bashrc
echo 'export CAPACITOR_ANDROID_STUDIO_PATH="/opt/android-studio/bin/studio.sh"' >> ~/.bashrc
source ~/.bashrc

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

# Configuración para detectar dispositivos Android
echo "Configurando detección de dispositivos..."
echo "export ADB_SERVER_SOCKET=tcp:$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):5037" >> ~/.bashrc
source ~/.bashrc

# Instalar platform-tools
echo "Instalando Android platform-tools..."
yes | /opt/android-studio/cmdline-tools/latest/bin/sdkmanager --install "platform-tools"

# Finalización
echo "Instalación completada!"
echo "Para detectar dispositivos:"
echo "1. En Windows: instala ADB y ejecuta 'adb -a -P 5037 nodaemon server'"
echo "2. Conecta tu dispositivo Android con depuración USB habilitada"
echo "3. En WSL ejecuta: adb devices"
