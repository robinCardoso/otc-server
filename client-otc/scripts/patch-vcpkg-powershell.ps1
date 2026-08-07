# openssl: fallback powershell.exe quando pwsh (PowerShell Core) nao existe
$VcpkgRoot = "C:\8.6\otserv_860\vcpkg"
$file = "$VcpkgRoot\scripts\cmake\vcpkg_copy_tool_dependencies.cmake"
if (-not (Test-Path $file)) {
    Write-Warning "Nao encontrado: $file"
    return
}
$content = Get-Content $file -Raw
if ($content -match 'find_program\(Z_VCPKG_POWERSHELL_CORE NAMES powershell') {
    Write-Host "Ja corrigido: $file"
    return
}
$old = @'
        find_program(Z_VCPKG_POWERSHELL_CORE pwsh)
        if (NOT Z_VCPKG_POWERSHELL_CORE)
            message(FATAL_ERROR "Could not find PowerShell Core; please open an issue to report this.")
        endif()
'@
$new = @'
        find_program(Z_VCPKG_POWERSHELL_CORE pwsh)
        if (NOT Z_VCPKG_POWERSHELL_CORE)
            find_program(Z_VCPKG_POWERSHELL_CORE NAMES powershell.exe powershell)
        endif()
        if (NOT Z_VCPKG_POWERSHELL_CORE)
            message(FATAL_ERROR "Could not find PowerShell Core; please open an issue to report this.")
        endif()
'@
if ($content -notmatch [regex]::Escape('find_program(Z_VCPKG_POWERSHELL_CORE pwsh)')) {
    Write-Warning "Bloco PowerShell nao encontrado em $file"
    return
}
$content = $content.Replace($old, $new)
Set-Content -Path $file -Value $content -NoNewline
Write-Host "Corrigido: $file"
