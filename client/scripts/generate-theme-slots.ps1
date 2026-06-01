# Recoloriza slots de equipamento por preset de tema
# Uso:
#   .\scripts\generate-theme-slots.ps1
#   .\scripts\generate-theme-slots.ps1 -Preset Dark

param(
    [ValidateSet('Dark', 'Medium', 'Light', 'All')]
    [string]$Preset = 'All'
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$srcDir = Join-Path $clientRoot "data\images\game\slots"

$SlotColors = @{
    Dark   = @{ bgLight = '#32323c'; bgMid = '#2a2a32'; border = '#585868' }
    Medium = @{ bgLight = '#585868'; bgMid = '#484858'; border = '#787888' }
    Light  = @{ bgLight = '#b0b0bc'; bgMid = '#9898a8'; border = '#9898a8' }
}

function Get-Color($hex) {
    $hex = $hex.TrimStart('#')
    return [System.Drawing.Color]::FromArgb(255,
        [Convert]::ToInt32($hex.Substring(0,2),16),
        [Convert]::ToInt32($hex.Substring(2,2),16),
        [Convert]::ToInt32($hex.Substring(4,2),16))
}

function Recolor-Slot($srcPath, $dstPath, $colors) {
    $bgLight = Get-Color $colors.bgLight
    $bgMid = Get-Color $colors.bgMid
    $border = Get-Color $colors.border
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
                $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($c.A,
                    [Math]::Min(255, $c.R + 20), [Math]::Min(255, $c.G + 20), [Math]::Min(255, $c.B + 20)))
            }
        }
    }
    $out.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $out.Dispose()
}

$toRun = if ($Preset -eq 'All') { @('Dark','Medium','Light') } else { @($Preset) }
foreach ($p in $toRun) {
    $outDir = Join-Path $clientRoot "layouts\modern-$($p.ToLower())\images\game\slots"
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    Write-Host "Gerando slots preset $p em $outDir ..."
    Get-ChildItem $srcDir -Filter "*.png" | ForEach-Object {
        Recolor-Slot $_.FullName (Join-Path $outDir $_.Name) $SlotColors[$p]
        Write-Host "  $($_.Name)"
    }
}
