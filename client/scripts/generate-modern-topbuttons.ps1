# Recoloriza icones do top menu para o tema modern / Modelo C
# Uso: .\scripts\generate-modern-topbuttons.ps1
#      .\scripts\deploy-modern-topbuttons.ps1

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$srcDir = Join-Path $clientRoot "data\images\topbuttons"
$backupDir = Join-Path $srcDir "_retro_backup"
$outDir = Join-Path $clientRoot "layouts\modern\images\topbuttons"
$iconSize = 20
$maxGlyph = 18

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Get-ChildItem $srcDir -Filter *.png | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $backupDir $_.Name) -Force
    }
    Write-Host "Backup retro: $backupDir ($((Get-ChildItem $backupDir -Filter *.png).Count) PNGs)"
}

$sourceDir = if ((Get-ChildItem $backupDir -Filter *.png -ErrorAction SilentlyContinue).Count -gt 0) {
    $backupDir
} else {
    $srcDir
}

function Get-Luminance($c) {
    return (0.299 * $c.R + 0.587 * $c.G + 0.114 * $c.B) / 255.0
}

function Recolor-IconBitmap($srcBmp, $tintR, $tintG, $tintB, $accentR, $accentG, $accentB, $accentThreshold) {
    $out = New-Object System.Drawing.Bitmap $srcBmp.Width, $srcBmp.Height
    for ($y = 0; $y -lt $srcBmp.Height; $y++) {
        for ($x = 0; $x -lt $srcBmp.Width; $x++) {
            $p = $srcBmp.GetPixel($x, $y)
            if ($p.A -lt 8) {
                $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
                continue
            }
            $lum = Get-Luminance $p
            $lum = [Math]::Pow($lum, 0.92)
            if ($lum -ge $accentThreshold) {
                $nr = [int]($accentR * $lum)
                $ng = [int]($accentG * $lum)
                $nb = [int]($accentB * $lum)
            } else {
                $nr = [int]($tintR * $lum)
                $ng = [int]($tintG * $lum)
                $nb = [int]($tintB * $lum)
            }
            $nr = [Math]::Min(255, [Math]::Max(0, $nr))
            $ng = [Math]::Min(255, [Math]::Max(0, $ng))
            $nb = [Math]::Min(255, [Math]::Max(0, $nb))
            $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($p.A, $nr, $ng, $nb))
        }
    }
    return $out
}

function Fit-IconCanvas($srcBmp, $canvasSize, $maxGlyph) {
    $canvas = New-Object System.Drawing.Bitmap $canvasSize, $canvasSize
    $g = [System.Drawing.Graphics]::FromImage($canvas)
    $g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $scale = [Math]::Min($maxGlyph / $srcBmp.Width, $maxGlyph / $srcBmp.Height)
    $w = [int]($srcBmp.Width * $scale)
    $h = [int]($srcBmp.Height * $scale)
    $x = [int](($canvasSize - $w) / 2)
    $y = [int](($canvasSize - $h) / 2)
    $g.DrawImage($srcBmp, $x, $y, $w, $h)
    $g.Dispose()
    return $canvas
}

Write-Host "Gerando topbuttons modern em $outDir"
Write-Host "Fonte: $sourceDir"

$count = 0
Get-ChildItem $sourceDir -Filter *.png | ForEach-Object {
    $name = $_.Name
    if ($name.StartsWith("_")) { return }

    $src = [System.Drawing.Bitmap]::FromFile($_.FullName)
    $isMute = $name -match 'mute|debug'
    $isShop = $name -match 'shop|prey'

    if ($isMute) {
        $recolored = Recolor-IconBitmap $src 200 140 140 230 100 100 0.55
    } elseif ($isShop) {
        $recolored = Recolor-IconBitmap $src 216 200 160 232 212 136 0.50
    } else {
        $recolored = Recolor-IconBitmap $src 216 224 236 232 212 136 0.62
    }
    $src.Dispose()

    $fitted = Fit-IconCanvas $recolored $iconSize $maxGlyph
    $recolored.Dispose()

    $outPath = Join-Path $outDir $name
    $fitted.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $fitted.Dispose()
    Write-Host "  $name"
    $count++
}

Write-Host "Concluido: $count icones em layouts/modern/images/topbuttons/"
