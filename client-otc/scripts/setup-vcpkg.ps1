# Instala vcpkg + dependencias do OTCv8 (x86-windows-static)
# Rodar no PowerShell: .\scripts\setup-vcpkg.ps1

$ErrorActionPreference = "Stop"
$VcpkgRoot = "C:\8.6\otserv_860\vcpkg"
$VcpkgCommit = "3b3bd424827a1f7f4813216f6b32b6c61e386b2e"

# vcpkg 2022 + ports antigos: usar CMake/Ninja do VS, NAO o do MSYS2 (CMake 4.x quebra zlib etc.)
$VsBase = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools"
$VsCmake = Join-Path $VsBase "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
$VsNinja = Join-Path $VsBase "Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"
$SevenZip = "${env:ProgramFiles}\7-Zip"
$GitExe = @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files\Git\bin\git.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $GitExe) {
    Write-Error "Git nao encontrado. Instale: https://git-scm.com/download/win"
}
$GitCmd = Split-Path $GitExe -Parent
$GitBin = if (Test-Path "C:\Program Files\Git\bin\git.exe") { "C:\Program Files\Git\bin" } else { $GitCmd }
# CMake/vcpkg (subprocessos) precisam achar git.exe e git.cmd
$env:GIT_EXECUTABLE = $GitExe
$NasmPaths = @(
    "$env:LOCALAPPDATA\bin\NASM",
    "C:\8.6\otserv_860\tools\nasm",
    "C:\8.6\otserv_860\tools\nasm\nasm-3.01"
) | Where-Object { Test-Path "$_\nasm.exe" } | ForEach-Object { $_ }
$NasmPaths = @($NasmPaths)
$pathParts = @($GitCmd, $GitBin, $VsCmake, $VsNinja, $SevenZip) + $NasmPaths + (($env:PATH -split ';') | Where-Object { $_ -and $_ -notmatch 'msys64|mingw64' })
$env:PATH = ($pathParts | Where-Object { $_ } | Select-Object -Unique) -join ';'
Write-Host "Git: $GitExe"

$packages = @(
    "boost-iostreams:x86-windows-static",
    "boost-asio:x86-windows-static",
    "boost-beast:x86-windows-static",
    "boost-system:x86-windows-static",
    "boost-variant:x86-windows-static",
    "boost-lockfree:x86-windows-static",
    "boost-process:x86-windows-static",
    "boost-program-options:x86-windows-static",
    "boost-filesystem:x86-windows-static",
    "boost-uuid:x86-windows-static",
    "luajit:x86-windows-static",
    "glew:x86-windows-static",
    "physfs:x86-windows-static",
    "openal-soft:x86-windows-static",
    "libogg:x86-windows-static",
    "libvorbis:x86-windows-static",
    "zlib:x86-windows-static",
    "libzip:x86-windows-static",
    "openssl:x86-windows-static",
    "bzip2:x86-windows-static",
    "liblzma:x86-windows-static"
)

Write-Host "=== vcpkg root: $VcpkgRoot ===" -ForegroundColor Cyan

$vcpkgGit = Join-Path $VcpkgRoot ".git"
if ((Test-Path $VcpkgRoot) -and -not (Test-Path $vcpkgGit)) {
    Write-Warning "Pasta vcpkg existe mas nao e um repo git (ex.: deletei acidentalmente). Removendo e clonando de novo..."
    Remove-Item $VcpkgRoot -Recurse -Force
}

if (-not (Test-Path $VcpkgRoot)) {
    Write-Host "Clonando vcpkg..."
    & $GitExe clone https://github.com/microsoft/vcpkg.git $VcpkgRoot
    if ($LASTEXITCODE -ne 0) { throw "git clone vcpkg falhou (codigo $LASTEXITCODE)" }
}

function Invoke-VcpkgGit {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $GitExe @GitArgs 2>&1 | Out-Null
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    return $code
}

Push-Location $VcpkgRoot
$head = (& $GitExe rev-parse HEAD 2>$null)
if ($head -ne $VcpkgCommit) {
    Write-Host "Checkout vcpkg $VcpkgCommit ..."
    [void](Invoke-VcpkgGit fetch --depth 1 origin $VcpkgCommit)
    if ((Invoke-VcpkgGit checkout $VcpkgCommit) -ne 0) {
        if ((Invoke-VcpkgGit checkout -f $VcpkgCommit) -ne 0) {
            throw "git checkout $VcpkgCommit falhou"
        }
    }
}

if (-not (Test-Path ".\vcpkg.exe")) {
    Write-Host "Bootstrap vcpkg..."
    .\bootstrap-vcpkg.bat -disableMetrics
}

# 7z extra: apos clone (evita criar vcpkg\ sem .git antes do git clone)
$SevenZipExtra = Join-Path $VcpkgRoot "downloads\7z2107-extra.7z"
$SevenZipExpectedHash = "648d894940bcc29951752d7a8fd18c770ee8d4fd944e17f1a52588e51ca8f58375ba48514538f2e1387786fd812bb86f75fd6bdd0892685cdcafb2989942c848"
$SevenZipWaybackUrl = "https://web.archive.org/web/20220628215932if_/https://www.7-zip.org/a/7z2107-extra.7z"
function Test-7zExtraValid($path) {
    if (-not (Test-Path $path)) { return $false }
    if ((Get-Item $path).Length -lt 900000) { return $false }
    return ((Get-FileHash $path -Algorithm SHA512).Hash.ToLower() -eq $SevenZipExpectedHash)
}
if (-not (Test-7zExtraValid $SevenZipExtra)) {
    Write-Host "Baixando 7z2107-extra.7z (Wayback Machine)..."
    New-Item -ItemType Directory -Force -Path (Split-Path $SevenZipExtra) | Out-Null
    Remove-Item $SevenZipExtra -Force -ErrorAction SilentlyContinue
    $curl = "C:\Program Files\Git\mingw64\bin\curl.exe"
    if (Test-Path $curl) {
        & $curl -L -o $SevenZipExtra $SevenZipWaybackUrl --retry 3
    } else {
        Invoke-WebRequest -Uri $SevenZipWaybackUrl -OutFile $SevenZipExtra -UseBasicParsing
    }
    if (-not (Test-7zExtraValid $SevenZipExtra)) {
        Write-Error "7z2107-extra.7z invalido. Apague $SevenZipExtra e rode o script de novo."
    }
    Write-Host "7z2107-extra.7z OK"
}

$env:VCPKG_ROOT = $VcpkgRoot
$env:VCPKG_DEFAULT_TRIPLET = "x86-windows-static"
$env:VCPKG_FORCE_SYSTEM_BINARIES = "1"
$PkgConfigCandidates = @(
    "C:\msys64\mingw64\bin\pkg-config.exe",
    "C:\msys64\usr\bin\pkg-config.exe",
    "C:\msys64\mingw32\bin\pkg-config.exe"
)
$PkgConfigExe = $PkgConfigCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($PkgConfigExe) {
    $env:PKG_CONFIG = $PkgConfigExe
    Write-Host "PKG_CONFIG: $PkgConfigExe (evita download MSYS2 obsoleto)"
} else {
    Write-Warning "pkg-config nao encontrado. Instale MSYS2 ou rode patch-vcpkg-msys.ps1"
}

& "$PSScriptRoot\patch-vcpkg-git.ps1"
& "$PSScriptRoot\patch-vcpkg-pkgconfig.ps1"
& "$PSScriptRoot\patch-vcpkg-vs2022.ps1"
& "$PSScriptRoot\patch-vcpkg-powershell.ps1"
Write-Host "CMake no PATH: $(Get-Command cmake -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)"
# Patches em vcpkg/scripts/cmake/: pkg-config (MSYS2), v142 -> VS 2022 generator

Write-Host "Instalando pacotes (pode levar 30-90 min)..." -ForegroundColor Yellow
if ($NasmPaths.Count -eq 0) {
    Write-Warning "NASM nao encontrado. Instale em $env:LOCALAPPDATA\bin\NASM ou rode .\scripts\install-nasm.ps1"
} else {
    Write-Host "NASM: $($NasmPaths | Select-Object -First 1)"
}
.\vcpkg.exe install @packages
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "vcpkg install falhou (codigo $LASTEXITCODE). Veja a saida acima."
}

Write-Host "Integrando com Visual Studio..."
.\vcpkg.exe integrate install

Pop-Location
Write-Host "=== vcpkg pronto ===" -ForegroundColor Green
Write-Host "VCPKG_ROOT=$VcpkgRoot"
