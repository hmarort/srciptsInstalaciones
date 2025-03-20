#!/bin/bash

# Verificar si el script se ejecuta con sudo
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root o con sudo." 
   exit 1
fi

# Función para verificar instalación
check_installed() {
    dpkg -l | grep -q "$1"
    return $?
}

echo "Actualizando repositorios y paquetes..."
apt update && apt upgrade -y

echo "Instalando dependencias necesarias..."
apt install -y wget tar unzip lib32z1 curl gpg lsb-release apt-transport-https ca-certificates gnupg software-properties-common ufw

# Instalar OpenJDK 17 (versión LTS más reciente)
if ! check_installed openjdk-17-jdk; then
    echo "Instalando OpenJDK 17..."
    apt install -y openjdk-17-jdk
else
    echo "OpenJDK ya está instalado."
fi

# Configurar variables de Java
if ! grep -q "JAVA_HOME=/usr/lib/jvm/java-17" ~/.bashrc; then
    echo "Configurando variables de entorno Java..."
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
    echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
fi

# Obtener la última versión de Android Studio
LATEST_VERSION="2022.3.1.20"  # Verificar la última versión en la web oficial

# Instalar Android Studio
if [ ! -d "/opt/android-studio" ]; then
    echo "Descargando Android Studio..."
    cd /tmp
    wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${LATEST_VERSION}/android-studio-${LATEST_VERSION}-linux.tar.gz
    tar -xzf android-studio-*-linux.tar.gz
    mv android-studio /opt/
    chown -R $SUDO_USER:$SUDO_USER /opt/android-studio
    rm android-studio-*-linux.tar.gz
    
    # Crear acceso directo
    echo "[Desktop Entry]
Version=1.0
Type=Application
Name=Android Studio
Comment=Android Studio
Exec=/opt/android-studio/bin/studio.sh
Icon=/opt/android-studio/bin/studio.svg
Terminal=false
Categories=Development;IDE;" > /usr/share/applications/android-studio.desktop
else
    echo "Android Studio ya está instalado."
fi

# Configurar variables de Android
if ! grep -q "ANDROID_HOME" ~/.bashrc; then
    echo "Configurando variables de Android..."
    echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
    echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >> ~/.bashrc
    echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >> ~/.bashrc
    echo 'export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"' >> ~/.bashrc
    echo 'export CAPACITOR_ANDROID_STUDIO_PATH="/opt/android-studio/bin/studio.sh"' >> ~/.bashrc
fi

# Instalar Apache2
if ! check_installed apache2; then
    echo "Instalando Apache2..."
    apt install -y apache2
    systemctl enable --now apache2
    ufw allow 'Apache'
else
    echo "Apache2 ya está instalado."
fi

# Instalar PHP 8.2 (versión estable más reciente)
if ! check_installed php8.2; then
    echo "Instalando PHP 8.2 y extensiones..."
    add-apt-repository -y ppa:ondrej/php
    apt update
    apt install -y php8.2 php8.2-cli php8.2-common php8.2-intl php8.2-mbstring php8.2-curl php8.2-xml php8.2-zip php8.2-pgsql libapache2-mod-php8.2
    systemctl restart apache2
else
    echo "PHP ya está instalado."
fi

# Instalar Node.js 20 LTS
if ! check_installed nodejs; then
    echo "Instalando Node.js 20 LTS..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    # Verificar instalación
    echo "Node.js $(node -v) instalado"
    echo "npm $(npm -v) instalado"
else
    echo "Node.js ya está instalado."
fi

# Instalar Ionic CLI
echo "Instalando/Actualizando Ionic CLI..."
npm install -g @ionic/cli

# Instalar PostgreSQL 16 (versión más reciente)
if ! check_installed postgresql-16; then
    echo "Instalando PostgreSQL 16..."
    sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    apt update
    apt install -y postgresql-16 postgresql-contrib-16
    systemctl enable --now postgresql
else
    echo "PostgreSQL ya está instalado."
fi

# Configurar PostgreSQL
PG_HBA_PATH=$(find /etc/postgresql -name "pg_hba.conf" | grep 16 | head -n 1)
PG_CONF_PATH=$(find /etc/postgresql -name "postgresql.conf" | grep 16 | head -n 1)

if [ -n "$PG_HBA_PATH" ] && [ -n "$PG_CONF_PATH" ]; then
    if ! grep -q "host all all all md5" "$PG_HBA_PATH"; then
        echo "Configurando PostgreSQL para conexiones remotas..."
        sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" "$PG_CONF_PATH"
        echo "host all all all md5" | tee -a "$PG_HBA_PATH"
        systemctl restart postgresql
    fi
fi

# Abrir puerto PostgreSQL
echo "Configurando firewall para PostgreSQL..."
ufw allow 5432/tcp

# Instalar pgAdmin4 (versión más reciente)
if ! check_installed pgadmin4; then
    echo "Instalando pgAdmin4..."
    curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
    sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
    apt update
    apt install -y pgadmin4-web
    /usr/pgadmin4/bin/setup-web.sh
else
    echo "pgAdmin4 ya está instalado."
fi

# Mejorar la detección de dispositivos Android en WSL
echo "Configurando detección de dispositivos Android en WSL..."

# Añadir configuración específica para WSL en el .bashrc
if ! grep -q "ADB_SERVER_SOCKET" ~/.bashrc; then
    echo '# Configuración para ADB en WSL' >> ~/.bashrc
    echo 'export WSL_HOST=$(cat /etc/resolv.conf | grep nameserver | awk "{print \$2}")' >> ~/.bashrc
    echo 'export ADB_SERVER_SOCKET=tcp:$WSL_HOST:5037' >> ~/.bashrc
    echo 'alias adb-connect="adb kill-server && adb connect $WSL_HOST:5037"' >> ~/.bashrc
fi

# Configurar udev para dispositivos USB (necesario para algunas distribuciones WSL)
if [ ! -f "/etc/udev/rules.d/51-android.rules" ]; then
    echo "Configurando reglas udev para dispositivos Android..."
    echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="*", MODE="0666", GROUP="plugdev"' > /etc/udev/rules.d/51-android.rules
    chmod a+r /etc/udev/rules.d/51-android.rules
fi

# Crear nuestro propio script de puente ADB para WSL (ya que el repo original no está disponible)
echo "Creando script de puente ADB para WSL..."
cat > /usr/local/bin/wsl-adb << 'EOF'
#!/bin/bash

# wsl-adb: ADB bridge for WSL
# Este script facilita la conexión entre ADB en WSL y dispositivos conectados al host Windows

# Obtener la IP del host Windows
WSL_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')

# Función para mostrar ayuda
show_help() {
    echo "wsl-adb: Puente ADB para Windows Subsystem for Linux"
    echo ""
    echo "Uso: wsl-adb [comando]"
    echo ""
    echo "Comandos:"
    echo "  setup      Configura el entorno para conectar con ADB en Windows"
    echo "  connect    Intenta conectar con el servidor ADB en Windows"
    echo "  devices    Muestra los dispositivos conectados"
    echo "  help       Muestra esta ayuda"
    echo ""
    echo "Para usar dispositivos Android con WSL:"
    echo "1. En Windows, ejecuta: adb -a -P 5037 nodaemon server"
    echo "2. En WSL, ejecuta: wsl-adb connect"
    echo ""
}

# Función para configurar el entorno
setup_env() {
    echo "Configurando entorno ADB para WSL..."
    export WSL_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
    export ADB_SERVER_SOCKET=tcp:$WSL_HOST:5037
    echo "Variables de entorno configuradas:"
    echo "  WSL_HOST=$WSL_HOST"
    echo "  ADB_SERVER_SOCKET=$ADB_SERVER_SOCKET"
    echo ""
    echo "Para hacer esta configuración permanente, agregue estas líneas a su ~/.bashrc:"
    echo "  export WSL_HOST=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')"
    echo "  export ADB_SERVER_SOCKET=tcp:\$WSL_HOST:5037"
}

# Función para conectar con el servidor ADB en Windows
connect_adb() {
    echo "Intentando conectar con el servidor ADB en $WSL_HOST:5037..."
    export ADB_SERVER_SOCKET=tcp:$WSL_HOST:5037
    adb kill-server
    echo "Asegúrese de que el servidor ADB esté ejecutándose en Windows con:"
    echo "  adb -a -P 5037 nodaemon server"
    echo ""
    echo "Intentando listar dispositivos..."
    adb devices
}

# Función para mostrar dispositivos
show_devices() {
    export ADB_SERVER_SOCKET=tcp:$WSL_HOST:5037
    echo "Dispositivos conectados a ADB en $WSL_HOST:5037:"
    adb devices -l
}

# Procesar argumentos
case "$1" in
    setup)
        setup_env
        ;;
    connect)
        connect_adb
        ;;
    devices)
        show_devices
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        ;;
esac
EOF

chmod +x /usr/local/bin/wsl-adb

# Crear script de inicialización para ADB en WSL
echo "Creando script de inicialización para ADB..."
cat > /usr/local/bin/init-adb-wsl << 'EOF'
#!/bin/bash

echo "Iniciando puente ADB para WSL..."
HOST_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
export ADB_SERVER_SOCKET=tcp:$HOST_IP:5037
adb kill-server

echo "========================================================"
echo "  CONFIGURACIÓN DE ADB PARA WSL"
echo "========================================================"
echo ""
echo "Para conectar dispositivos Android desde Windows:"
echo ""
echo "1. En Windows, ejecuta esta línea en una terminal CMD/PowerShell:"
echo "   adb -a -P 5037 nodaemon server"
echo ""
echo "2. En tu dispositivo Android:"
echo "   - Activa la Depuración USB en Opciones de desarrollador"
echo "   - Conecta el dispositivo al PC con USB"
echo "   - Acepta la solicitud de depuración USB en el dispositivo"
echo ""
echo "3. En WSL, verifica la conexión con:"
echo "   adb devices"
echo ""
echo "Variables de entorno configuradas:"
echo "  ADB_SERVER_SOCKET=tcp:$HOST_IP:5037"
echo ""
echo "========================================================"
EOF

chmod +x /usr/local/bin/init-adb-wsl

# Crear archivo README con instrucciones
echo "Creando archivo README con instrucciones..."
mkdir -p /opt/dev-setup
cat > /opt/dev-setup/README.md << 'EOF'
# Entorno de Desarrollo en WSL

## Componentes instalados
- OpenJDK 17
- Android Studio
- Apache2
- PHP 8.2
- Node.js 20 LTS
- Ionic CLI
- PostgreSQL 16
- pgAdmin4

## Configuración de Android en WSL

Para conectar dispositivos Android desde WSL:

1. En Windows:
   - Asegúrate de tener adb instalado (viene con Android Studio)
   - Ejecuta en una terminal: `adb -a -P 5037 nodaemon server`

2. En tu dispositivo Android:
   - Activa la depuración USB
   - Conecta el dispositivo a tu PC

3. En WSL:
   - Ejecuta: `init-adb-wsl` o `wsl-adb connect`
   - Verifica la conexión: `adb devices`

## Herramientas de soporte para WSL-ADB
El script de instalación ha creado dos herramientas para facilitar la conectividad:

1. `wsl-adb`: Herramienta principal para gestionar la conexión ADB
   - `wsl-adb setup`: Configura variables de entorno
   - `wsl-adb connect`: Conecta con el servidor ADB en Windows
   - `wsl-adb devices`: Muestra dispositivos conectados

2. `init-adb-wsl`: Script de inicialización rápida
   - Configura todo lo necesario y muestra instrucciones

## Variables de entorno
- JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
- ANDROID_HOME=$HOME/Android/Sdk

## Acceso a pgAdmin4
- URL: http://localhost/pgadmin4
EOF

echo "¡Instalación completada!"
echo "Para cargar las variables de entorno, ejecuta: source ~/.bashrc"
echo "Para configurar Android con WSL, ejecuta: init-adb-wsl"
echo "Consulta la documentación en /opt/dev-setup/README.md para más detalles"