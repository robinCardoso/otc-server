# Copia PNGs do pacote Login UI para data/images/ui/login/
# Uso: .\scripts\deploy-login-ui.ps1

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$src = Join-Path $root "layouts\modern\images\ui\login"
$dst = Join-Path $root "data\images\ui\login"

if (-not (Test-Path $src)) {
    Write-Error "Execute primeiro: .\scripts\generate-login-ui.ps1"
}
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Copy-Item (Join-Path $src "*.png") $dst -Force
Write-Host "Deploy: $((Get-ChildItem $dst -Filter *.png).Count) PNGs em data/images/ui/login/"
