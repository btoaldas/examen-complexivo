# Script de inicio rápido para Windows PowerShell
# Sistema de Banco de Preguntas

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Sistema de Banco de Preguntas - Examen      " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si Docker está instalado
Write-Host "Verificando Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker encontrado: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker no está instalado o no está en PATH" -ForegroundColor Red
    Write-Host "Por favor instala Docker Desktop desde: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    pause
    exit 1
}

# Verificar si Docker Compose está disponible
Write-Host "Verificando Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "✓ Docker Compose encontrado: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose no está disponible" -ForegroundColor Red
    pause
    exit 1
}

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Iniciando sistema...                         " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Levantar los contenedores
Write-Host "Levantando contenedores (esto puede tomar unos minutos la primera vez)..." -ForegroundColor Yellow
docker-compose up -d

# Esperar a que los servicios estén listos
Write-Host ""
Write-Host "Esperando a que los servicios estén listos..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verificar estado de los contenedores
Write-Host ""
Write-Host "Estado de los contenedores:" -ForegroundColor Cyan
docker-compose ps

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  ¡Sistema listo! 🚀                          " -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Accede al sistema en:" -ForegroundColor White
Write-Host "  → Frontend:  http://localhost:5053" -ForegroundColor Cyan
Write-Host "  → Backend:   http://localhost:5052/api" -ForegroundColor Cyan
Write-Host "  → Database:  localhost:5433" -ForegroundColor Cyan
Write-Host ""
Write-Host "Credenciales de Base de Datos:" -ForegroundColor White
Write-Host "  → Usuario:   admin" -ForegroundColor Yellow
Write-Host "  → Password:  admin123" -ForegroundColor Yellow
Write-Host "  → Database:  banco_preguntas" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para ver logs en tiempo real:" -ForegroundColor White
Write-Host "  docker-compose logs -f" -ForegroundColor Gray
Write-Host ""
Write-Host "Para detener el sistema:" -ForegroundColor White
Write-Host "  docker-compose down" -ForegroundColor Gray
Write-Host ""

# Preguntar si quiere abrir el navegador
$response = Read-Host "¿Deseas abrir el sistema en el navegador? (S/N)"
if ($response -eq "S" -or $response -eq "s") {
    Start-Process "http://localhost:5053"
}

Write-Host ""
Write-Host "¡Disfruta del sistema! 😊" -ForegroundColor Green
Write-Host ""
