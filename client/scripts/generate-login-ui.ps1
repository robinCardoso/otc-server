# Gera PNGs do pacote Login UI (painel claro + ouro) para layouts/modern/images/ui/login/
# Uso: .\scripts\generate-login-ui.ps1

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$outDir = Join-Path $clientRoot "layouts\modern\images\ui\login"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

function Get-Color($hex) {
    $hex = $hex.TrimStart('#')
    if ($hex.Length -eq 6) {
        return [System.Drawing.Color]::FromArgb(255,
            [Convert]::ToInt32($hex.Substring(0, 2), 16),
            [Convert]::ToInt32($hex.Substring(2, 2), 16),
            [Convert]::ToInt32($hex.Substring(4, 2), 16))
    }
    if ($hex.Length -eq 8) {
        return [System.Drawing.Color]::FromArgb(
            [Convert]::ToInt32($hex.Substring(0, 2), 16),
            [Convert]::ToInt32($hex.Substring(2, 2), 16),
            [Convert]::ToInt32($hex.Substring(4, 2), 16),
            [Convert]::ToInt32($hex.Substring(6, 2), 16))
    }
    throw "Cor invalida: $hex"
}

function New-Bmp($w, $h) { return New-Object System.Drawing.Bitmap $w, $h }

function Fill-Rect($g, $x, $y, $w, $h, $color) {
    $brush = New-Object System.Drawing.SolidBrush $color
    $g.FillRectangle($brush, $x, $y, $w, $h)
    $brush.Dispose()
}

function Set-Pixel($bmp, $x, $y, $color) {
    if ($x -ge 0 -and $y -ge 0 -and $x -lt $bmp.Width -and $y -lt $bmp.Height) {
        $bmp.SetPixel($x, $y, $color)
    }
}

function Save-Bmp($bmp, $name) {
    $path = Join-Path $outDir $name
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  $name"
}

function Draw-OrnateCorner($g, $bmp, $corner, $w, $h, $cornerSize) {
    $gold = Get-Color '#c9a850'
    $goldHi = Get-Color '#e0cc88'
    $goldLo = Get-Color '#8a7030'
    $pen2 = New-Object System.Drawing.Pen $gold, 2
    $penHi = New-Object System.Drawing.Pen $goldHi, 1
    $penLo = New-Object System.Drawing.Pen $goldLo, 1
    $s = [Math]::Max(4, [Math]::Min($cornerSize, [Math]::Min($w, $h) - 2))

    switch ($corner) {
        'TL' {
            $g.DrawLine($pen2, 1, 1, $s, 1)
            $g.DrawLine($pen2, 1, 1, 1, $s)
            $g.DrawLine($penHi, 2, 2, $s - 1, 2)
            $g.DrawLine($penHi, 2, 2, 2, $s - 1)
        }
        'TR' {
            $g.DrawLine($pen2, $w - $s - 1, 1, $w - 2, 1)
            $g.DrawLine($pen2, $w - 2, 1, $w - 2, $s)
            $g.DrawLine($penHi, $w - $s, 2, $w - 3, 2)
            $g.DrawLine($penHi, $w - 3, 2, $w - 3, $s - 1)
        }
        'BL' {
            $g.DrawLine($pen2, 1, $h - 2, $s, $h - 2)
            $g.DrawLine($pen2, 1, $h - $s - 1, 1, $h - 2)
            $g.DrawLine($penHi, 2, $h - 3, $s - 1, $h - 3)
            $g.DrawLine($penHi, 2, $h - $s, 2, $h - 3)
        }
        'BR' {
            $g.DrawLine($pen2, $w - $s - 1, $h - 2, $w - 2, $h - 2)
            $g.DrawLine($pen2, $w - 2, $h - $s - 1, $w - 2, $h - 2)
            $g.DrawLine($penHi, $w - $s, $h - 3, $w - 3, $h - 3)
            $g.DrawLine($penHi, $w - 3, $h - $s, $w - 3, $h - 3)
        }
    }
    $pen2.Dispose(); $penHi.Dispose(); $penLo.Dispose()
}

function New-LoginWindowSheet($w, $h, $border, $topBar) {
    $bmp = New-Bmp $w $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)

    $body = Get-Color '#ede4d4'
    $titleTop = Get-Color '#d8cbb0'
    $titleBot = Get-Color '#cfc0a8'
    $gold = Get-Color '#c9a850'
    $goldHi = Get-Color '#e0cc88'
    $goldLo = Get-Color '#8a7030'
    $outer = Get-Color '#6a5838'

    Fill-Rect $g 0 0 $w $h $body

    for ($y = 0; $y -lt $topBar; $y++) {
        $t = if ($topBar -le 1) { 0.0 } else { $y / ($topBar - 1) }
        $r = [int]($titleTop.R + ($titleBot.R - $titleTop.R) * $t)
        $gr = [int]($titleTop.G + ($titleBot.G - $titleTop.G) * $t)
        $b = [int]($titleTop.B + ($titleBot.B - $titleTop.B) * $t)
        Fill-Rect $g 0 $y $w 1 ([System.Drawing.Color]::FromArgb(255, $r, $gr, $b))
    }

    $sideSkip = $border + 1
    Fill-Rect $g $sideSkip 0 ($w - 2 * $sideSkip) 1 $goldLo
    Fill-Rect $g $sideSkip 1 ($w - 2 * $sideSkip) 1 $gold
    Fill-Rect $g $sideSkip ($h - 2) ($w - 2 * $sideSkip) 1 $gold
    Fill-Rect $g $sideSkip ($h - 1) ($w - 2 * $sideSkip) 1 $goldLo
    Fill-Rect $g 0 $sideSkip 1 ($h - 2 * $sideSkip) $goldLo
    Fill-Rect $g 1 $sideSkip 1 ($h - 2 * $sideSkip) $gold
    Fill-Rect $g ($w - 2) $sideSkip 1 ($h - 2 * $sideSkip) $gold
    Fill-Rect $g ($w - 1) $sideSkip 1 ($h - 2 * $sideSkip) $goldLo

    Draw-OrnateCorner $g $bmp 'TL' $w $h $border
    Draw-OrnateCorner $g $bmp 'TR' $w $h $border
    Draw-OrnateCorner $g $bmp 'BL' $w $h $border
    Draw-OrnateCorner $g $bmp 'BR' $w $h $border

    for ($x = 0; $x -lt $w; $x++) {
        $bmp.SetPixel($x, 0, $outer)
        $bmp.SetPixel($x, $h - 1, $outer)
    }
    for ($y = 0; $y -lt $h; $y++) {
        $bmp.SetPixel(0, $y, $outer)
        $bmp.SetPixel($w - 1, $y, $outer)
    }

    $g.Dispose()
    return $bmp
}

function New-LoginFieldTile($w, $h) {
    $bmp = New-Bmp $w $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $fill = Get-Color '#faf6ee'
    $gold = Get-Color '#c9a850'
    Fill-Rect $g 1 1 ($w - 2) ($h - 2) $fill
    $pen = New-Object System.Drawing.Pen $gold, 1
    $g.DrawRectangle($pen, 0, 0, $w - 1, $h - 1)
    $pen.Dispose()
    $g.Dispose()
    return $bmp
}

function Draw-ComboArrow($g, $x, $y, $w, $h, $color) {
    $cx = $x + [int]($w / 2)
    $cy = $y + [int]($h / 2) + 1
    $brush = New-Object System.Drawing.SolidBrush $color
    $pts = @(
        [System.Drawing.Point]::new($cx - 4, $cy - 2),
        [System.Drawing.Point]::new($cx + 4, $cy - 2),
        [System.Drawing.Point]::new($cx, $cy + 3)
    )
    $g.FillPolygon($brush, $pts)
    $brush.Dispose()
}

function New-LoginComboboxSheet($w, $cellH, $rightW) {
    $rows = 4
    $bmp = New-Bmp $w ($cellH * $rows)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)

    $fills = @('#faf6ee', '#f0e8d8', '#e8dcc8', '#f5efe3')
    $gold = Get-Color '#c9a850'
    $arrow = Get-Color '#6a5838'
    $leftW = $w - $rightW

    for ($i = 0; $i -lt $rows; $i++) {
        $y = $i * $cellH
        Fill-Rect $g 0 $y $leftW $cellH (Get-Color $fills[$i])
        Fill-Rect $g $leftW $y $rightW $cellH (Get-Color $fills[$i])
        if ($i -lt 3) {
            Draw-ComboArrow $g $leftW $y $rightW $cellH $arrow
        }
        $pen = New-Object System.Drawing.Pen $gold, 1
        $g.DrawRectangle($pen, 0, $y, $w - 1, $cellH - 1)
        $pen.Dispose()
    }

    $g.Dispose()
    return $bmp
}

function Fill-GradientRect($g, $x, $y, $w, $h, $topHex, $botHex) {
    $top = Get-Color $topHex
    $bot = Get-Color $botHex
    for ($row = 0; $row -lt $h; $row++) {
        $t = if ($h -le 1) { 0.0 } else { $row / ($h - 1) }
        $r = [int]($top.R + ($bot.R - $top.R) * $t)
        $gr = [int]($top.G + ($bot.G - $top.G) * $t)
        $b = [int]($top.B + ($bot.B - $top.B) * $t)
        Fill-Rect $g $x ($y + $row) $w 1 ([System.Drawing.Color]::FromArgb(255, $r, $gr, $b))
    }
}

function New-LoginButtonSheet($cellW, $cellH, $states) {
    $rows = $states.Count
    $bmp = New-Bmp $cellW ($cellH * $rows)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $gold = Get-Color '#c9a850'
    $goldLo = Get-Color '#8a7030'

    for ($i = 0; $i -lt $rows; $i++) {
        $y = $i * $cellH
        $st = $states[$i]
        Fill-GradientRect $g 1 1 ($cellW - 2) ($cellH - 2) $st[0] $st[1]
        $pen = New-Object System.Drawing.Pen $goldLo, 1
        $g.DrawRectangle($pen, 0, $y, $cellW - 1, $cellH - 1)
        $pen.Dispose()
        $penHi = New-Object System.Drawing.Pen $gold, 1
        $g.DrawLine($penHi, 2, ($y + 1), ($cellW - 3), ($y + 1))
        $penHi.Dispose()
    }

    $g.Dispose()
    return $bmp
}

function New-LoginListPanelTile($w, $h) {
    $bmp = New-Bmp $w $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $fill = Get-Color '#e0d4c0'
    $gold = Get-Color '#c9a850'
    Fill-Rect $g 1 1 ($w - 2) ($h - 2) $fill
    $pen = New-Object System.Drawing.Pen $gold, 1
    $g.DrawRectangle($pen, 0, 0, $w - 1, $h - 1)
    $pen.Dispose()
    $g.Dispose()
    return $bmp
}

function New-LoginCheckboxSheet($w, $cellH) {
    $rows = 4
    $bmp = New-Bmp $w ($cellH * $rows)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $gold = Get-Color '#c9a850'
    $fill = Get-Color '#faf6ee'
    $tick = Get-Color '#8a6820'

    for ($i = 0; $i -lt $rows; $i++) {
        $y = $i * $cellH
        Fill-Rect $g 1 ($y + 1) ($w - 2) ($cellH - 2) $fill
        $pen = New-Object System.Drawing.Pen $gold, 1
        $g.DrawRectangle($pen, 0, $y, $w - 1, $cellH - 1)
        $pen.Dispose()
        if ($i -ge 2) {
            $penT = New-Object System.Drawing.Pen $tick, 2
            $g.DrawLine($penT, 3, ($y + 8), 6, ($y + 11))
            $g.DrawLine($penT, 6, ($y + 11), 12, ($y + 4))
            $penT.Dispose()
        }
    }

    $g.Dispose()
    return $bmp
}

function New-LoginTitleDiamond($size) {
    $bmp = New-Bmp $size $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $gold = Get-Color '#c9a850'
    $goldHi = Get-Color '#e0cc88'
    $cx = [int]($size / 2)
    $cy = [int]($size / 2)
    $r = [Math]::Max(1, [int](($size - 1) / 2))
    for ($y = 0; $y -lt $size; $y++) {
        for ($x = 0; $x -lt $size; $x++) {
            $md = [Math]::Abs($x - $cx) + [Math]::Abs($y - $cy)
            if ($md -le $r) {
                $bmp.SetPixel($x, $y, $(if ($md -le ($r - 1)) { $gold } else { $goldHi }))
            }
        }
    }
    $g.Dispose()
    return $bmp
}

function New-LoginSeparator($w) {
    $bmp = New-Bmp $w 1
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $c = Get-Color '#66c9a850'
    Fill-Rect $g 0 0 $w 1 $c
    $g.Dispose()
    return $bmp
}

Write-Host "Gerando Login UI pack em $outDir ..."
Save-Bmp (New-LoginWindowSheet 96 88 8 30) 'login_window.png'
Save-Bmp (New-LoginFieldTile 32 32) 'login_field.png'
Save-Bmp (New-LoginComboboxSheet 96 28 22) 'login_combobox.png'
Save-Bmp (New-LoginButtonSheet 24 28 @(
    @('#4a6080', '#3a5070'),
    @('#567090', '#465880'),
    @('#3a5070', '#2a4060')
)) 'login_button_primary.png'
Save-Bmp (New-LoginButtonSheet 24 28 @(
    @('#5a7048', '#4a6040'),
    @('#688058', '#587048'),
    @('#506838', '#405830')
)) 'login_button_secondary.png'
Save-Bmp (New-LoginListPanelTile 32 32) 'login_list_panel.png'
Save-Bmp (New-LoginCheckboxSheet 16 16) 'login_checkbox.png'
Save-Bmp (New-LoginTitleDiamond 9) 'login_title_diamond.png'
Save-Bmp (New-LoginSeparator 32) 'login_separator.png'
Write-Host "Concluido: $((Get-ChildItem $outDir -Filter *.png).Count) PNGs"
