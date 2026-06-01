# Copia PNGs do tema modern para data/images/ui/ (exclui login/ — pacote separado)
# Uso: .\scripts\deploy-modern-ui-to-data.ps1

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$src = Join-Path $root "layouts\modern\images\ui"
$dst = Join-Path $root "data\images\ui"

if (-not (Test-Path $src)) {
    Write-Error "Execute primeiro: .\scripts\generate-modern-ui-pngs.ps1"
}
New-Item -ItemType Directory -Path $dst -Force | Out-Null
Get-ChildItem $src -Filter "*.png" -File | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $dst $_.Name) -Force
}
Write-Host "Deploy: $((Get-ChildItem $src -Filter *.png -File).Count) PNGs em data/images/ui/ (login/ nao tocado)"
