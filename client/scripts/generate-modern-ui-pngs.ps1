# Gera PNGs de chrome UI para layouts/modern-{dark|medium|light}/images/ui/
# NAO gera ui/login/ (pacote separado). NAO gera entergame_button_* legado.
# Uso:
#   .\scripts\generate-modern-ui-pngs.ps1
#   .\scripts\generate-modern-ui-pngs.ps1 -Preset Dark
#   .\scripts\generate-modern-ui-pngs.ps1 -Preset All

param(
    [ValidateSet('Dark', 'Medium', 'Light', 'All')]
    [string]$Preset = 'All'
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$ThemePresets = @{
    Dark = @{
        bgBase       = '#2a2a32'; bgSurface    = '#32323c'; bgElevated   = '#3c3c48'
        bgInset      = '#222228'; bgTitle      = '#383840'; bgTitleBot   = '#2e2e36'
        border       = '#585868'; borderStrong = '#686878'
        hover        = '#484858'; pressed      = '#585868'
        scrollbarTrack  = '#2a2a32'; scrollbarBtn    = '#383840'
        scrollbarBtnH   = '#484858'; scrollbarBtnP   = '#585868'
        scrollbarThumb  = '#686878'; scrollbarThumbH = '#787888'; scrollbarThumbP = '#585868'
        checkboxFill    = '#32323c'; checkboxBorder  = '#585868'
        checkboxChecked = '#484858'; tick            = '#dfdfdf'
        comboArrow      = '#aaaaaa'; miniBtnAccent   = '#888898'
    }
    Medium = @{
        bgBase       = '#484858'; bgSurface    = '#585868'; bgElevated   = '#686878'
        bgInset      = '#404048'; bgTitle      = '#505058'; bgTitleBot   = '#484850'
        border       = '#787888'; borderStrong = '#888898'
        hover        = '#686878'; pressed      = '#787888'
        scrollbarTrack  = '#404048'; scrollbarBtn    = '#505058'
        scrollbarBtnH   = '#686878'; scrollbarBtnP   = '#787888'
        scrollbarThumb  = '#888898'; scrollbarThumbH = '#9898a8'; scrollbarThumbP = '#787888'
        checkboxFill    = '#585868'; checkboxBorder  = '#787888'
        checkboxChecked = '#686878'; tick            = '#e8e8ec'
        comboArrow      = '#c0c0c8'; miniBtnAccent   = '#a0a0ac'
    }
    Light = @{
        bgBase       = '#7B6A72'; bgSurface    = '#848482'; bgElevated   = '#B5A6B2'
        bgInset      = '#5C4D54'; bgTitle      = '#95848C'; bgTitleBot   = '#7B6A72'
        border       = '#6E5D65'; borderStrong = '#8B7A82'
        hover        = '#B5A6B2'; pressed      = '#95848C'
        scrollbarTrack  = '#7B6A72'; scrollbarBtn    = '#95848C'
        scrollbarBtnH   = '#B5A6B2'; scrollbarBtnP   = '#95848C'
        scrollbarThumb  = '#B5A6B2'; scrollbarThumbH = '#D2C5CE'; scrollbarThumbP = '#95848C'
        checkboxFill    = '#848482'; checkboxBorder  = '#6E5D65'
        checkboxChecked = '#B5A6B2'; tick            = '#f5f0e8'
        comboArrow      = '#4e3d45'; miniBtnAccent   = '#8B7A82'
    }
}

function Get-Color($hex) {
    $hex = $hex.TrimStart('#')
    if ($hex.Length -eq 6) {
        return [System.Drawing.Color]::FromArgb(255,
            [Convert]::ToInt32($hex.Substring(0,2),16),
            [Convert]::ToInt32($hex.Substring(2,2),16),
            [Convert]::ToInt32($hex.Substring(4,2),16))
    }
    if ($hex.Length -eq 8) {
        return [System.Drawing.Color]::FromArgb(
            [Convert]::ToInt32($hex.Substring(0,2),16),
            [Convert]::ToInt32($hex.Substring(2,2),16),
            [Convert]::ToInt32($hex.Substring(4,2),16),
            [Convert]::ToInt32($hex.Substring(6,2),16))
    }
    throw "Cor invalida: $hex"
}

function Generate-ThemeUI {
    param([string]$PresetName, [hashtable]$Theme)

    $script:Theme = $Theme
    $script:outDir = Join-Path $clientRoot "layouts\modern-$($PresetName.ToLower())\images\ui"
    New-Item -ItemType Directory -Path $script:outDir -Force | Out-Null
    Get-ChildItem $script:outDir -Filter "*.png" -File | Remove-Item -Force

    function T($key) { return $script:Theme[$key] }

    function New-Bmp($w, $h) { return New-Object System.Drawing.Bitmap $w, $h }

    function Fill-Rect($g, $x, $y, $w, $h, $color) {
        $brush = New-Object System.Drawing.SolidBrush $color
        $g.FillRectangle($brush, $x, $y, $w, $h)
        $brush.Dispose()
    }

    function Save-Bmp($bmp, $name) {
        $path = Join-Path $script:outDir $name
        $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        Write-Host "  $name"
    }

    function New-PanelTile($w, $h, $fillHex, $borderHex) {
        $bmp = New-Bmp $w $h
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        Fill-Rect $g 0 0 $w $h (Get-Color $fillHex)
        if ($borderHex) {
            $pen = New-Object System.Drawing.Pen (Get-Color $borderHex), 1
            $g.DrawRectangle($pen, 0, 0, $w - 1, $h - 1)
            $pen.Dispose()
        }
        $g.Dispose()
        return $bmp
    }

    function Draw-BorderedRect($g, $x, $y, $w, $h, $fill, $border) {
        Fill-Rect $g $x $y $w $h $fill
        $pen = New-Object System.Drawing.Pen $border, 1
        $g.DrawRectangle($pen, $x, $y, [Math]::Max(0, $w - 1), [Math]::Max(0, $h - 1))
        $pen.Dispose()
    }

    function New-ButtonSheet($cellW, $cellH, $fills) {
        $rows = $fills.Count
        $bmp = New-Bmp $cellW ($cellH * $rows)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        $border = Get-Color (T 'border')
        for ($i = 0; $i -lt $rows; $i++) {
            Draw-BorderedRect $g 0 ($i * $cellH) $cellW $cellH (Get-Color $fills[$i]) $border
        }
        $g.Dispose()
        return $bmp
    }

    function New-WindowSheet($w, $h, $border, $topBar) {
        $bmp = New-Bmp $w $h
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        $body = Get-Color (T 'bgSurface')
        $titleTop = Get-Color (T 'bgTitle')
        $titleBot = Get-Color (T 'bgTitleBot')
        $edge = Get-Color (T 'border')
        $edgeStrong = Get-Color (T 'borderStrong')
        Fill-Rect $g 0 0 $w $h $body
        for ($y = 0; $y -lt $topBar; $y++) {
            $t = if ($topBar -le 1) { 0.0 } else { $y / ($topBar - 1) }
            $r = [int]($titleTop.R + ($titleBot.R - $titleTop.R) * $t)
            $gr = [int]($titleTop.G + ($titleBot.G - $titleTop.G) * $t)
            $b = [int]($titleTop.B + ($titleBot.B - $titleTop.B) * $t)
            Fill-Rect $g 0 $y $w 1 ([System.Drawing.Color]::FromArgb(255, $r, $gr, $b))
        }
        $sideSkip = $border + 1
        Fill-Rect $g $sideSkip 0 ($w - 2 * $sideSkip) 1 $edgeStrong
        Fill-Rect $g $sideSkip ($h - 1) ($w - 2 * $sideSkip) 1 $edgeStrong
        Fill-Rect $g 0 $sideSkip 1 ($h - 2 * $sideSkip) $edgeStrong
        Fill-Rect $g ($w - 1) $sideSkip 1 ($h - 2 * $sideSkip) $edgeStrong
        Fill-Rect $g ($sideSkip + 1) 1 ($w - 2 * $sideSkip - 2) 1 $edge
        Fill-Rect $g 1 ($sideSkip + 1) 1 ($h - 2 * $sideSkip - 2) $edge
        $g.Dispose()
        return $bmp
    }

    function New-TextEditTile($w, $h) {
        $bmp = New-Bmp $w $h
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        Fill-Rect $g 1 1 ($w - 2) ($h - 2) (Get-Color (T 'bgElevated'))
        $pen = New-Object System.Drawing.Pen (Get-Color (T 'border')), 1
        $g.DrawRectangle($pen, 0, 0, $w - 1, $h - 1)
        $pen.Dispose()
        $g.Dispose()
        return $bmp
    }

    function Draw-ComboArrow($g, $x, $y, $w, $h) {
        $cx = $x + [int]($w / 2)
        $cy = $y + [int]($h / 2) + 1
        $brush = New-Object System.Drawing.SolidBrush (Get-Color (T 'comboArrow'))
        $pts = @(
            [System.Drawing.Point]::new($cx - 3, $cy - 2),
            [System.Drawing.Point]::new($cx + 3, $cy - 2),
            [System.Drawing.Point]::new($cx, $cy + 2)
        )
        $g.FillPolygon($brush, $pts)
        $brush.Dispose()
    }

    function New-ComboboxSheet() {
        $w = 91; $cellH = 23; $rightW = 19; $leftW = $w - $rightW
        $bmp = New-Bmp $w ($cellH * 4)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        $border = Get-Color (T 'border')
        $fills = @((T 'bgElevated'), (T 'bgSurface'), (T 'bgInset'), (T 'bgSurface'))
        for ($i = 0; $i -lt 4; $i++) {
            $y = $i * $cellH
            $fill = Get-Color $fills[$i]
            Fill-Rect $g 0 $y $leftW $cellH $fill
            Fill-Rect $g $leftW $y $rightW $cellH $fill
            if ($i -lt 3) { Draw-ComboArrow $g $leftW $y $rightW $cellH }
            $pen = New-Object System.Drawing.Pen $border, 1
            $g.DrawRectangle($pen, 0, $y, $w - 1, $cellH - 1)
            $pen.Dispose()
        }
        $g.Dispose()
        return $bmp
    }

    function New-ScrollbarSheet() {
        $bmp = New-Bmp 52 78
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        $track = Get-Color (T 'scrollbarTrack')
        $btn = Get-Color (T 'scrollbarBtn')
        $btnH = Get-Color (T 'scrollbarBtnH')
        $btnP = Get-Color (T 'scrollbarBtnP')
        $thumb = Get-Color (T 'scrollbarThumb')
        $thumbH = Get-Color (T 'scrollbarThumbH')
        $thumbP = Get-Color (T 'scrollbarThumbP')
        function Draw3($bx, $by, $c0, $c1, $c2) {
            Fill-Rect $g $bx $by 13 13 $c0
            Fill-Rect $g ($bx + 13) $by 13 13 $c1
            Fill-Rect $g ($bx + 26) $by 13 13 $c2
        }
        Draw3 0 0 $btn $btnH $btnP
        Draw3 0 13 $btn $btnH $btnP
        Draw3 0 26 $thumb $thumbH $thumbP
        Draw3 0 39 $btn $btnH $btnP
        Draw3 0 52 $btn $btnH $btnP
        Fill-Rect $g 39 0 13 65 $track
        Fill-Rect $g 0 65 52 13 $track
        $g.Dispose()
        return $bmp
    }

    function New-CheckboxSheet() {
        $bmp = New-Bmp 15 60
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        function DrawCell($y, $fill, $borderC, $checked) {
            Fill-Rect $g 0 $y 15 15 (Get-Color $fill)
            $pen = New-Object System.Drawing.Pen (Get-Color $borderC), 1
            $g.DrawRectangle($pen, 1, $y + 1, 12, 12)
            $pen.Dispose()
            if ($checked) {
                $pen = New-Object System.Drawing.Pen (Get-Color (T 'tick')), 2
                $g.DrawLine($pen, 3, $y + 8, 6, $y + 11)
                $g.DrawLine($pen, 6, $y + 11, 12, $y + 4)
                $pen.Dispose()
            }
        }
        DrawCell 0 (T 'checkboxFill') (T 'checkboxBorder') $false
        DrawCell 15 (T 'bgSurface') (T 'border') $false
        DrawCell 30 (T 'checkboxChecked') (T 'borderStrong') $true
        DrawCell 45 (T 'hover') (T 'borderStrong') $true
        $g.Dispose()
        return $bmp
    }

    function New-MiniwindowButtons() {
        $cell = 140; $cols = 8; $rows = 3
        $bmp = New-Bmp ($cell * $cols) ($cell * $rows)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        $fills = @((T 'bgInset'), (T 'hover'), (T 'pressed'))
        $border = Get-Color (T 'border')
        for ($c = 0; $c -lt $cols; $c++) {
            for ($r = 0; $r -lt $rows; $r++) {
                $x = $c * $cell; $y = $r * $cell
                Draw-BorderedRect $g $x $y $cell $cell (Get-Color $fills[$r]) $border
                if ($c -eq 2) {
                    Fill-Rect $g ($x + 58) ($y + 58) 24 24 (Get-Color (T 'miniBtnAccent'))
                }
            }
        }
        $g.Dispose()
        return $bmp
    }

    function New-ItemSlot($w, $h, $blessed) {
        $bmp = New-Bmp $w $h
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        $fill = if ($blessed) { T 'hover' } else { T 'bgSurface' }
        Draw-BorderedRect $g 0 0 $w $h (Get-Color $fill) (Get-Color (T 'border'))
        if ($blessed) {
            $pen = New-Object System.Drawing.Pen (Get-Color (T 'borderStrong')), 1
            $g.DrawRectangle($pen, 1, 1, $w - 3, $h - 3)
            $pen.Dispose()
        }
        $g.Dispose()
        return $bmp
    }

    function New-Progressbar($w, $h) {
        $bmp = New-Bmp $w $h
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        $pen = New-Object System.Drawing.Pen (Get-Color (T 'border')), 1
        $g.DrawRectangle($pen, 0, 0, $w - 1, $h - 1)
        $pen.Dispose()
        $g.Dispose()
        return $bmp
    }

    Write-Host "Gerando PNGs preset $PresetName em $($script:outDir) ..."
    $btnFills = @((T 'bgInset'), (T 'hover'), (T 'pressed'))
    Save-Bmp (New-PanelTile 32 32 (T 'bgSurface') (T 'border')) 'panel_flat.png'
    Save-Bmp (New-PanelTile 32 32 (T 'bgElevated') (T 'border')) 'panel_lightflat.png'
    Save-Bmp (New-WindowSheet 50 54 4 23) 'miniwindow.png'
    Save-Bmp (New-PanelTile 50 54 (T 'bgInset') (T 'border')) 'minipanel.png'
    Save-Bmp (New-PanelTile 32 32 (T 'bgSurface') (T 'border')) 'menubox.png'
    Save-Bmp (New-TextEditTile 32 32) 'textedit.png'
    Save-Bmp (New-PanelTile 51 25 (T 'bgSurface') (T 'border')) 'dark_background.png'
    Save-Bmp (New-ButtonSheet 22 23 $btnFills) 'button.png'
    Save-Bmp (New-ButtonSheet 22 23 $btnFills) 'button_rounded.png'
    Save-Bmp (New-ButtonSheet 22 23 $btnFills) 'button_popupmenu.png'
    Save-Bmp (New-ButtonSheet 22 23 $btnFills) 'button_square.png'
    Save-Bmp (New-ButtonSheet 22 23 @((T 'bgSurface'), (T 'hover'), (T 'pressed'))) 'tabbutton_rounded.png'
    Save-Bmp (New-ButtonSheet 20 21 $btnFills) 'tabbutton_square.png'
    Save-Bmp (New-WindowSheet 92 80 6 27) 'window.png'
    Save-Bmp (New-WindowSheet 45 30 5 12) 'window_headless.png'
    Save-Bmp (New-MiniwindowButtons) 'miniwindow_buttons.png'
    Save-Bmp (New-ScrollbarSheet) 'scrollbar.png'
    Save-Bmp (New-ComboboxSheet) 'combobox_square.png'
    Save-Bmp (New-ComboboxSheet) 'combobox_rounded.png'
    Save-Bmp (New-ComboboxSheet) 'combobox.png'
    Save-Bmp (New-CheckboxSheet) 'checkbox.png'
    Save-Bmp (New-CheckboxSheet) 'checkbox_round.png'
    $cb = New-Bmp 32 16; $g = [System.Drawing.Graphics]::FromImage($cb); $g.Clear([System.Drawing.Color]::Transparent)
    Draw-BorderedRect $g 0 0 16 16 (Get-Color (T 'bgSurface')) (Get-Color (T 'border'))
    Draw-BorderedRect $g 16 0 16 16 (Get-Color (T 'hover')) (Get-Color (T 'borderStrong'))
    $g.Dispose(); Save-Bmp $cb 'colorbox.png'
    Save-Bmp (New-ButtonSheet 10 10 $btnFills) 'spinbox_up.png'
    Save-Bmp (New-ButtonSheet 10 10 $btnFills) 'spinbox_down.png'
    Save-Bmp (New-Progressbar 80 16) 'progressbar.png'
    Save-Bmp (New-Progressbar 80 20) 'progressbar_thick.png'
    Save-Bmp (New-ButtonSheet 12 21 $btnFills) 'arrow_horizontal.png'
    $sh = New-Bmp 32 1; $g = [System.Drawing.Graphics]::FromImage($sh); $g.Clear([System.Drawing.Color]::Transparent)
    Fill-Rect $g 0 0 32 1 (Get-Color (T 'border')); $g.Dispose(); Save-Bmp $sh 'separator_horizontal.png'
    $sv = New-Bmp 1 32; $g = [System.Drawing.Graphics]::FromImage($sv); $g.Clear([System.Drawing.Color]::Transparent)
    Fill-Rect $g 0 0 1 32 (Get-Color (T 'border')); $g.Dispose(); Save-Bmp $sv 'separator_vertical.png'
    Save-Bmp (New-ItemSlot 32 32 $false) 'item.png'
    Save-Bmp (New-ItemSlot 34 34 $true) 'item-blessed.png'
    Save-Bmp (New-PanelTile 61 61 (T 'bgBase') (T 'border')) 'panel_side.png'
    Save-Bmp (New-PanelTile 61 61 (T 'bgBase') (T 'border')) 'panel_map.png'
    Save-Bmp (New-PanelTile 61 61 (T 'bgSurface') (T 'border')) 'panel_bottom.png'
    Save-Bmp (New-PanelTile 61 61 (T 'bgSurface') (T 'border')) 'panel_container.png'
    Save-Bmp (New-PanelTile 59 59 (T 'bgBase') (T 'border')) 'panel_content.png'
    $pt = New-Bmp 256 56; $g = [System.Drawing.Graphics]::FromImage($pt); $g.Clear([System.Drawing.Color]::Transparent)
    Fill-Rect $g 0 0 256 56 (Get-Color (T 'bgSurface'))
    $pen = New-Object System.Drawing.Pen (Get-Color (T 'border')), 1
    $g.DrawLine($pen, 0, 0, 255, 0); $g.DrawLine($pen, 0, 55, 255, 55); $pen.Dispose(); $g.Dispose()
    Save-Bmp $pt 'panel_top.png'
    $pb2 = New-Bmp 942 60; $g = [System.Drawing.Graphics]::FromImage($pb2)
    Fill-Rect $g 0 0 942 60 (Get-Color (T 'bgSurface'))
    $pen = New-Object System.Drawing.Pen (Get-Color (T 'border')), 1
    $g.DrawLine($pen, 0, 0, 941, 0); $g.Dispose(); $pen.Dispose()
    Save-Bmp $pb2 'panel_bottom2.png'
    Save-Bmp (New-PanelTile 40 40 (T 'bgInset') (T 'border')) 'rotate_button.png'
    $iaPath = Join-Path $clientRoot "data\images\ui\icon_add.png"
    if (Test-Path $iaPath) {
        Copy-Item $iaPath (Join-Path $script:outDir "icon_add.png") -Force
        Write-Host "  icon_add.png (copiado)"
    } else {
        $ia = New-Bmp 24 24; $g = [System.Drawing.Graphics]::FromImage($ia); $g.Clear([System.Drawing.Color]::Transparent)
        $pen = New-Object System.Drawing.Pen (Get-Color (T 'borderStrong')), 2
        $g.DrawLine($pen, 12, 6, 12, 18); $g.DrawLine($pen, 6, 12, 18, 12)
        $pen.Dispose(); $g.Dispose(); Save-Bmp $ia 'icon_add.png'
    }
    $count = (Get-ChildItem $script:outDir -Filter "*.png" -File).Count
    Write-Host "Concluido preset ${PresetName}: $count PNGs"
}

$toRun = if ($Preset -eq 'All') { @('Dark','Medium','Light') } else { @($Preset) }
foreach ($p in $toRun) {
    Generate-ThemeUI -PresetName $p -Theme $ThemePresets[$p]
}
