# Logs do TFS (-orig)

Configuração em `config.lua` (final do arquivo).

## `enableTfsConsoleLog`

| Valor | Comportamento |
|-------|----------------|
| `true` | `rodar-tfs-novo.bat` / `scripts/run-tfs-logged.ps1` gravam cópia do console em `data/logs/tfs/tfs-console_YYYY-MM-DD_HH-mm-ss.log` |
| `false` | Apenas janela do console, sem arquivo |

**Não exige recompilar** — só reiniciar o servidor após mudar `config.lua`.

Uso típico: capturar stack de Lua, erros de startup (`global.lua`), ou saída antes do crash.

## `enableTfsDiagnosticLog`

| Valor | Comportamento |
|-------|----------------|
| `true` | `std::cout` com tags `[login]` e `[extopcode]` (implementação em C++) |
| `false` | Menos ruído no console |

**Exige recompilar** `tfs.exe` após alterar (flag lida na build ou no startup via config — neste repo está em `config.lua` lido no runtime; mesmo assim, o código dos logs está em `src/` — se a flag não existir no binário antigo, rebuild).

Útil para: confirmar ordem de login, extended opcodes recebidos (201, 203), debug de crash pós-login.

## Como rodar com log em arquivo

```powershell
cd C:\8.6\otserv_860\otserv_860-orig
.\rodar-tfs-novo.bat
```

Ou manualmente após `deploy-runtime-dlls.ps1`:

```powershell
.\scripts\run-tfs-logged.ps1
```

## Onde olhar

| Tipo | Caminho |
|------|---------|
| Console espelhado | `data/logs/tfs/tfs-console_*.log` |
| Diagnóstico C++ | Mesmo arquivo / janela do console (linhas `[login]`, `[extopcode]`) |
| Lua print | Console / arquivo acima (ex.: `[ExtendedOpcodeCombatPower] send failed`) |

## Combinação recomendada para debug de opcode 203

1. `enableTfsConsoleLog = true`
2. `enableTfsDiagnosticLog = true` + `tfs.exe` recompilado recente
3. `rodar-tfs-novo.bat`
4. Login OTC + `!power` ou abrir modal Combat Power
5. Analisar últimas linhas do `.log` antes do crash `0xC0000005`

Ver também: [AGENT-GUIDE.md](./AGENT-GUIDE.md), [COMBAT-POWER.md](./COMBAT-POWER.md).
