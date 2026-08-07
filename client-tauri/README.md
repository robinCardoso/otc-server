# Client Tauri

Cliente próprio para servidor TFS 8.6, em desenvolvimento incremental.

## Stack

- **Tauri 2** — shell nativo (Rust)
- **TypeScript + Vite** — frontend
- **PixiJS 8** — renderização 2D

## Estrutura

```
client-tauri/
├── client/          ← aplicativo Tauri (use este diretório)
│   ├── src/         frontend (main, renderer, game, ui)
│   └── src-tauri/   backend Rust (protocol, tibia)
└── asset/tibia/     assets Tibia locais (não versionados)
```

O app real está em `client/`. O `package.json` na raiz de `client-tauri/` é legado — ignore.

## Pré-requisitos

- Node.js 18+
- Rust (rustup) com `cargo` no PATH (`%USERPROFILE%\.cargo\bin`)
- WebView2 Runtime (Windows)
- Visual Studio Build Tools 2022 com C++ (MSVC)

## Desenvolvimento

```powershell
cd client-tauri/client
npm install
npm run tauri dev
```

O script `npm run tauri` usa `scripts/tauri.cjs` para garantir que `cargo` seja encontrado mesmo se o terminal não tiver o PATH do Rust atualizado.

**Primeira compilação:** pode levar vários minutos (download de crates Rust).

## Estado atual

- Janela Tauri com canvas PixiJS em tela cheia
- Cena 2D vazia (fundo `#1a1a2e`)
- Protocolo, login e leitura de Tibia.dat/spr ainda não implementados

## Build de produção

```powershell
cd client-tauri/client
npm run tauri build
```
