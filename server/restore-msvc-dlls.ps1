# Restaura DLLs MSVC para theforgottenserver.exe (apos rodar deploy-runtime-dlls.ps1)
$dst = $PSScriptRoot
$quarantine = Join-Path $dst "_dlls_msvc_nao_usar_com_tfs"

if (-not (Test-Path $quarantine)) {
    Write-Host "Nada para restaurar (pasta _dlls_msvc_nao_usar_com_tfs nao existe)."
    exit 0
}

Get-ChildItem $quarantine -Filter "*.dll" | ForEach-Object {
    Move-Item $_.FullName (Join-Path $dst $_.Name) -Force
    Write-Host "Restaurado: $($_.Name)"
}

Write-Host ""
Write-Host "Agora pode rodar: .\theforgottenserver.exe"
