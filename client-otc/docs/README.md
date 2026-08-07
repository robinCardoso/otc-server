# Documentação — OTCv8 Dev (Fazendo Tibia 860)

Cliente OTClientV8 compilado localmente para o servidor TFS 8.60.

## Índice

| Documento | Conteúdo |
|-----------|----------|
| [BUILD.md](BUILD.md) | Pré-requisitos, vcpkg, compilação, patches, scripts |
| [CLIENT-CHANGES.md](CLIENT-CHANGES.md) | Correções Lua/C++/projeto no cliente |
| [ASSIGN-SPELL.md](ASSIGN-SPELL.md) | Action bar — Assign Spell, filtros, lista vazia |
| [SPELL-LIST-MODULE.md](SPELL-LIST-MODULE.md) | Lista de magias opcode **202** (ponte → servidor) |
| [COMBAT-POWER-MODULE.md](COMBAT-POWER-MODULE.md) | Modal Combat Power opcode **203** — layout, JSON, ícones, troubleshooting |
| [BESTIARY-MODULE.md](BESTIARY-MODULE.md) | Bestiary opcode **207** — catálogo JSON, kills/looks sync, UI, roadmap |
| [VIEWPORT-CLASSIC-VIEW.md](VIEWPORT-CLASSIC-VIEW.md) | Mapa **25×20**, opção **Classic view**, layout vs zoom, build e testes |
| [SHOP-MODULE.md](SHOP-MODULE.md) | UI Shop opcode **201** (ponte → servidor) |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Login, movimento, assets, erros comuns |

## Início rápido

```powershell
# 1) Dependências (uma vez; demora)
cd C:\8.6\otserv_860\otc-server\client
.\scripts\setup-vcpkg.ps1

# 2) Compilar cliente
.\scripts\build-client.ps1

# 3) Jogar
# Copiar Tibia 8.60 para data\things\860\ (Tibia.dat + Tibia.spr)
# Executar otclient_gl.exe na pasta client\
# Servidor: 127.0.0.1:7171:860
```

## Pastas importantes

- **Executáveis:** `otc-server\client\otclient_gl.exe`, `otclient_dx.exe`
- **Código C++:** `src\`, solução `vc16\otclient.sln`
- **Lua/UI:** `modules\`, `data\`, `init.lua`
- **Log do cliente:** `otc-server\client\otclientv8.log`
- **vcpkg:** `C:\8.6\otserv_860\vcpkg`
- **Servidor:** `C:\8.6\otserv_860\otserv_860\`
