# Verificar si el script se ejecuta como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Por favor, ejecute este script como administrador." -ForegroundColor Red
    exit
}

# Habilitar la característica de WSL
Write-Host "Habilitando el Subsistema de Windows para Linux (WSL)..." -ForegroundColor Green
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Habilitar la característica de Virtual Machine Platform
Write-Host "Habilitando la Plataforma de Máquina Virtual..." -ForegroundColor Green
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Reiniciar el sistema para aplicar los cambios
Write-Host "Reiniciando el sistema para aplicar los cambios..." -ForegroundColor Yellow
shutdown.exe /r /t 10
exit

# Después del reinicio, instalar WSL2 y Ubuntu como distribución predeterminada
Write-Host "Instalando WSL2 y la distribución predeterminada (Ubuntu)..." -ForegroundColor Green
wsl --install

# Confirmar instalación exitosa
Write-Host "Instalación completa. Puede iniciar su distribución de Linux desde el menú de inicio." -ForegroundColor Cyan