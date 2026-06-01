# Inventario de assets UI chrome — paths OTUI + dimensoes PNG
# Uso: .\scripts\ui-chrome-inventory.ps1

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$styleDirs = @(
    (Join-Path $clientRoot "data\styles"),
    (Join-Path $clientRoot "layouts\retro\styles"),
    (Join-Path $clientRoot "layouts\modern\styles")
) | Where-Object { Test-Path $_ }

$pngDirs = @(
    (Join-Path $clientRoot "layouts\modern\images"),
    (Join-Path $clientRoot "data\images")
) | Where-Object { Test-Path $_ }

$refs = @{}
foreach ($dir in $styleDirs) {
    Get-ChildItem $dir -Filter *.otui -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $style = $_.BaseName
        [regex]::Matches($content, 'image-source:\s*(/images/[^\s\r\n]+)') | ForEach-Object {
            $path = $_.Groups[1].Value
            if ($path -notmatch '^/images/ui/') { return }
            if (-not $refs.ContainsKey($path)) {
                $refs[$path] = @{ Files = [System.Collections.Generic.HashSet[string]]::new(); Clips = @() }
            }
            [void]$refs[$path].Files.Add($_.Path)
        }
        [regex]::Matches($content, 'image-clip:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)') | ForEach-Object {
            $w = [int]$_.Groups[3].Value; $h = [int]$_.Groups[4].Value
            $refs.Values | ForEach-Object { } # noop
        }
    }
}

# Re-scan with per-file context for clips
foreach ($dir in $styleDirs) {
    Get-ChildItem $dir -Filter *.otui -Recurse | ForEach-Object {
        $rel = $_.FullName.Substring($dir.Length).TrimStart('\')
        $content = Get-Content $_.FullName -Raw
        if ($content -match 'image-source:\s*(/images/ui/[^\s\r\n]+)') {
            $current = $Matches[1]
            [regex]::Matches($content, 'image-clip:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)') | ForEach-Object {
                if ($refs.ContainsKey($current)) {
                    $refs[$current].Clips += "$rel : $($_.Groups[1].Value),$($_.Groups[2].Value) $($_.Groups[3].Value)x$($_.Groups[4].Value)"
                }
            }
        }
    }
}

function Find-Png($logicalPath) {
    $rel = ($logicalPath -replace '^/images/', '') + '.png'
    foreach ($base in $pngDirs) {
        $full = Join-Path $base $rel
        if (Test-Path $full) { return $full }
    }
    return $null
}

$outCsv = Join-Path $clientRoot "ui-asset-inventory.csv"
$rows = @("path,png_width,png_height,png_exists,referenced_in")
foreach ($path in ($refs.Keys | Sort-Object)) {
    $png = Find-Png $path
    $w = ''; $h = ''; $exists = 'no'
    if ($png) {
        $img = [System.Drawing.Image]::FromFile($png)
        $w = $img.Width; $h = $img.Height
        $img.Dispose()
        $exists = 'yes'
    }
    $files = ($refs[$path].Files | Sort-Object) -join ';'
    $rows += "$path,$w,$h,$exists,`"$files`""
}
$rows | Set-Content $outCsv -Encoding UTF8
Write-Host "Inventario: $outCsv ($($refs.Count) paths UI)"
