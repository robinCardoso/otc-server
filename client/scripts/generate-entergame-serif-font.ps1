# Gera fonte bitmap serif (Cinzel) para labels Enter Game — Modelo C
# Uso: .\scripts\generate-entergame-serif-font.ps1

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$fontDir = Join-Path $clientRoot "layouts\modern\fonts"
$tmpDir = Join-Path $clientRoot "layouts\modern\fonts\_tmp"
New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

$ttfPath = Join-Path $tmpDir "EnterSerif.ttf"
$fontName = "enter-serif-11px"
$fontSize = 11
$glyphW = 16
$glyphH = 16
$firstChar = 32
$lastChar = 255

$cinzelCandidates = @(
    (Join-Path $tmpDir "static\Cinzel-Regular.ttf"),
    (Join-Path $tmpDir "Cinzel-Regular.ttf"),
    $ttfPath
)

$sourceTtf = $null
foreach ($candidate in $cinzelCandidates) {
    if ((Test-Path $candidate) -and ((Get-Item $candidate).Length -gt 50000)) {
        $sourceTtf = $candidate
        break
    }
}

if ($sourceTtf) {
    if ($sourceTtf -ne $ttfPath) {
        Copy-Item $sourceTtf $ttfPath -Force
    }
    Write-Host "Usando fonte: $sourceTtf"
} else {
    $systemSerif = @(
        "$env:WINDIR\Fonts\georgia.ttf",
        "$env:WINDIR\Fonts\times.ttf",
        "$env:WINDIR\Fonts\timesbd.ttf"
    )
    $found = $false
    foreach ($sysFont in $systemSerif) {
        if (Test-Path $sysFont) {
            Copy-Item $sysFont $ttfPath -Force
            Write-Host "Usando fonte serif do sistema: $sysFont"
            $found = $true
            break
        }
    }
    if (-not $found) {
        throw "Cole Cinzel-Regular.ttf em layouts/modern/fonts/_tmp/static/ e rode de novo."
    }
}

$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile($ttfPath)
$family = New-Object System.Drawing.FontFamily($pfc.Families[0].Name, $pfc)
$font = New-Object System.Drawing.Font($family, $fontSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 255, 255))

$cols = 16
$count = $lastChar - $firstChar + 1
$rows = [Math]::Ceiling($count / $cols)
$atlasW = $glyphW * $cols
$atlasH = $glyphH * $rows

$atlas = New-Object System.Drawing.Bitmap $atlasW, $atlasH
$gAtlas = [System.Drawing.Graphics]::FromImage($atlas)
$gAtlas.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
$gAtlas.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$encoding = [System.Text.Encoding]::GetEncoding(1252)

for ($code = $firstChar; $code -le $lastChar; $code++) {
    $idx = $code - $firstChar
    $col = $idx % $cols
    $row = [Math]::Floor($idx / $cols)
    $x = $col * $glyphW
    $y = $row * $glyphH

    $bytes = [byte[]]@($code)
    $ch = $encoding.GetString($bytes)
    if ($code -eq 127 -or $code -eq 129 -or ($code -ge 141 -and $code -le 144) -or $code -eq 157) {
        $ch = [char]0x25A1
    }

    $cell = New-Object System.Drawing.Bitmap $glyphW, $glyphH
    $gCell = [System.Drawing.Graphics]::FromImage($cell)
    $gCell.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $gCell.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $gCell.DrawString($ch, $font, $brush, 0, 0)
    $gCell.Dispose()
    $gAtlas.DrawImage($cell, $x, $y)
    $cell.Dispose()
}

$gAtlas.Dispose()
$font.Dispose()
$brush.Dispose()

$pngPath = Join-Path $fontDir "${fontName}_cp1252.png"
$otfontPath = Join-Path $fontDir "${fontName}.otfont"
$atlas.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
$atlas.Dispose()

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($otfontPath, @"
Font
  name: $fontName
  texture: ${fontName}_cp1252
  height: 14
  glyph-size: 16 16
  space-width: 3
"@ + "`n", $utf8NoBom)

Write-Host "Fonte gerada: $otfontPath"
Write-Host "Textura: $pngPath"
