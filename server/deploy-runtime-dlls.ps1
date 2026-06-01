# DLLs MinGW necessarias para tfs.exe (NAO use com theforgottenserver.exe)
$src = "C:\msys64\mingw64\bin"
$dst = $PSScriptRoot
$quarantine = Join-Path $dst "_dlls_msvc_nao_usar_com_tfs"

if (-not (Test-Path $src)) {
    Write-Error "MSYS2 MinGW64 nao encontrado em $src"
    exit 1
}

New-Item -ItemType Directory -Force -Path $quarantine | Out-Null

# DLLs MSVC antigas que conflitam com tfs.exe (usadas pelo theforgottenserver.exe)
$conflict = @("pugixml.dll", "zlibd1.dll", "zstdd.dll")
foreach ($d in $conflict) {
    $p = Join-Path $dst $d
    if (Test-Path $p) {
        Move-Item $p (Join-Path $quarantine $d) -Force
        Write-Host "Movido para _dlls_msvc_nao_usar_com_tfs: $d"
    }
}

$dlls = @(
    "lua51.dll",
    "libstdc++-6.dll",
    "libgcc_s_seh-1.dll",
    "libwinpthread-1.dll",
    "libgmp-10.dll",
    "libpugixml.dll",
    "libmariadb.dll"
)

foreach ($d in $dlls) {
    Copy-Item (Join-Path $src $d) (Join-Path $dst $d) -Force
    Write-Host "OK: $d"
}

Write-Host ""
Write-Host "tfs.exe      -> use este script antes de rodar"
Write-Host "theforgottenserver.exe -> NAO precisa destas DLLs; usa libmysql.dll (MSVC)"
Write-Host ""
Write-Host "Teste: .\tfs.exe"
