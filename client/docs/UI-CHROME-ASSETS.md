# UI Chrome — assets e tema `modern`

Referência para o reskin flat do OTCv8 (`otcv8-dev-orig`).

## Como funciona

| Camada | Pasta |
|--------|--------|
| Estilos base | `data/styles/*.otui` |
| Layout ativo | `layouts/<nome>/styles/*.otui` (sobrescreve base) |
| PNG | `layouts/<nome>/images/ui/*.png` ou `data/images/ui/*.png` |

`image-source: /images/ui/window` → arquivo `images/ui/window.png` (relativo ao `data/` ou ao layout).

`init.lua`: layout fixo `modern-dark`. Tom in-game: `uiTheme` = `dark` | `medium` | `light` (modulo `client_theme`, **sem reiniciar**).

**Escolha pelo jogador:** Opcoes → Interface → **Tema da interface** (Escuro / Cinza / Claro).

## Temas in-game (presets)

| uiTheme | Tom | Texto UI | bgBase |
|---------|-----|----------|--------|
| `dark` | Escuro (padrao) | `#dfdfdf` | `#2a2a32` |
| `medium` | Cinza medio | `#e8e8ec` | `#484858` |
| `light` | Cinza claro | `#2e2e38` | `#9898a8` |

PNGs runtime: `data/images/ui/theme/{dark|medium|light}/`. Fonte: `layouts/modern-{preset}/`. Deploy: `.\scripts\deploy-ui-themes.ps1`

## Scripts (temas)

```powershell
cd C:\8.6\otserv_860\otcv8-dev-orig
.\scripts\generate-modern-ui-pngs.ps1 -Preset All   # Dark + Medium + Light
.\scripts\generate-theme-slots.ps1 -Preset All
.\scripts\sync-login-to-themes.ps1
.\scripts\deploy-ui-themes.ps1
```

Presets individuais: `-Preset Dark` | `Medium` | `Light`.

## Paleta legada (layout `modern` — referencia login)

| Token | Hex |
|-------|-----|
| bgBase | `#e8e8ec` |
| bgSurface | `#f2f2f5` |
| texto claro | `#2e2e38` |

**Escopo PNG:** `layouts/modern-{preset}/images/ui/`. **Intactos:** `ui/login/` e `topbuttons/` (icones HD).

## Login UI pack (Enter Game + Character List + modais)

Pacote **isolado** em `layouts/modern/images/ui/login/` — painel claro pergaminho + borda dourada, centro liso (9-slice seguro). **Nao** usa `combobox_square.png` global.

| Script | Funcao |
|--------|--------|
| `scripts/generate-login-ui.ps1` | Gera 9 PNGs em `layouts/modern/images/ui/login/` |
| `scripts/deploy-login-ui.ps1` | Copia para `data/images/ui/login/` |

| PNG | Tamanho | OTUI (`39-loginflow.otui`) |
|-----|---------|----------------------------|
| `login_window.png` | 96×88 | `LoginWindow`: `border 8`, `border-top 30` |
| `login_field.png` | 32×32 | `LoginField`: `border 6` |
| `login_combobox.png` | 96×112 (4×28) | `LoginComboBox`: `border 6`, `border-right 22`; popup clip Y=84 |
| `login_button_primary.png` | 24×84 (3×28) | `LoginPrimaryButton`: `border 6` |
| `login_button_secondary.png` | 24×84 (3×28) | `LoginSecondaryButton` |
| `login_list_panel.png` | 32×32 | `LoginListPanel`: `border 4` |
| `login_checkbox.png` | 16×64 (4×16) | `LoginCheckbox` |
| `login_title_diamond.png` | 9×9 | divisor de titulo |
| `login_separator.png` | 32×1 | `LoginSeparator` |

**Estilos:** `layouts/modern/styles/39-loginflow.otui` (widgets `Login*`), `40-entergame.otui` (janelas).

**OTUI override modern:** `layouts/modern/modules/client_entergame/*.otui` (entergame, characterlist, createaccount, createchar).

Resolucao de path: `EnterGame.resolveUiPath(name)` em `entergame.lua`.

**Combobox:** coluna direita 22px fixa (seta); centro `#faf6ee` repetivel.

### Top menu — icones HD (`layouts/modern/images/topbuttons/`)

Com `DEFAULT_LAYOUT = "modern-dark"` (ou outro preset), o OTC resolve `/images/topbuttons/X` **primeiro** em `layouts/<preset>/images/topbuttons/X.png`; depois `layouts/modern/images/topbuttons/`; por fim `data/images/topbuttons/`.

| Item | Detalhe |
|------|---------|
| Pasta ativa (modern) | **`layouts/modern/images/topbuttons/`** — coloque ou copie PNGs HD aqui |
| Deploy custom | `.\scripts\deploy-custom-topbuttons.ps1` (copia de `data/` sem redimensionar) |
| Chrome do botao | `button_top.png` / `button_top_blink.png` (**144×48**, 3×48×48) — `generate-modern-ui-pngs.ps1` |
| Icones na tela | PNG pode ser 96×96+ no disco; OTUI usa `icon-size: 40 40` em `20-topmenu.otui` |
| Botao / barra | `TopButton` **48×48**, `TopMenuPanel` **56** px de altura |
| Nao usar | `generate-modern-topbuttons.ps1` — reduz para 20×20 e apaga qualidade HD |

Reinicie `otclient_gl.exe` apos trocar PNGs (sem hot-reload).

### Painel lateral de botoes (`game_buttons`)

Modulos registram botoes no top menu; com `forceOpen: true`, o modulo [`game_buttons`](c:\8.6\otserv_860\otcv8-dev-orig\modules\game_buttons\buttons.lua) **move** os botoes para o painel direito.

| Arquivo | Funcao |
|---------|--------|
| [`layouts/modern/styles/40-gamebuttons.otui`](c:\8.6\otserv_860\otcv8-dev-orig\layouts\modern\styles\40-gamebuttons.otui) | Grid `cell-size` = `TopButton` size; **`MiniWindowContents margin-top: 22`** (titulo + minimizar/fechar) |
| [`modules/game_buttons/buttons.lua`](c:\8.6\otserv_860\otcv8-dev-orig\modules\game_buttons\buttons.lua) | `updateOrder()` redimensiona altura da janela conforme linhas do grid |

**Bug comum:** aumentar `TopButton` para 48px sem atualizar `40-gamebuttons.otui` (grid 20x20) → icones amontoados. Manter **mesmo tamanho** nos dois arquivos (hoje 48x48).

## PNGs gerados (dimensões fixas)

| Arquivo | Tamanho | Notas OTUI |
|---------|---------|------------|
| `button.png` | 22×69 | 3× célula 22×23 (normal/hover/pressed) |
| `button_rounded.png` | 22×69 | idem |
| `tabbutton_rounded.png` | 22×69 | idem |
| `tabbutton_square.png` | 20×63 | clips Y: 0, 21, 42 |
| `button_top.png` | 144×48 | 3× célula 48×48 horizontal (top menu HD) |
| `panel_top.png` | 256×56 | barra superior top menu 56px |
| `window.png` | 92×80 | Modelo **C**: borda `#4a4a4a` + cantoneiras `#b8a060` 8px; `image-border: 6`, `image-border-top: 27` |
| `miniwindow.png` | 50×54 | Mesmo estilo C; `image-border: 4`, `image-border-top: 23` |
| `window_headless.png` | 45×30 | border 5, top 12 |
| `miniwindow.png` | 50×54 | border 4, top 23 |
| `miniwindow_buttons.png` | 140×42 | sprites 14×14, 3 linhas |
| `scrollbar.png` | 52×78 | ver `data/styles/10-scrollbars.otui` |
| `combobox_square.png` | 91×92 | células 23px; popup clip Y=69 |
| `checkbox.png` | 15×60 | 4× célula 15×15 |
| `panel_flat.png` | 32×32 | `image-border: 1` |
| `panel_lightflat.png` | 32×32 | idem |
| `textedit.png` | 32×32 | border 1 |
| `separator_horizontal.png` | 32×1 | Layout **modern** não usa PNG — ver abaixo |
| `separator_vertical.png` | 1×32 | idem |

### Separadores no Enter Game (“listas” / sulcos)

Não são listas: widgets `HorizontalSeparator` em `modules/client_entergame/entergame.otui`.

| Antes (retro) | Problema |
|---------------|----------|
| PNG `separator_horizontal.png` **32×2** + `image-border: 1` + `height: 2` | 9-slice usa **linha de cima e linha de baixo** do PNG → aparecem **duas faixas** (efeito 3D) |

**Layout modern:** `layouts/modern/styles/10-separators.otui` usa só `background-color: #4a4a4a` e `height: 1` (sem imagem).

Para mudar a cor da linha, edite esse `.otui` e reinicie o cliente.
| `arrow_horizontal.png` | 24×63 | 2 col × 3 linhas de 12×21 |
| `progressbar.png` | 80×16 | **Interior transparente** — cor do fill vem de `background-color`; PNG so borda |
| `progressbar_thick.png` | 80×20 | ThickProgressBar |
| `panel_top.png` | 256×36 | top menu, `image-repeated` |
| `panel_bottom2.png` | 942×60 | console inferior |
| `panel_side.png` / `panel_map.png` | 61×61 | bordas do mapa |

Lista completa: `layouts/modern/images/ui/` (43 arquivos).

## Estilos sobrescritos em `layouts/modern/styles/`

- `10-panels.otui` — fundo semitransparente + PNG flat
- `10-windows.otui`, `30-miniwindow.otui`
- `10-buttons.otui`, `20-tabbars.otui`
- `10-textedits.otui` — texto claro em fundo escuro
- `10-scrollbars.otui`, `10-comboboxes.otui`, `10-checkboxes.otui`
- `10-separators.otui`, `10-progressbars.otui`, `20-topmenu.otui`

## Baseline (retro)

Opcoes → Interface → **retro**, ou `DEFAULT_LAYOUT = "retro"` em `init.lua`. Usa PNGs/OTUI de `data/` sem layout overlay.

## Troubleshooting — ainda vejo UI antiga

1. **Reinicie o cliente** após mudar tema (layout só carrega na abertura).
2. **`config.otml` `layout:`** — valores validos: `modern-dark`, `modern-medium`, `modern-light`, `retro`. Valor antigo `modern` migra para `modern-dark`.
3. Confira no log ao iniciar: `UI layout ativo: modern-dark` (ou medium/light).
4. **Skills ilegivel** — confirme que o layout ativo tem `styles/10-labels.otui` e `modules/game_skills/skills.otui` (fonte `verdana-11px-antialised`). Rode `.\scripts\sync-login-to-themes.ps1`.
5. **Slots de equipamento** — gerados por `generate-theme-slots.ps1` em `layouts/<preset>/images/game/slots/`.

6. **Erro `TabBarVertical is not a defined style`** — o `layouts/modern/styles/20-tabbars.otui` estava incompleto (sem `TabBarVertical`, usado em Options). Corrigido: manter o arquivo **completo** como em `data/styles/20-tabbars.otui`.

## Ajuste fino (checkbox / slider)

Se checkboxes ou sliders sumirem no fundo escuro:

1. Edite `scripts/generate-modern-ui-pngs.ps1` (`New-CheckboxSheet`, `New-ScrollbarSheet`).
2. Rode `.\scripts\generate-modern-ui-pngs.ps1` e `.\scripts\deploy-modern-ui-to-data.ps1`.
3. Reinicie o cliente.

**Checkbox:** fundo `#484848`, borda `#aaaaaa`; marcado = fundo `#4a6a8a` + tick branco.  
**Slider:** trilho `#2d2d2d`, “thumb” azul `#6a9ec8` (clip `0 26` em `scrollbar.png`).  
**OTUI:** `image-color: #ffffffff` em `layouts/modern/styles/10-checkboxes.otui` (tint neutro).

### Risquinhos verticais (Enter Game / Character List)

Causa: `window.png` (faixas laterais 6 px do 9-slice) e `scrollbar.png` (trilho 39,0 13×65) com pixels que repetem ao esticar.

O script `generate-modern-ui-pngs.ps1` gera laterais **uniformes** (sem `DrawRectangle` no corpo). Regenerar:

```powershell
.\scripts\generate-modern-ui-pngs.ps1
.\scripts\deploy-modern-ui-to-data.ps1
```

## Fora do escopo chrome

`data/images/game/*`, sprites de itens (`Tibia.dat`/`.spr`), ícones de módulos (`topbuttons/`, `game/prey/`, etc.).
