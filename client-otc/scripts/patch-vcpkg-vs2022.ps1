# v142 -> gerador Visual Studio 17 2022 (maquina so tem Build Tools 2022)
$VcpkgRoot = "C:\8.6\otserv_860\vcpkg"
$file = "$VcpkgRoot\scripts\cmake\vcpkg_configure_cmake.cmake"
if (-not (Test-Path $file)) {
    Write-Warning "Nao encontrado: $file"
    return
}
$content = Get-Content $file -Raw
$old = '        elseif("${VCPKG_PLATFORM_TOOLSET}" STREQUAL "v142")' + "`n            set(generator `"Visual Studio 16 2019`")"
$new = '        elseif("${VCPKG_PLATFORM_TOOLSET}" STREQUAL "v142")' + "`n            set(generator `"Visual Studio 17 2022`")"
if ($content -match 'v142"\)\s*\r?\n\s*set\(generator "Visual Studio 17 2022"\)') {
    Write-Host "Ja corrigido: $file"
    return
}
if ($content -notmatch [regex]::Escape('set(generator "Visual Studio 16 2019")')) {
    Write-Warning "Bloco v142/VS2019 nao encontrado em $file"
    return
}
$content = $content.Replace($old, $new)
Set-Content -Path $file -Value $content -NoNewline
Write-Host "Corrigido: $file"
