# Copia icones HD custom para layouts/modern/images/topbuttons/ (sem resize)
# Com DEFAULT_LAYOUT=modern, o OTC le ESTA pasta antes de data/images/topbuttons/
# Uso: .\scripts\deploy-custom-topbuttons.ps1
#      .\scripts\deploy-custom-topbuttons.ps1 -Source data\images\topbuttons

param(
    [string]$Source = ""
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$dst = Join-Path $root "layouts\modern\images\topbuttons"

if ($Source -eq "") {
    $Source = Join-Path $root "data\images\topbuttons"
} else {
    $Source = Join-Path $root $Source
}

if (-not (Test-Path $Source)) {
    Write-Error "Pasta origem nao encontrada: $Source"
}

$expected = @(
    "analyzers", "audio", "audio_mute", "battle", "bot", "buttons", "combatcontrols",
    "cooldowns", "debug", "healthinfo", "hotkeys", "inventory", "keypad", "logout",
    "minimap", "options", "party", "prey", "prey_window", "quest_tracker", "questlog",
    "shop", "skills", "spelllist", "terminal", "unjustifiedpoints", "viplist", "zoomin", "zoomout"
)

New-Item -ItemType Directory -Path $dst -Force | Out-Null
$files = Get-ChildItem $Source -Filter *.png -File
if ($files.Count -eq 0) {
    Write-Error "Nenhum PNG em $Source"
}

foreach ($f in $files) {
    Copy-Item $f.FullName (Join-Path $dst $f.Name) -Force
}

Write-Host "Deploy: $($files.Count) PNG(s) -> layouts/modern/images/topbuttons/"

$missing = @()
foreach ($name in $expected) {
    if (-not (Test-Path (Join-Path $dst "$name.png"))) {
        $missing += $name
    }
}
if ($missing.Count -gt 0) {
    Write-Host "AVISO: faltam icones usados pelos modulos:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_.png" }
} else {
    Write-Host "Todos os icones esperados pelos modulos estao presentes."
}

Write-Host "Reinicie otclient_gl.exe para ver as mudancas."
