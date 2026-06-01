# Recoloriza slots de equipamento para tema cinza claro
# Le: data/images/game/slots/  Escreve: layouts/modern/images/game/slots/
# Uso: .\scripts\generate-light-slots.ps1

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$srcDir = Join-Path $clientRoot "data\images\game\slots"
$outDir = Join-Path $clientRoot "layouts\modern\images\game\slots"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

function Get-Color($hex) {
    $hex = $hex.TrimStart('#')
    return [System.Drawing.Color]::FromArgb(255,
        [Convert]::ToInt32($hex.Substring(0,2),16),
        [Convert]::ToInt32($hex.Substring(2,2),16),
        [Convert]::ToInt32($hex.Substring(4,2),16))
}

$bgLight = Get-Color '#e8e8ec'
$bgMid = Get-Color '#d8d8de'
$border = Get-Color '#b8b8c4'

function Recolor-Slot($srcPath, $dstPath) {
    $bmp = [System.Drawing.Bitmap]::FromFile($srcPath)
    $out = New-Object System.Drawing.Bitmap $bmp.Width, $bmp.Height
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            $c = $bmp.GetPixel($x, $y)
            if ($c.A -lt 16) {
                $out.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                continue
            }
            $lum = ($c.R * 0.299 + $c.G * 0.587 + $c.B * 0.114)
            if ($lum -lt 45) {
                $out.SetPixel($x, $y, $border)
            } elseif ($lum -lt 90) {
                $out.SetPixel($x, $y, $bgMid)
            } elseif ($lum -lt 140) {
                $out.SetPixel($x, $y, $bgLight)
            } else {
                $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($c.A, [Math]::Min(255, $c.R + 40), [Math]::Min(255, $c.G + 40), [Math]::Min(255, $c.B + 40)))
            }
        }
    }
    $out.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $out.Dispose()
}

Write-Host "Gerando slots claros em $outDir ..."
Get-ChildItem $srcDir -Filter "*.png" | ForEach-Object {
    Recolor-Slot $_.FullName (Join-Path $outDir $_.Name)
    Write-Host "  $($_.Name)"
}
Write-Host "Concluido: $((Get-ChildItem $outDir -Filter *.png).Count) PNGs"
