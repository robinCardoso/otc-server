# OTCv8 — cliente (sources)

Fork do [OTCv8/otcv8-dev](https://github.com/OTCv8/otcv8-dev) para o servidor Tibia **8.60**. Binários prontos também existem em [OTCv8/otclientv8](https://github.com/OTCv8/otclientv8).

**Documentação detalhada (patches vcpkg, erros comuns):** [docs/BUILD.md](docs/BUILD.md) · índice geral em [docs/README.md](docs/README.md).

---

## Compilação no Windows (este projeto)

Tudo abaixo assume **PowerShell** e a pasta do cliente:

```text
C:\8.6\otserv_860\otc-server\client\
```

O vcpkg fica **fora** do repositório (compartilhado com outros builds):

```text
C:\8.6\otserv_860\vcpkg\
```

### O que você precisa instalar (uma vez na máquina)

| Ferramenta | Obrigatório | Para quê |
|------------|-------------|----------|
| **Visual Studio 2019 ou 2022** (Community ou Build Tools) | Sim | MSBuild, MSVC, Windows SDK |
| → workload **Desenvolvimento para desktop com C++** | Sim | Compilar o cliente |
| → **Windows 10/11 SDK** | Sim | Headers/libs Windows |
| → plataforma **Win32** (x86), não só x64 | Sim | O projeto é `Platform=Win32` |
| → MSVC **v143** (VS 2022) ou **v142** (VS 2019) | Sim | Toolset do `vc16\otclient.vcxproj` |
| **Git for Windows** | Sim | `setup-vcpkg.ps1` clona o vcpkg |
| **7-Zip** | Sim | Extração de pacotes no vcpkg |
| **NASM** | Recomendado | Algumas libs do vcpkg (Boost, etc.) |
| **MSYS2** com `pkg-config` | Recomendado | Evita downloads quebrados do vcpkg |

**NASM** — instale antes do `setup-vcpkg` se ainda não tiver:

```powershell
cd C:\8.6\otserv_860\otc-server\client
.\scripts\install-nasm.ps1
```

Ou coloque `nasm.exe` em `%LOCALAPPDATA%\bin\NASM`.

**Visual Studio Build Tools** (exemplo com winget):

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

### Passo 1 — Dependências vcpkg (só na primeira vez)

Demora em geral **30–90 minutos**. Não precisa repetir a cada build.

```powershell
cd C:\8.6\otserv_860\otc-server\client
.\scripts\setup-vcpkg.ps1
```

O script:

- Clona o vcpkg em `C:\8.6\otserv_860\vcpkg` no commit fixo `3b3bd424827a1f7f4813216f6b32b6c61e386b2e`
- Instala pacotes `x86-windows-static` (Boost, OpenSSL, LuaJIT, OpenAL, etc.)
- Aplica patches para VS 2022, Git, pkg-config e 7-Zip (ver [docs/BUILD.md](docs/BUILD.md))

### Passo 2 — Compilar o cliente

```powershell
cd C:\8.6\otserv_860\otc-server\client
.\scripts\build-client.ps1
```

**Variantes:**

```powershell
.\scripts\build-client.ps1                  # padrão: só OpenGL (mais rápido)
.\scripts\build-client.ps1 -Target OpenGL   # igual ao padrão
.\scripts\build-client.ps1 -Target DirectX  # só otclient_dx.exe
.\scripts\build-client.ps1 -Target All      # OpenGL + DirectX (dobra o tempo)
```

**Saída esperada** (na pasta `client\`):

| Arquivo | Configuração |
|---------|----------------|
| `otclient_gl.exe` | OpenGL (padrão) |
| `otclient_dx.exe` | DirectX |

### Executar de qualquer pasta

```powershell
& "C:\8.6\otserv_860\otc-server\client\scripts\build-client.ps1"
```

### Política de execução do PowerShell

Se aparecer erro do tipo *“running scripts is disabled”*:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\8.6\otserv_860\otc-server\client\scripts\build-client.ps1"
```

Ou, na sessão atual: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

### Depois de compilar — jogar

1. Copie **Tibia.dat** e **Tibia.spr** (cliente 8.60) para `data\things\860\`
2. Execute `otclient_gl.exe` na pasta `client\`
3. Servidor local típico: `127.0.0.1:7171:860`

### Quando rodar cada script de novo

| Situação | Script |
|----------|--------|
| Primeira máquina / vcpkg novo | `setup-vcpkg.ps1` |
| Mudou só Lua, `data\`, UI | Reinicie o `.exe` (sem compilar) |
| Mudou `src\` ou `vc16\` | `build-client.ps1` |
| Erro de link / nova lib C++ | `setup-vcpkg.ps1` + `build-client.ps1` |

### Erros comuns (resumo)

| Sintoma | O que fazer |
|---------|-------------|
| `MSBuild nao encontrado` | Instale VS com C++ desktop + Win32 |
| `Git nao encontrado` | Instale [Git for Windows](https://git-scm.com/download/win) |
| `vcpkg install falhou` | Leia a saída; veja [docs/BUILD.md](docs/BUILD.md) (NASM, MSYS2, 7-Zip) |
| Build OK mas sem `.exe` | Confira `vc16\` e permissões na pasta `client\` |

---

## Compilação manual (upstream OTCv8)

### GitHub Actions

Repositório oficial usa Actions para build automático. Aba **Actions** no GitHub do OTCv8.

### Windows (manual, sem scripts deste repo)

Visual Studio 2019 + vcpkg no commit [3b3bd424](https://github.com/microsoft/vcpkg/archive/3b3bd424827a1f7f4813216f6b32b6c61e386b2e.zip):

```bash
vcpkg install boost-iostreams:x86-windows-static boost-asio:x86-windows-static boost-beast:x86-windows-static boost-system:x86-windows-static boost-variant:x86-windows-static boost-lockfree:x86-windows-static boost-process:x86-windows-static boost-program-options:x86-windows-static luajit:x86-windows-static glew:x86-windows-static boost-filesystem:x86-windows-static boost-uuid:x86-windows-static physfs:x86-windows-static openal-soft:x86-windows-static libogg:x86-windows-static libvorbis:x86-windows-static zlib:x86-windows-static libzip:x86-windows-static openssl:x86-windows-static
```

Abra `vc16\otclient.sln`, plataforma **Win32**, configurações OpenGL/DirectX.

### Linux

- vcpkg commit `761c81d43335a5d5ccc2ec8ad90bd7e2cbba734e`
- boost >= 1.67, libzip-dev, physfs >= 3, gcc >= 9

```bash
mkdir build && cd build && cmake .. && make -j8
```

### Android

Ver instruções originais no histórico do projeto (NDK, assets, `create_android_assets.ps1`).

---

## Dicas úteis

- Testes manuais: descompacte `tests.7z` e rode `otclient_debug.exe --test`
- UI mobile: `otclient_debug.exe --mobile`

## Links

- Discord: https://discord.gg/feySup6
- Forum: http://otclient.net
- Email: otclient@otclient.ovh
