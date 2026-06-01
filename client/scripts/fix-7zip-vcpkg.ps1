# Corrige 7z2107-extra.7z com hash errado (vcpkg falha com 404 no 7-zip.org)
$VcpkgRoot = "C:\8.6\otserv_860\vcpkg"
$dest = Join-Path $VcpkgRoot "downloads\7z2107-extra.7z"
$url = "https://web.archive.org/web/20220628215932if_/https://www.7-zip.org/a/7z2107-extra.7z"
$expected = "648d894940bcc29951752d7a8fd18c770ee8d4fd944e17f1a52588e51ca8f58375ba48514538f2e1387786fd812bb86f75fd6bdd0892685cdcafb2989942c848"

Remove-Item $dest -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
$curl = "C:\Program Files\Git\mingw64\bin\curl.exe"
if (Test-Path $curl) {
    & $curl -L -o $dest $url
} else {
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
}
$hash = (Get-FileHash $dest -Algorithm SHA512).Hash.ToLower()
if ($hash -ne $expected) {
    Write-Error "Hash incorreto. Tamanho: $((Get-Item $dest).Length)"
}
Write-Host "OK: $dest ($((Get-Item $dest).Length) bytes)"
