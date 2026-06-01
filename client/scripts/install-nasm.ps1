# Baixa e instala NASM 3.01 para o vcpkg (evita download quebrado do MSYS2)
# PowerShell: .\scripts\install-nasm.ps1

$ErrorActionPreference = "Stop"
$NasmDir = "C:\8.6\otserv_860\tools\nasm"
$ZipUrl = "https://www.nasm.us/pub/nasm/releasebuilds/3.01/win64/nasm-3.01-win64.zip"
$ZipPath = "$env:TEMP\nasm-3.01-win64.zip"

New-Item -ItemType Directory -Force -Path "C:\8.6\otserv_860\tools" | Out-Null

Write-Host "Baixando NASM 3.01..."
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing

$extract = "$env:TEMP\nasm-extract"
if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
Expand-Archive -Path $ZipPath -DestinationPath $extract -Force

New-Item -ItemType Directory -Force -Path $NasmDir | Out-Null
$inner = Get-ChildItem $extract -Directory | Where-Object { Test-Path (Join-Path $_.FullName "nasm.exe") } | Select-Object -First 1
if ($inner) {
    Copy-Item "$($inner.FullName)\*" $NasmDir -Force
} else {
    Copy-Item "$extract\*" $NasmDir -Force
}

$nasmExe = Join-Path $NasmDir "nasm.exe"
Write-Host "NASM instalado em: $NasmDir"
if (Test-Path $nasmExe) {
    & $nasmExe -v
} else {
    Write-Warning "nasm.exe nao encontrado em $NasmDir. Se usou o instalador, o caminho costuma ser: $env:LOCALAPPDATA\bin\NASM"
}

Write-Host ""
Write-Host "Adicione ao PATH do usuario (uma vez):"
Write-Host "  $NasmDir"
Write-Host ""
Write-Host "Ou rode o setup-vcpkg.ps1 (ja inclui essa pasta no PATH)."
