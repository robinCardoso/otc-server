# Copia icones modern do top menu para data/images/topbuttons/
# Uso: .\scripts\deploy-modern-topbuttons.ps1

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$src = Join-Path $root "layouts\modern\images\topbuttons"
$dst = Join-Path $root "data\images\topbuttons"

if (-not (Test-Path $src)) {
    Write-Error "Execute primeiro: .\scripts\generate-modern-topbuttons.ps1"
}
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Copy-Item (Join-Path $src "*.png") $dst -Force
Write-Host "Deploy: $((Get-ChildItem $src -Filter *.png).Count) PNGs -> data/images/topbuttons/"
