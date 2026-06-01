# Inicia tfs.exe; grava stdout/stderr em data/logs/tfs/ se enableTfsConsoleLog = true em config.lua
# Uso: .\scripts\run-tfs-logged.ps1   ou   rodar-tfs-novo.bat

$ErrorActionPreference = "Continue"
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

function Get-ConfigLuaBoolean {
  param(
    [string]$Key,
    [bool]$Default = $true
  )
  $configPath = Join-Path $Root "config.lua"
  if (-not (Test-Path $configPath)) { return $Default }
  $line = Select-String -Path $configPath -Pattern "^\s*$Key\s*=" | Select-Object -First 1
  if (-not $line) { return $Default }
  $v = ($line.Line -split '=', 2)[1].Trim().TrimEnd(';').Trim()
  if ($v -match '^(?i)true\b') { return $true }
  if ($v -match '^(?i)false\b') { return $false }
  return $Default
}

& "$Root\deploy-runtime-dlls.ps1" | Out-Host

$env:PATH = "$Root;C:\msys64\mingw64\bin;$env:PATH"

$consoleLog = Get-ConfigLuaBoolean -Key 'enableTfsConsoleLog' -Default $true
if (-not $consoleLog) {
  Write-Host ""
  Write-Host "=== TFS (sem log em arquivo: enableTfsConsoleLog = false) ===" -ForegroundColor Cyan
  Write-Host ""
  & "$Root\tfs.exe"
  exit $LASTEXITCODE
}

$logDir = Join-Path $Root "data\logs\tfs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path $logDir "tfs-console_$stamp.log"

Write-Host ""
Write-Host "=== TFS com log em arquivo ===" -ForegroundColor Cyan
Write-Host "Log: $logFile"
Write-Host "Desative com enableTfsConsoleLog = false em config.lua"
Write-Host "Se o cliente mostrar ERROR 10054, compare o horario com as ultimas linhas deste arquivo."
Write-Host ""

$header = @"
=== TFS console log | iniciado $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===
pasta: $Root
mapName: $(if (Test-Path 'config.lua') { (Select-String -Path 'config.lua' -Pattern '^\s*mapName\s*=' | Select-Object -First 1).Line.Trim() } else { '?' })
===
"@
Set-Content -Path $logFile -Value $header -Encoding UTF8

$exitCode = 0
try {
  & "$Root\tfs.exe" 2>&1 | ForEach-Object {
    $line = $_.ToString()
    Write-Host $line
    Add-Content -Path $logFile -Value $line -Encoding UTF8
  }
  if ($LASTEXITCODE) { $exitCode = $LASTEXITCODE }
} catch {
  $msg = ">>> EXCECAO PowerShell: $($_.Exception.Message)"
  Write-Host $msg -ForegroundColor Red
  Add-Content -Path $logFile -Value $msg -Encoding UTF8
  $exitCode = 1
}

$footer = "=== FIM $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | exit=$exitCode ==="
Add-Content -Path $logFile -Value $footer -Encoding UTF8
Write-Host ""
Write-Host $footer -ForegroundColor Yellow
Write-Host "Log salvo: $logFile" -ForegroundColor Cyan

exit $exitCode
