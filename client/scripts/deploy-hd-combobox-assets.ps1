# Gera combobox_square.png / combobox_rounded.png em 91x92 a partir do master HD 540x540.
# Cada faixa HD (540x135) vira uma linha OTC (91x23) — evita distorcer o 9-slice.
#
# Uso (apos editar o HD):
#   .\scripts\deploy-hd-combobox-assets.ps1
#
# Masters HD (540x540): layouts/modern/images/ui/*_hd.png
# Runtime OTC (91x92):  layouts/modern/images/ui/combobox_*.png + data/images/ui/

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$uiDir = Join-Path $clientRoot "layouts\modern\images\ui"
$dataUiDir = Join-Path $clientRoot "data\images\ui"
New-Item -ItemType Directory -Path $dataUiDir -Force | Out-Null

$runtimeW = 91
$runtimeRowH = 23
$runtimeRows = 4
$runtimeH = $runtimeRowH * $runtimeRows

function Export-ComboboxRuntime($masterName) {
    $masterPath = Join-Path $uiDir "${masterName}_hd.png"
    $runtimeName = "${masterName}.png"

    if (-not (Test-Path $masterPath)) {
        $legacyPath = Join-Path $uiDir $runtimeName
        if (Test-Path $legacyPath) {
            $img = [System.Drawing.Image]::FromFile($legacyPath)
            if ($img.Width -ge 512) {
                Write-Host "  Criando master ${masterName}_hd.png a partir de $runtimeName ($($img.Width)x$($img.Height))"
                $img.Save($masterPath, [System.Drawing.Imaging.ImageFormat]::Png)
            }
            $img.Dispose()
        }
    }

    if (-not (Test-Path $masterPath)) {
        Write-Warning "Master nao encontrado: $masterPath"
        return
    }

    $src = [System.Drawing.Image]::FromFile($masterPath)
    $srcRowH = [int][Math]::Round($src.Height / $runtimeRows)
    if ($srcRowH -le 0) {
        throw "Altura invalida no master ${masterName}_hd.png"
    }

    $bmp = New-Object System.Drawing.Bitmap $runtimeW, $runtimeH
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    for ($row = 0; $row -lt $runtimeRows; $row++) {
        $srcY = $row * $srcRowH
        $dstY = $row * $runtimeRowH
        $srcRect = New-Object System.Drawing.Rectangle 0, $srcY, $src.Width, $srcRowH
        $dstRect = New-Object System.Drawing.Rectangle 0, $dstY, $runtimeW, $runtimeRowH
        $g.DrawImage($src, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    }

    $g.Dispose()
    $src.Dispose()

    $outModern = Join-Path $uiDir $runtimeName
    $outData = Join-Path $dataUiDir $runtimeName
    $bmp.Save($outModern, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Save($outData, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()

    Write-Host "  OK $runtimeName (${runtimeW}x${runtimeH}, ${runtimeRows}x${runtimeRowH}px por faixa) <- ${masterName}_hd.png"

    $outPath = Join-Path $uiDir $runtimeName
    $b = Get-ComboboxBorderHints $outPath
    Write-Host "     borders sugeridos: top=$($b.Top) bottom=$($b.Bottom) left=$($b.Left) right=$($b.Right)"
}

function Get-ComboboxBorderHints($pngPath) {
    $bmp = [System.Drawing.Bitmap]::FromFile($pngPath)
    $y = 11
    $maxDiff = 0; $sepX = $bmp.Width - 12
    for ($x = [Math]::Max(40, [int]($bmp.Width * 0.55)); $x -lt $bmp.Width - 2; $x++) {
        $c1 = $bmp.GetPixel($x - 1, $y)
        $c2 = $bmp.GetPixel($x, $y)
        $d = [Math]::Abs($c1.R - $c2.R) + [Math]::Abs($c1.G - $c2.G) + [Math]::Abs($c1.B - $c2.B)
        if ($d -gt $maxDiff) { $maxDiff = $d; $sepX = $x }
    }
    $right = $bmp.Width - $sepX
    $left = 13
    for ($x = 4; $x -lt 20; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -gt 20 -and $c.R -lt 55) { $left = $x; break }
    }
    $top = 4
    $bottom = 5
    $bmp.Dispose()
    return [PSCustomObject]@{ Top = $top; Bottom = $bottom; Left = $left; Right = $right }
}

Write-Host "Deploy combobox runtime (91x92) em $uiDir"
Export-ComboboxRuntime "combobox_square"
Export-ComboboxRuntime "combobox_rounded"
Write-Host "Concluido. Reinicie otclient_gl.exe"
