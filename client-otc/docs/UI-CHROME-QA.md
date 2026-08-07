# QA — tema UI `modern`

Checklist após alterar PNGs ou `.otui` em `layouts/modern/`. Reiniciar `otclient_gl.exe` (sem rebuild C++).

## Ativação

- [ ] `init.lua` com `DEFAULT_LAYOUT = "modern"`
- [ ] Se ainda aparecer retro: Options → apagar `layout` salvo ou editar `%APPDATA%\OTCv8\config.otml`

## Enter Game / geral

- [ ] Tela de login e lista de personagens legíveis
- [ ] Top menu (botões 26×26) com hover visível
- [ ] FPS/ping legíveis no topo

## Janelas

- [ ] Abrir Skills, Battle, Inventory (miniwindow): borda superior e botões − □ ×
- [ ] Arrastar e minimizar miniwindow
- [ ] Janela modal grande (ex. **Estoque** Ctrl+Shift+E): título e bordas sem “rasgar”
- [ ] Botões **Retirar** / **Depositar**: normal, hover, pressed

## Controles

- [ ] Campo **Buscar item...** (TextEdit): texto claro, seleção visível
- [ ] Combobox **Nome** / ordenação: abrir lista, hover em item
- [ ] Scroll em lista longa (Estoque ou VIP)
- [ ] Checkbox (se houver em options/outfit)

## Mapa / painéis

- [ ] Moldura do mapa (`panel_map`) sem artefatos nos cantos
- [ ] Painéis laterais (`panel_side`) consistentes
- [ ] Barra inferior / console (`panel_bottom2`)

## Regressão

- [ ] `DEFAULT_LAYOUT = "retro"` restaura visual anterior
- [ ] Sem erros no `otclient.log` sobre texturas ausentes (`unable to load` / `image`)

## Se algo quebrar

1. Comparar dimensão do PNG com tabela em `docs/UI-CHROME-ASSETS.md`
2. Conferir `image-clip` / `image-border` no `.otui` correspondente
3. Regenerar: `.\scripts\generate-modern-ui-pngs.ps1`
4. Restaurar PNG original de `data/images/ui/` no layout se necessário
