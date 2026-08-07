# Build do OTCv8 no Windows (Fazendo Tibia 860)

Guia do ambiente usado para compilar `otclient_gl.exe` e `otclient_dx.exe` com Visual Studio 2022 Build Tools e vcpkg fixo (março/2022).

## Pré-requisitos

| Ferramenta | Uso |
|------------|-----|
| **Visual Studio 2022 Build Tools** | C++ desktop, **Win32**, Windows 10/11 SDK, MSVC v142 e v143 |
| **Git for Windows** | Clone vcpkg; patches usam `GIT_EXECUTABLE` |
| **7-Zip** | Extração no vcpkg |
| **NASM** | Boost/algumas libs (`%LOCALAPPDATA%\bin\NASM` ou `tools\nasm`) |
| **MSYS2** (opcional mas recomendado) | `pkg-config` em `mingw64\bin` — evita downloads MSYS2 quebrados do vcpkg |

Instalação Build Tools (exemplo winget):

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

## Estrutura de diretórios

```
C:\8.6\otserv_860\
├── otserv_860\              # TFS 8.60
├── otc-server\client\       # este projeto (OTCv8)
├── vcpkg\                   # commit 3b3bd424827a1f7f4813216f6b32b6c61e386b2e
└── tools\nasm\              # opcional
```

## Passo 1 — vcpkg e dependências

```powershell
cd C:\8.6\otserv_860\otc-server\client
.\scripts\setup-vcpkg.ps1
```

O script:

1. Coloca no PATH: Git, CMake/Ninja do **VS** (não MSYS), 7-Zip, NASM — e **remove** `msys64` do PATH (CMake 4.x do MSYS quebra ports antigos).
2. Baixa `7z2107-extra.7z` via **Wayback** se o arquivo local for inválido (site 7-zip.org retorna 404).
3. Clona/checkout do vcpkg no commit fixo.
4. Executa `patch-vcpkg-git.ps1`.
5. Define `VCPKG_FORCE_SYSTEM_BINARIES=1` e `PKG_CONFIG` (MSYS2) quando existir.
6. Instala pacotes `x86-windows-static` (Boost, OpenSSL, OpenAL, LuaJIT, etc.).

Tempo típico: **30–90 minutos** na primeira execução.

### Erros do vcpkg que corrigimos (patches manuais)

Após `git checkout` limpo, reaplicar ou rodar `setup-vcpkg.ps1` (que chama o patch do Git). Outros patches ficam no tree após correção bem-sucedida:

#### 1. Git não encontrado pelo CMake

**Erro:** `Could not find GIT` em `z_vcpkg_apply_patches.cmake`  
**Causa:** subprocessos CMake não herdam PATH do PowerShell.  
**Correção:** `scripts/patch-vcpkg-git.ps1` adiciona `HINTS` para `GIT_EXECUTABLE` e `C:/Program Files/Git/cmd`.

#### 2. MSYS2 libwinpthread 404 (bzip2 / pkg-config)

**Erro:** download `mingw-w64-i686-libwinpthread-git-...` 404 em todos os mirrors.  
**Correção:** em `vcpkg_find_acquire_program.cmake`, usar `pkg-config` do MSYS2 local (`C:/msys64/mingw64/bin/pkg-config.exe`) antes de `vcpkg_acquire_msys`.

#### 3. Visual Studio 16 2019 não encontrado (openal-soft)

**Erro:** `Generator Visual Studio 16 2019 could not find any instance`.  
**Causa:** toolset v142 mapeava para VS 2019; máquina só tem Build Tools **2022**.  
**Correção:** em `vcpkg_configure_cmake.cmake`, v142 → gerador **Visual Studio 17 2022** (toolset v142 continua no build).

#### 4. PowerShell Core (openssl)

**Erro:** `Could not find PowerShell Core` em `vcpkg_copy_tool_dependencies.cmake`.  
**Correção:** fallback para `powershell.exe` do Windows.

#### 5. 7z2107-extra.7z inválido

**Erro:** hash SHA512 incorreto (HTML do SourceForge ou 404).  
**Correção:** download Wayback com hash esperado pelo vcpkg; validação no `setup-vcpkg.ps1`.

## Passo 2 — Compilar o cliente

```powershell
.\scripts\build-client.ps1
```

Saída:

- `otc-server\client\otclient_gl.exe`
- `otc-server\client\otclient_dx.exe`

O script:

- Localiza MSBuild em `Program Files (x86)\...\2022\BuildTools\...` (ou `vswhere`).
- Compila `vc16\otclient.sln` — configurações **OpenGL** e **DirectX**, plataforma **Win32**.
- Passa `/p:VcpkgRoot` e `/p:VcpkgInstalledDir`.

### Ajustes do projeto MSBuild

| Arquivo | Alteração |
|---------|-----------|
| `vc16/otclient.vcxproj` | `PlatformToolset` **v143** (OpenAL e libs vcpkg com MSVC 14.44) |
| `vc16/settings.props` | `VcpkgRoot` = `C:\8.6\otserv_860\vcpkg` |
| `vc16/otclient.vcxproj` | `AdditionalLibraryDirectories` debug usa `$(VcpkgRoot)\installed\...` (não `D:\a\otclient\...`) |

### Erro de link OpenAL (LNK2001 símbolos `___std_*`)

**Causa:** cliente v142 linkando OpenAL compilado com v143.  
**Solução:** toolset v143 no `vc16` (documentado acima).

## Scripts em `scripts/`

| Script | Função |
|--------|--------|
| `setup-vcpkg.ps1` | vcpkg + dependências |
| `build-client.ps1` | MSBuild OpenGL/DX |
| `patch-vcpkg-git.ps1` | patch Git no vcpkg |
| `patch-vcpkg-pkgconfig.ps1` | referência pkg-config (patch principal no cmake) |
| `fix-7zip-vcpkg.ps1` | utilitário 7z extra |
| `install-nasm.ps1` | instalar NASM local |

## Quando recompilar

| Mudança em | Ação |
|------------|------|
| `modules/*.lua`, `data/`, `init.lua` | Reiniciar `.exe` |
| `src/**`, `vc16/**` | `.\scripts\build-client.ps1` |
| vcpkg / novas libs | `setup-vcpkg.ps1` + rebuild |

## Integração com o servidor

- Servidor: `127.0.0.1`, login `7171`, game `7172`, versão **860**.
- Cliente: host `127.0.0.1:7171:860`, RSA OTServ padrão (`modules/gamelib/const.lua`).
- `data/things/860/Tibia.dat` + `Tibia.spr` obrigatórios (versão 8.60).
