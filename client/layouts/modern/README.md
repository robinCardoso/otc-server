# Layouts UI — temas in-game configuráveis

Três tons de chrome in-game (painéis, janelas, chat, Skills). **Enter Game** permanece pergaminho (`ui/login/`).

| Tom | Valor `uiTheme` | Padrão |
|-----|-----------------|--------|
| Escuro | `dark` | **Sim** |
| Cinza | `medium` | |
| Claro | `light` | |

## Escolher tema (sem reiniciar)

**Opções → Interface → Tema da interface** → Escuro / Cinza / Claro — aplica **na hora** via `modules/client_theme`.

Layout fixo `modern-dark` (estrutura OTUI). PNGs em `data/images/ui/theme/{dark|medium|light}/`.

## Regenerar assets

```powershell
cd C:\8.6\otserv_860\otcv8-dev-orig
.\scripts\generate-modern-ui-pngs.ps1 -Preset All
.\scripts\generate-theme-slots.ps1 -Preset All
.\scripts\sync-login-to-themes.ps1
.\scripts\deploy-ui-themes.ps1
```

Login pack: `.\scripts\generate-login-ui.ps1` + `.\scripts\deploy-login-ui.ps1`
