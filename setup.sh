#!/bin/bash

# Verificar si el script se ejecuta con sudo
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root o con sudo." 
   exit 1
fi

echo "Actualizando repositorios y paquetes..."
sudo apt update && sudo apt upgrade -y

# Verificar si ya está instalado antes de instalar dependencias
echo "Instalando dependencias necesarias..."
sudo apt install -y wget tar unzip lib32z1 openjdk-11-jdk

# Configurar variables de Java solo si no están configuradas
if ! grep -q "JAVA_HOME" ~/.bashrc; then
    echo "Configurando variables de entorno Java..."
    echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ~/.bashrc
    echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
fi

# Instalar Android Studio solo si no existe
if [ ! -d "/opt/android-studio" ]; then
    echo "Descargando Android Studio..."
    cd /tmp
    wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2024.3.1.13/android-studio-2024.3.1.13-linux.tar.gz
    sudo tar -xvzf android-studio-*-linux.tar.gz -C /opt/
    sudo chown -R $USER:$USER /opt/android-studio
    rm android-studio-*-linux.tar.gz
else
    echo "Android Studio ya está instalado."
fi

# Configurar variables de Android si no están ya configuradas
if ! grep -q "ANDROID_HOME" ~/.bashrc; then
    echo "Configurando variables de Android..."
    echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
    echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >> ~/.bashrc
    echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >> ~/.bashrc
    echo 'export CAPACITOR_ANDROID_STUDIO_PATH="/opt/android-studio/bin/studio.sh"' >> ~/.bashrc
fi

# Instalar Apache2 si no está instalado
if ! dpkg -l | grep -q apache2; then
    echo "Instalando Apache2..."
    sudo apt install -y apache2
    sudo systemctl enable --now apache2
else
    echo "Apache2 ya está instalado."
fi

# Instalar PHP y extensiones necesarias si no están instaladas
if ! dpkg -l | grep -q php; then
    echo "Instalando PHP y extensiones..."
    sudo apt install -y php libapache2-mod-php php-intl php-mbstring php-curl php-json php-xml php-zip
    sudo systemctl restart apache2
else
    echo "PHP ya está instalado."
fi

# Instalar Node.js y npm si no están instalados
if ! dpkg -l | grep -q nodejs; then
    echo "Instalando Node.js y npm..."
    sudo apt install -y nodejs npm
else
    echo "Node.js ya está instalado."
fi

# Instalar Ionic CLI si no está instalado
if ! command -v ionic &> /dev/null; then
    echo "Instalando Ionic CLI..."
    sudo npm install -g @ionic/cli
else
    echo "Ionic CLI ya está instalado."
fi

# Instalar PostgreSQL si no está instalado
if ! dpkg -l | grep -q postgresql; then
    echo "Instalando PostgreSQL..."
    sudo apt install -y postgresql postgresql-contrib
    sudo systemctl enable --now postgresql
else
    echo "PostgreSQL ya está instalado."
fi

# Configurar PostgreSQL solo si no ha sido configurado antes
if ! grep -q "md5" /etc/postgresql/16/main/pg_hba.conf; then
    echo "Configurando PostgreSQL para conexiones remotas..."
    sudo sed -i 's/localhost/\*/g' /etc/postgresql/16/main/postgresql.conf
    echo "host all all all md5" | sudo tee -a /etc/postgresql/16/main/pg_hba.conf
    sudo systemctl restart postgresql
fi

# Abrir el puerto 5432 solo si no está abierto
if ! sudo ufw status | grep -q "5432"; then
    echo "Abriendo el puerto 5432..."
    sudo apt install -y ufw
    sudo ufw allow 5432
else
    echo "El puerto 5432 ya está abierto."
fi

# Instalar pgAdmin4 si no está instalado
if ! dpkg -l | grep -q pgadmin4; then
    echo "Instalando pgAdmin4..."
    curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
    sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list && apt update'
    sudo apt install -y pgadmin4-web
    sudo /usr/pgadmin4/bin/setup-web.sh
else
    echo "pgAdmin4 ya está instalado."
fi

# Configurar detección de dispositivos Android
if ! grep -q "ADB_SERVER_SOCKET" ~/.bashrc; then
    echo "Configurando detección de dispositivos..."
    echo 'export ADB_SERVER_SOCKET=tcp:$(cat /etc/resolv.conf | grep nameserver | awk "{print \$2}"):5037' >> ~/.bashrc
fi

# Instalar platform-tools solo si no está instalado
if [ ! -d "$ANDROID_HOME/platform-tools" ]; then
    echo "Instalando Android platform-tools..."
    yes | /opt/android-studio/cmdline-tools/latest/bin/sdkmanager --install "platform-tools"
else
    echo "Android platform-tools ya está instalado."
fi

echo "Instalación completada!"
echo "Para detectar dispositivos:"
echo "1. En Windows: instala ADB y ejecuta 'adb -a -P 5037 nodaemon server'"
echo "2. Conecta tu dispositivo Android con depuración USB habilitada"
echo "3. En WSL ejecuta: adb devices"