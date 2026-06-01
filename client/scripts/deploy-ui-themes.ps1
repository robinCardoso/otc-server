# Copia PNGs dos presets para paths usados pelo client_theme (troca em runtime)
# Uso: .\scripts\deploy-ui-themes.ps1

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$map = @{
    dark   = "modern-dark"
    medium = "modern-medium"
    light  = "modern-light"
}

foreach ($theme in $map.Keys) {
    $layout = $map[$theme]
    $uiSrc = Join-Path $root "layouts\$layout\images\ui"
    $uiDst = Join-Path $root "data\images\ui\theme\$theme"
    if (-not (Test-Path $uiSrc)) {
        Write-Error "Faltam PNGs em $uiSrc. Rode generate-modern-ui-pngs.ps1 primeiro."
    }
    New-Item -ItemType Directory -Path $uiDst -Force | Out-Null
    Copy-Item (Join-Path $uiSrc "*.png") $uiDst -Force
    Write-Host "UI theme ${theme}: $((Get-ChildItem $uiDst -Filter *.png).Count) PNGs"

    $slotSrc = Join-Path $root "layouts\$layout\images\game\slots"
    $slotDst = Join-Path $root "data\images\game\slots\theme\$theme"
    if (Test-Path $slotSrc) {
        New-Item -ItemType Directory -Path $slotDst -Force | Out-Null
        Copy-Item (Join-Path $slotSrc "*.png") $slotDst -Force
        Write-Host "Slots theme ${theme}: $((Get-ChildItem $slotDst -Filter *.png).Count) PNGs"
    }
}

Write-Host "Deploy concluido."
