# Compila otclient_gl.exe e/ou otclient_dx.exe (Win32)
# Pre-requisitos: Visual Studio 2019/2022 com C++ e vcpkg (setup-vcpkg.ps1)
#
# Uso rapido (so OpenGL, ~metade do tempo):
#   .\scripts\build-client.ps1
#   .\scripts\build-client.ps1 -Target OpenGL
# Tudo (OpenGL + DirectX):
#   .\scripts\build-client.ps1 -Target All

param(
    [ValidateSet('OpenGL', 'DirectX', 'All')]
    [string] $Target = 'OpenGL'
)

$ErrorActionPreference = 'Stop'
$DevRoot = Split-Path $PSScriptRoot -Parent
$VcpkgRoot = 'C:\8.6\otserv_860\vcpkg'
$ClientRelease = $DevRoot

$msbuild = @(
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles}\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe",
    "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $msbuild) {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $msbuild = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild `
            -find 'MSBuild\**\Bin\MSBuild.exe' 2>$null | Select-Object -First 1
    }
}

if (-not $msbuild) {
    Write-Error @"
MSBuild nao encontrado. Instale Visual Studio 2019 ou 2022 com:
  - Desenvolvimento para desktop com C++
  - MSVC v142 (VS 2019) ou v143
  - Windows 10/11 SDK
  - Plataforma Win32 (nao so x64)
"@
}

if (Test-Path $VcpkgRoot) {
    $env:VCPKG_ROOT = $VcpkgRoot
}
$vcpkgInstalled = Join-Path $VcpkgRoot 'installed'

$proj = Join-Path $DevRoot 'vc16\otclient.vcxproj'
$configs = switch ($Target) {
    'OpenGL'  { @('OpenGL') }
    'DirectX' { @('DirectX') }
    'All'     { @('OpenGL', 'DirectX') }
}

Write-Host "MSBuild: $msbuild" -ForegroundColor Cyan
Write-Host "Projeto: $proj"
Write-Host "Alvo: $Target" -ForegroundColor Cyan

Push-Location (Join-Path $DevRoot 'vc16')
try {
    foreach ($cfg in $configs) {
        Write-Host "=== $cfg ===" -ForegroundColor Yellow
        & $msbuild $proj /p:Configuration=$cfg /p:Platform=Win32 /m:1 /v:minimal /nologo `
            "/p:VcpkgRoot=$VcpkgRoot" "/p:VcpkgInstalledDir=$vcpkgInstalled"
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
}
finally {
    Pop-Location
}

$exeName = switch ($Target) {
    'DirectX' { 'otclient_dx.exe' }
    default   { 'otclient_gl.exe' }
}
if ($Target -eq 'All') {
    $built = @('otclient_gl.exe', 'otclient_dx.exe')
} else {
    $built = @($exeName)
}

foreach ($name in $built) {
    $e = Join-Path $DevRoot $name
    if (Test-Path $e) {
        Write-Host "OK: $e" -ForegroundColor Green
        if (Test-Path $ClientRelease) {
            $dest = Join-Path $ClientRelease $name
            $srcFull = (Resolve-Path $e).Path
            $destFull = [System.IO.Path]::GetFullPath($dest)
            if ($srcFull -ieq $destFull) {
                Write-Host "Executavel ja em $ClientRelease" -ForegroundColor DarkGray
            } else {
                Copy-Item $e $ClientRelease -Force
                Write-Host "Copiado para $ClientRelease"
            }
        }
    } else {
        Write-Warning "Nao encontrado: $e"
    }
}

Write-Host '=== Build concluido ===' -ForegroundColor Green
