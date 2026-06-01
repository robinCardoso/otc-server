# Copia estilos/login/topbuttons do layout modern para modern-{dark|medium|light}
# e aplica cores OTUI coerentes com cada preset.
# Uso: .\scripts\sync-login-to-themes.ps1

$ErrorActionPreference = "Stop"
$clientRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}
$srcModern = Join-Path $clientRoot "layouts\modern"
$presets = @('dark', 'medium', 'light')

$OtuiTokens = @{
    dark = @{
        text       = '#dfdfdf'
        textMuted  = '#aaaaaa'
        textDark   = '#dfdfdf'
        panelBg    = '#32323ccc'
        panelLight = '#3c3c48cc'
        hoverBg    = '#484858'
        selectBg   = '#585868'
        accent     = '#8ab4f8'
        consoleBg  = '#32323cee'
        consoleBorder = '#585868'
        resizeBorder  = '#48485888'
        separator  = '#585868'
        chatColor  = '#c87800'
    }
    medium = @{
        text       = '#e8e8ec'
        textMuted  = '#c0c0c8'
        textDark   = '#e8e8ec'
        panelBg    = '#585868cc'
        panelLight = '#686878cc'
        hoverBg    = '#686878'
        selectBg   = '#787888'
        accent     = '#8ab4f8'
        consoleBg  = '#585868ee'
        consoleBorder = '#787888'
        resizeBorder  = '#68687888'
        separator  = '#787888'
        chatColor  = '#d88800'
    }
    light = @{
        text       = '#2e2e38'
        textMuted  = '#4a4a58'
        textDark   = '#2e2e38'
        panelBg    = '#b0b0bccc'
        panelLight = '#c8c8d4cc'
        hoverBg    = '#c8d4e8'
        selectBg   = '#8898b0'
        accent     = '#3a5a98'
        consoleBg  = '#b0b0bcee'
        consoleBorder = '#9898a8'
        resizeBorder  = '#c8d4e888'
        separator  = '#9898a8'
        chatColor  = '#c87800'
    }
}

function Copy-Tree($src, $dst) {
    if (-not (Test-Path $src)) { return }
    New-Item -ItemType Directory -Path $dst -Force | Out-Null
    Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
}

function Write-LabelsOtui($path, $t) {
    $content = @"
Label < UILabel
  font: verdana-11px-antialised
  color: $($t.text)

  `$disabled:
    color: $($t.text)88

FlatLabel < UILabel
  font: verdana-11px-antialised
  color: $($t.text)
  size: 86 20
  text-offset: 3 3
  image-source: /images/ui/panel_flat
  image-border: 1

  `$disabled:
    color: $($t.text)88

MenuLabel < Label

GameLabel < UILabel
  font: verdana-11px-antialised
  color: $($t.text)
"@
    Write-Utf8NoBom $path $content
}

function Patch-FileColors($path, $t, $isDark) {
    if (-not (Test-Path $path)) { return }
    $c = Get-Content $path -Raw -Encoding UTF8
    $text = $t.text
    $hover = $t.hoverBg
    $sel = $t.selectBg

    if ($isDark) {
        $c = $c -replace '#2e2e38', $text
        $c = $c -replace '#2e2e3888', ($text + '88')
        $c = $c -replace '#c8d4e8', $hover
        $c = $c -replace '#8898b0', $sel
        $c = $c -replace '#f2f2f5cc', $t.panelBg
        $c = $c -replace '#ffffffcc', $t.panelLight
        $c = $c -replace 'color: #2e2e38', "color: $text"
    } else {
        # light: ensure dark text on light panels
        $c = $c -replace '#dfdfdf', $text
        $c = $c -replace '#f2f2f5cc', $t.panelBg
        $c = $c -replace '#ffffffcc', $t.panelLight
    }
    Write-Utf8NoBom $path $c
}

function Apply-ThemeOtui($preset, $stylesDir) {
    $t = $OtuiTokens[$preset]
    $isDark = ($preset -ne 'light')

    Write-LabelsOtui (Join-Path $stylesDir '10-labels.otui') $t

    # Copiar base do modern e patch
    $baseFiles = @(
        '10-panels.otui','10-buttons.otui','10-textedits.otui','10-comboboxes.otui',
        '10-checkboxes.otui','10-windows.otui','10-scrollbars.otui','10-separators.otui',
        '10-progressbars.otui','20-tabbars.otui','20-popupmenus.otui','20-topmenu.otui',
        '30-miniwindow.otui','40-console.otui','40-container.otui','40-gamebuttons.otui',
        '39-loginflow.otui','40-entergame.otui','41-entergame.otui'
    )
    $srcStyles = Join-Path $srcModern 'styles'
    foreach ($f in $baseFiles) {
        $src = Join-Path $srcStyles $f
        $dst = Join-Path $stylesDir $f
        if (Test-Path $src) {
            Copy-Item $src $dst -Force
            if ($f -notmatch '^39-loginflow|^40-entergame|^41-entergame') {
                Patch-FileColors $dst $t $isDark
            }
        }
    }

    # Ajustes manuais por preset
    $panels = Join-Path $stylesDir '10-panels.otui'
    if (Test-Path $panels) {
        $p = Get-Content $panels -Raw
        $p = $p -replace '#f2f2f5cc', $t.panelBg
        $p = $p -replace '#ffffffcc', $t.panelLight
        Write-Utf8NoBom $panels $p
    }

    $tabs = Join-Path $stylesDir '20-tabbars.otui'
    if (Test-Path $tabs) {
        $tb = Get-Content $tabs -Raw
        if ($isDark) {
            $tb = $tb -replace 'icon-color: #888888', "icon-color: $($t.textMuted)"
            $tb = $tb -replace 'color: #aaaaaa', "color: $($t.textMuted)"
        } else {
            $tb = $tb -replace 'icon-color: #dfdfdf', "icon-color: $($t.text)"
            $tb = $tb -replace 'color: #dfdfdf', "color: $($t.text)"
            $tb = $tb -replace 'icon-color: #888888', "icon-color: $($t.textMuted)"
            $tb = $tb -replace 'color: #aaaaaa', "color: $($t.textMuted)"
        }
        Write-Utf8NoBom $tabs $tb
    }

    $topmenu = Join-Path $stylesDir '20-topmenu.otui'
    if (Test-Path $topmenu) {
        $tm = Get-Content $topmenu -Raw
        $tm = $tm -replace 'color: #2e2e38', "color: $($t.text)"
        Write-Utf8NoBom $topmenu $tm
    }

    $mini = Join-Path $stylesDir '30-miniwindow.otui'
    if (Test-Path $mini) {
        $m = Get-Content $mini -Raw
        $m = $m -replace 'color: #2e2e38', "color: $($t.text)"
        $m = $m -replace 'background: #c8d4e888', "background: $($t.resizeBorder)"
        Write-Utf8NoBom $mini $m
    }

    $console = Join-Path $stylesDir '40-console.otui'
    if (Test-Path $console) {
        $co = Get-Content $console -Raw
        $co = $co -replace '#f2f2f5ee', $t.consoleBg
        $co = $co -replace '#b8b8c4', $t.consoleBorder
        $co = $co -replace '#c87800', $t.chatColor
        if ($isDark) {
            $co = $co -replace 'selection-color: #2e2e38', "selection-color: $($t.text)"
            $co = $co -replace 'selection-background-color: #c8d4e8', "selection-background-color: $($t.hoverBg)"
        }
        Write-Utf8NoBom $console $co
    }

    $sep = Join-Path $stylesDir '10-separators.otui'
    if (-not (Test-Path $sep)) {
        $sepContent = @"
HorizontalSeparator < UIWidget
  height: 1
  background-color: $($t.separator)

VerticalSeparator < UIWidget
  width: 1
  background-color: $($t.separator)
"@
        Write-Utf8NoBom $sep $sepContent
    }
}

foreach ($preset in $presets) {
    $destRoot = Join-Path $clientRoot "layouts\modern-$preset"
    Write-Host "Sync preset modern-$preset ..."

    # styles + login OTUI
    $stylesDir = Join-Path $destRoot 'styles'
    New-Item -ItemType Directory -Path $stylesDir -Force | Out-Null
    Apply-ThemeOtui $preset $stylesDir

    # login modules (pergaminho igual)
    Copy-Tree (Join-Path $srcModern 'modules\client_entergame') (Join-Path $destRoot 'modules\client_entergame')

    # login PNGs
    Copy-Tree (Join-Path $srcModern 'images\ui\login') (Join-Path $destRoot 'images\ui\login')

    # topbuttons HD (se existir)
    Copy-Tree (Join-Path $srcModern 'images\topbuttons') (Join-Path $destRoot 'images\topbuttons')

    # fonts login
    Copy-Tree (Join-Path $srcModern 'fonts') (Join-Path $destRoot 'fonts')

    # inventory slot override se existir no modern
    $invSrc = Join-Path $srcModern 'styles\40-inventory.otui'
    if (Test-Path $invSrc) {
        Copy-Item $invSrc (Join-Path $stylesDir '40-inventory.otui') -Force
    }

    # skills override: fonte antialised (nao monochrome)
    $skillsSrc = Join-Path $clientRoot 'modules\game_skills\skills.otui'
    $skillsDst = Join-Path $destRoot 'modules\game_skills\skills.otui'
    if (Test-Path $skillsSrc) {
        New-Item -ItemType Directory -Path (Split-Path $skillsDst) -Force | Out-Null
        $sk = Get-Content $skillsSrc -Raw
        $sk = $sk -replace 'verdana-11px-monochrome', 'verdana-11px-antialised'
        Write-Utf8NoBom $skillsDst $sk
    }

    Write-Host "  OK modern-$preset"
}

Write-Host "Sync concluido para: $($presets -join ', ')"
