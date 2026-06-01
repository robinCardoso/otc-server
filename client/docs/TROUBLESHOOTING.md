# Solução de problemas — OTCv8 + TFS 860

## Compilação

### MSBuild não encontrado

**Sintoma:** `build-client.ps1` falha imediatamente.

**Solução:** instalar VS 2022 Build Tools com C++ e Win32. MSBuild fica em:

`C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe`

O script já procura em `(x86)` primeiro.

### vcpkg: Could not find GIT

Rodar `.\scripts\patch-vcpkg-git.ps1` ou `setup-vcpkg.ps1` completo. Definir no PowerShell antes do setup:

```powershell
$env:GIT_EXECUTABLE = "C:\Program Files\Git\cmd\git.exe"
```

### vcpkg: bzip2 / libwinpthread 404

Instalar MSYS2 e garantir `C:\msys64\mingw64\bin\pkg-config.exe`. O patch em `vcpkg_find_acquire_program.cmake` deve usar pkg-config local.

### vcpkg: Visual Studio 16 2019 not found

Patch em `vcpkg_configure_cmake.cmake` (v142 → VS 17 2022). Não instalar VS 2019 só por isso.

### vcpkg: PowerShell Core (openssl)

Patch em `vcpkg_copy_tool_dependencies.cmake` com fallback `powershell.exe`.

### Link LNK2001 OpenAL (`___std_*`)

Cliente e vcpkg devem usar o **mesmo toolset** (v143 no `vc16`).

---

## Login e entrada no jogo

### Cliente trava em "Connecting to game server..."

Servidor mostra login OK, cliente não entra.

**Verificar `otclientv8.log`:**

1. `ERROR: Failed to read dat ... corrupt` → colocar `Tibia.dat`/`Tibia.spr` 8.60 em `data/things/860/`.
2. `switchMode (a nil value)` → corrigido em `gameinterface.lua` (reiniciar cliente).
3. `Login to 127.0.0.1:7172` sem erro depois → conexão game OK.

### Lista de personagens vazia / cast sem senha

Servidor: `enableLiveCasting = false` em `config.lua`.

### Versão / RSA

Host: `127.0.0.1:7171:860`. Servidor: `clientVersionMin/Max = 860`.

---

## Movimento

### Um clique = 2 sqm

Correção em `src/client/game.cpp` (preWalk no autoWalk). **Recompilar** o cliente.

### Sensação de travamento ao andar

**Options → Game:**

- Marcar **Enable fast walking (DASH)** e **Enable smart walking**
- Delays baixos (50 ms turn/first step) — defaults no `options.lua` com migração `walkSettingsVersion`

**Options → Graphics** (principal para “coice” da tocha):

- **Game framerate limit:** teste **30–40** (10 = muito fluido mas lento; max = rápido mas trava visual)
- **Vsync:** desligado (padrão do projeto)
- **Classic view:** **ligado** (desligado causa faixas pretas no layout)

**Floor fading** não costuma afetar o deslize tile-a-tile do mapa.

Migração `mapSmoothSettingsVersion` (v2): classic on, FPS **35**, floor fading 300 ms.

Reinicie o cliente após mudança de versão da migração.

**Servidor:** `timeBetweenActions` / `timeBetweenExActions` em `config.lua` (200 ms no projeto).

### Mapa / tocha “dando coice” ao andar

Movimento tile-a-tile; defaults acima reduzem snap visual. Ver `docs/CLIENT-CHANGES.md`.

### Ping: ??

Comum em localhost; não indica necessariamente lag se FPS ~60.

---

## Interface

### Transição login → jogo brusca

Fade em `gameinterface.lua` (`show`/`hide`). Só Lua — reiniciar exe.

### Floor fading lento

**Options → Graphics** → floor fading, ou default 300 ms em `options.lua`.

---

## Diagnóstico rápido

| Sintoma | Onde olhar |
|---------|------------|
| Não compila | saída `setup-vcpkg.ps1` / `build-client.ps1` |
| Não loga | servidor console, porta 7171 |
| Não entra no mapa | `otclientv8.log`, assets 860 |
| Anda estranho | rebuild C++ se mudou `game.cpp`; Options → Game |
| FPS baixo | Options → Graphics, drivers GPU |

## Rebuild mínimo

```powershell
cd C:\8.6\otserv_860\otcv8-dev
.\scripts\build-client.ps1
```

Só Lua: fechar e abrir `otclient_gl.exe`.
