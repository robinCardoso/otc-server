# Copia slots claros para data/images/game/slots/
# Uso: .\scripts\deploy-modern-slots.ps1

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$src = Join-Path $root "layouts\modern\images\game\slots"
$dst = Join-Path $root "data\images\game\slots"

if (-not (Test-Path $src)) {
    Write-Error "Execute primeiro: .\scripts\generate-light-slots.ps1"
}
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Copy-Item (Join-Path $src "*.png") $dst -Force
Write-Host "Deploy: $((Get-ChildItem $dst -Filter *.png).Count) PNGs em data/images/game/slots/"
