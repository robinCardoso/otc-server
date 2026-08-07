# Corrige vcpkg 2022: cmake find_program(GIT) nao ve o PATH do PowerShell
$VcpkgRoot = "C:\8.6\otserv_860\vcpkg"
$hintBlock = @'
    set(_vcpkg_git_hints)
    if(DEFINED ENV{GIT_EXECUTABLE})
        get_filename_component(_vcpkg_git_from_env "$ENV{GIT_EXECUTABLE}" DIRECTORY)
        list(APPEND _vcpkg_git_hints "${_vcpkg_git_from_env}")
    endif()
    list(APPEND _vcpkg_git_hints "C:/Program Files/Git/cmd" "C:/Program Files/Git/bin")
'@

$files = @(
    @{
        Path = "$VcpkgRoot\scripts\cmake\z_vcpkg_apply_patches.cmake"
        Old = '    find_program(GIT NAMES git git.cmd REQUIRED)'
        New = $hintBlock + "`n    find_program(GIT NAMES git git.cmd HINTS `${_vcpkg_git_hints} REQUIRED)"
    },
    @{
        Path = "$VcpkgRoot\scripts\cmake\vcpkg_from_git.cmake"
        Old = '        find_program(GIT NAMES git git.cmd)'
        New = $hintBlock.Replace('    ', '        ') + "`n        find_program(GIT NAMES git git.cmd HINTS `${_vcpkg_git_hints})"
    }
)

foreach ($item in $files) {
    if (-not (Test-Path $item.Path)) {
        Write-Warning "Nao encontrado: $($item.Path)"
        continue
    }
    $content = Get-Content $item.Path -Raw
    if ($content -match '_vcpkg_git_hints') {
        Write-Host "Ja corrigido: $($item.Path)"
        continue
    }
    if ($content -notmatch [regex]::Escape($item.Old)) {
        Write-Warning "Padrao git nao encontrado em $($item.Path)"
        continue
    }
    $content = $content.Replace($item.Old, $item.New)
    Set-Content -Path $item.Path -Value $content -NoNewline
    Write-Host "Corrigido: $($item.Path)"
}
