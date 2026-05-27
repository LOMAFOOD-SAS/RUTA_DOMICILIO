<#
Bootstrap PowerShell: convierte esta carpeta en un repo git listo para subir a GitHub.
Uso:
   .\init-repo.ps1
   .\init-repo.ps1 -RemoteUrl "https://github.com/TU_USUARIO/lomafood-ruta-diaria.git"
#>
param(
    [string]$RemoteUrl = ""
)

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

if (Test-Path ".git") {
    Write-Host "Ya existe .git/ — saltando 'git init'."
} else {
    git init -b main
}

git add .
git status

$staged = git diff --cached --name-only
if (-not $staged) {
    Write-Host "No hay cambios para commitear."
} else {
    git commit -m "Initial commit: LOMAFOOD daily route automation"
}

if ($RemoteUrl) {
    $hasOrigin = $false
    try { git remote get-url origin > $null 2>&1; $hasOrigin = $true } catch { $hasOrigin = $false }
    if ($hasOrigin) {
        git remote set-url origin $RemoteUrl
    } else {
        git remote add origin $RemoteUrl
    }
    Write-Host ""
    Write-Host "Subiendo a $RemoteUrl ..."
    git push -u origin main
    Write-Host "Listo."
} else {
    Write-Host ""
    Write-Host "Repo local listo. Para subirlo a GitHub:"
    Write-Host "  1) Crear un repo VACÍO en https://github.com/new (sin README, .gitignore ni LICENSE)"
    Write-Host "  2) git remote add origin https://github.com/TU_USUARIO/lomafood-ruta-diaria.git"
    Write-Host "  3) git push -u origin main"
}
