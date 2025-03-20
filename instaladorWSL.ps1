# Verificar si el script se ejecuta como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Por favor, ejecute este script como administrador." -ForegroundColor Red
    exit
}

# Función para verificar si una característica está habilitada
function Is-FeatureEnabled($featureName) {
    $feature = dism.exe /online /get-features | Select-String $featureName
    return $feature -match "Enabled"
}

# Habilitar WSL si no está activado
if (-not (Is-FeatureEnabled "Microsoft-Windows-Subsystem-Linux")) {
    Write-Host "Habilitando el Subsistema de Windows para Linux (WSL)..." -ForegroundColor Green
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    $restartRequired = $true
} else {
    Write-Host "WSL ya está habilitado." -ForegroundColor Yellow
}

# Habilitar la Plataforma de Máquina Virtual si no está activada
if (-not (Is-FeatureEnabled "VirtualMachinePlatform")) {
    Write-Host "Habilitando la Plataforma de Máquina Virtual..." -ForegroundColor Green
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    $restartRequired = $true
} else {
    Write-Host "La Plataforma de Máquina Virtual ya está habilitada." -ForegroundColor Yellow
}

# Reiniciar solo si se han habilitado características nuevas
if ($restartRequired) {
    Write-Host "Es necesario reiniciar para aplicar los cambios. Reiniciando en 10 segundos..." -ForegroundColor Yellow
    shutdown.exe /r /t 10
    exit
}

# Verificar si WSL 2 ya está instalado
$wslVersion = wsl --status 2>$null
if ($wslVersion -match "WSL version: 2") {
    Write-Host "WSL2 ya está instalado." -ForegroundColor Yellow
} else {
    Write-Host "Instalando WSL2..." -ForegroundColor Green
    wsl --install
}

# Verificar si Ubuntu ya está instalado
$installedDistros = wsl --list --verbose 2>$null
if ($installedDistros -match "Ubuntu") {
    Write-Host "Ubuntu ya está instalado como distribución." -ForegroundColor Yellow
} else {
    Write-Host "Instalando Ubuntu como distribución predeterminada..." -ForegroundColor Green
    wsl --install -d Ubuntu
}

Write-Host "Instalación completa. Puede iniciar su distribución de Linux desde el menú de inicio." -ForegroundColor Cyan
