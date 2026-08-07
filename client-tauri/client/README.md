# Client Tauri — App

Frontend Tauri + PixiJS para cliente Tibia/OTServer 8.6.

## Setup

```powershell
npm install
```

## Desenvolvimento

```powershell
npm run tauri dev
```

Abre a janela nativa com Vite em `http://localhost:1420`.

## Scripts

| Comando | Descrição |
|---------|-----------|
| `npm run dev` | Apenas Vite (sem janela Tauri) |
| `npm run tauri dev` | App completo em modo desenvolvimento |
| `npm run tauri build` | Build de produção |
| `npm run build` | Build do frontend (`dist/`) |

## Arquitetura frontend

```
src/
├── main.ts          entry point — inicializa GameRenderer
├── renderer/        PixiJS (GameRenderer)
├── game/            estado do jogo (stub)
└── ui/              overlays DOM (stub)
```

## Rust (`src-tauri/src/`)

```
protocol/   stubs de login e game protocol
tibia/      stubs de parsers (dat, spr, otb, otbm)
```

Módulos Rust existem mas ainda não estão integrados ao frontend.

## IDE

- VS Code + [Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode)
- [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)
