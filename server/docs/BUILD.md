# Build do servidor TFS (Fazendo Tibia 8.60)

Documentação completa para compilar o **The Forgotten Server (TFS)** neste repositório no **Windows**, usando **MSYS2 MinGW 64-bit**.

Última build validada: **20/05/2026** — `tfs.exe` gerado com **GCC 15.2.0**, **Boost 1.91**, **CMake 4.x**.

---

## Visão geral

| Item | Valor |
|------|--------|
| Projeto | The Forgotten Server (TFS) — servidor Open Tibia |
| Cliente alvo | Tibia **8.60** (`config.lua`: `clientVersionMin/Max = 860`) |
| Executável | `tfs.exe` (Windows) / `tfs` (Linux) |
| Build system | CMake + cotire (PCH) |
| Padrão C++ | **C++17** (`cmake/FindCXX11.cmake`) |
| Diretório de build (Windows) | `build_win/` |
| Raiz do servidor | Onde estão `config.lua`, `data/`, `tfs.exe` |

---

## Ambiente usado nesta máquina

| Ferramenta | Versão / caminho |
|------------|------------------|
| SO | Windows 10/11 |
| MSYS2 | `C:\msys64` |
| Toolchain | **MinGW-w64 x86_64** (`C:\msys64\mingw64`) |
| Compilador | `C:\msys64\mingw64\bin\g++.exe` — GCC **15.2.0** |
| CMake | `C:\msys64\mingw64\bin\cmake.exe` (também pode existir CMake global 4.x no PATH) |
| Make | `C:\msys64\mingw64\bin\mingw32-make.exe` |
| WSL | **Não instalado** (build feita nativamente no Windows) |

### PATH obrigatório para compilar (PowerShell ou CMD)

Coloque o MinGW64 **antes** de outros compiladores:

```
C:\msys64\mingw64\bin
C:\msys64\usr\bin
```

PowerShell (sessão atual):

```powershell
$env:PATH = "C:\msys64\mingw64\bin;C:\msys64\usr\bin;" + $env:PATH
```

---

## MSYS2 — instalação inicial (se ainda não tiver)

1. Baixar e instalar: https://www.msys2.org/
2. Abrir **MSYS2 MinGW 64-bit** (atalho: `C:\msys64\mingw64.exe` ou terminal “MINGW64”).
3. Atualizar base (uma vez):

```bash
pacman -Syu
```

---

## Dependências — pacotes instalados

Instalados com **pacman** (repositório `mingw64`). Nomes corretos no MSYS2 atual:

| Pacote MSYS2 | Biblioteca / uso |
|--------------|------------------|
| `mingw-w64-x86_64-toolchain` | GCC, g++, binutils |
| `mingw-w64-x86_64-cmake` | CMake (opcional se já tiver no PATH) |
| `mingw-w64-x86_64-make` | mingw32-make |
| `mingw-w64-x86_64-boost` | Boost ≥ 1.53 (system, filesystem, iostreams) |
| `mingw-w64-x86_64-crypto++` | Crypto++ (**não** é `cryptopp`) |
| `mingw-w64-x86_64-gmp` | GMP |
| `mingw-w64-x86_64-luajit` | LuaJIT 2.1 |
| `mingw-w64-x86_64-libmariadbclient` | Cliente MariaDB/MySQL |
| `mingw-w64-x86_64-pugixml` | PugiXML |

### Comando único de instalação

Executar no **MSYS2** (MINGW64) ou:

```powershell
C:\msys64\usr\bin\pacman.exe -S --noconfirm --needed `
  mingw-w64-x86_64-toolchain `
  mingw-w64-x86_64-cmake `
  mingw-w64-x86_64-make `
  mingw-w64-x86_64-boost `
  mingw-w64-x86_64-crypto++ `
  mingw-w64-x86_64-gmp `
  mingw-w64-x86_64-luajit `
  mingw-w64-x86_64-libmariadbclient `
  mingw-w64-x86_64-pugixml
```

### Onde ficam headers e libs (após instalar)

| Componente | Include | Biblioteca |
|------------|---------|------------|
| Boost | `C:\msys64\mingw64\include\boost` | `C:\msys64\mingw64\lib\libboost_*.a` |
| Crypto++ | `C:\msys64\mingw64\include\cryptopp\` | `C:\msys64\mingw64\lib\libcryptopp.a` |
| GMP | `C:\msys64\mingw64\include\` | `C:\msys64\mingw64\lib\libgmp.a` |
| LuaJIT | `C:\msys64\mingw64\include\luajit-2.1\` | `C:\msys64\mingw64\lib\libluajit-5.1.dll.a` |
| MariaDB | `C:\msys64\mingw64\include\mariadb\mysql.h` | `C:\msys64\mingw64\lib\libmariadb.dll.a` |
| PugiXML | `C:\msys64\mingw64\include\pugixml.hpp` | `C:\msys64\mingw64\lib\libpugixml.a` |

---

## Compilar — passo a passo (Windows / MinGW)

Na raiz do repositório (`otserv_860`):

```bash
cd /c/8.6/otserv_860/otserv_860-orig

mkdir -p build_win
cd build_win

cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
mingw32-make -j8
```

### Saída da build

| Artefato | Caminho |
|----------|---------|
| Executável principal | `build_win/tfs.exe` |
| Cópia recomendada na raiz | `tfs.exe` (mesmo nível que `config.lua`) |

Copiar para a raiz e instalar DLLs:

```powershell
Copy-Item build_win\tfs.exe .\tfs.exe -Force
.\deploy-runtime-dlls.ps1
```

Atalho: **`rodar-tfs-novo.bat`** (deploy + inicia). Aguarde **`>> Fazendo Tibia Server Online!`**.

### Rebuild limpo

```bash
cd build_win
mingw32-make clean
mingw32-make -j8
```

Ou apagar `build_win` e rodar `cmake` + `make` de novo.

---

## Rodar o servidor (após build)

### Requisitos de runtime

1. **MariaDB ou MySQL** em execução (`config.lua`):

   - Host: `127.0.0.1`
   - Porta: `3306`
   - Banco: `global`
   - Usuário/senha: `mysqlUser` / `mysqlPass`

2. Importar schema: `global.sql` (na raiz do repo).

3. Pastas `data/`, mapa (`mapName` em `config.lua`, ex.: `realmap.otbm`), DLLs do MinGW no PATH se necessário (`libstdc++-6.dll`, `libwinpthread-1.dll`, etc. em `C:\msys64\mingw64\bin`).

### Executar

```bash
cd /c/8.6/otserv_860/otserv_860-orig
./tfs.exe
```

### Logs do console (TFS)

Em `config.lua`:

| Chave | Efeito | Recompilar? |
|-------|--------|---------------|
| `enableTfsConsoleLog` | `true`: `rodar-tfs-novo.bat` grava `data/logs/tfs/tfs-console_*.log`. `false`: só console, sem arquivo. | Não |
| `enableTfsDiagnosticLog` | `true`: linhas `[login]` / `[extopcode]` no stdout. `false`: menos ruído e I/O. | Sim (`tfs.exe`) |

Atalho com log em arquivo: **`rodar-tfs-novo.bat`** (chama `scripts/run-tfs-logged.ps1`, que lê `enableTfsConsoleLog` antes de criar o `.log`).

Mensagem esperada se o banco **não** estiver rodando:

```
>> Loading config: config.lua
>> Establishing database connection...
MySQL Error Message: Can't connect to MySQL server on '127.0.0.1' (10061)
> ERROR: Failed to connect to database.
```

Isso indica que a **build está OK**; falta apenas o banco.

---

## Alterações no repositório (implementadas para build completa)

### Arquivos CMake novos

| Arquivo | Função |
|---------|--------|
| `cmake/FindCrypto++.cmake` | Localiza Crypto++ (estava ausente na cópia original) |
| `cmake/FindLTO.cmake` | Link-time optimization (`-flto` só em **não-Windows**) |

### Arquivos CMake modificados

| Arquivo | Alteração |
|---------|-----------|
| `CMakeLists.txt` | `cmake_minimum_required` 3.16; `-pipe` só fora do Windows; link `ws2_32` + `mswsock` no WIN32 |
| `cmake/cotire.cmake` | `cmake_minimum_required` 3.10 (compatível com CMake 4.x) |
| `cmake/FindCXX11.cmake` | `-std=c++17` em vez de C++11 |
| `cmake/FindMySQL.cmake` | Paths MSYS2 (`mariadb/`, `mysql/`); libs `mariadb`/`libmariadb`; `MYSQL_CLIENT_LIBS` derivado do `.a` encontrado |
| `cmake/FindLuaJIT.cmake` | Sufixo `include/luajit-2.1` |
| `cmake/FindCrypto++.cmake` | Paths `C:/msys64/mingw64/...` |

### Código-fonte adaptado (Boost 1.91 + GCC 15)

APIs antigas do Boost.Asio removidas no Boost atual:

| Antes | Depois | Arquivos |
|-------|--------|----------|
| `boost::asio::io_service` | `boost::asio::io_context` | `connection.h`, `server.h`, `signals.h`, `signals.cpp`, `connection.cpp` |
| `boost::asio::deadline_timer` | `boost::asio::steady_timer` | `connection.h`, `server.h` |
| `expires_from_now(posix_time::seconds)` | `expires_after(std::chrono::seconds)` | `connection.cpp`, `server.cpp` |
| `socket.get_io_service().dispatch` | `boost::asio::post(socket.get_executor(), ...)` | `connection.cpp` |
| `io_service.post` | `boost::asio::post(io_service, ...)` | `server.cpp` |
| `address_v4::to_ulong()` | `to_uint()` | `connection.cpp` |
| `address_v4::from_string` | `boost::asio::ip::make_address` | `server.cpp` |
| `INADDR_ANY` manual | `address_v4::any()` | `server.cpp` |

Outros ajustes de compilação:

| Arquivo | Alteração |
|---------|-----------|
| `src/definitions.h` | Macros `strcasecmp` só com `_MSC_VER` (evita recursão infinita no MinGW) |
| `src/outputmessage.cpp` | `allocate_shared` substituído por allocate + placement new + `shared_ptr` custom deleter (GCC 15 + allocator) |
| `src/lockfree.h` | Construtor default no `LockfreePoolingAllocator` |
| `src/luascript.cpp` | `luaPlayerGetSpectators`: usa `spectators.size()` (warning unused) |
| `CMakeLists.txt` | `luascript.cpp` + `scriptmanager.cpp` com **`-O1`** no Windows (evita crash LuaJIT/GCC 15 em `global.lua`) |
| `src/database.cpp` | Desativa SSL forçado do `libmariadb` 3.4 |
| `src/scriptmanager.cpp` | Logs `> scripts: ...` para diagnóstico de startup |

---

## Linux (referência — build antiga em `build/`)

A pasta `build/` contém cache CMake de ambiente **Linux** (`/usr/bin/g++`). Em Ubuntu/Debian:

```bash
sudo apt install build-essential cmake \
  libboost-system-dev libboost-filesystem-dev libboost-iostreams-dev \
  libcrypto++-dev libgmp-dev libluajit-5.1-dev \
  libmysqlclient-dev libpugixml-dev

mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cp tfs ..
```

---

## Problemas comuns

| Erro | Causa | Solução |
|------|--------|---------|
| `FindCrypto++.cmake` não encontrado | Arquivo faltando | Usar `cmake/FindCrypto++.cmake` deste repo |
| `Could NOT find Crypto++` | Pacote não instalado | `pacman -S mingw-w64-x86_64-crypto++` |
| `target not found: mingw-w64-x86_64-cryptopp` | Nome errado | Pacote correto: **`crypto++`** |
| `io_service` / `deadline_timer` | Boost 1.86+ | Aplicar patches em `src/` (já no repo) |
| `undefined reference to AcceptEx` | Falta link Windows socket | `ws2_32` + `mswsock` no `CMakeLists.txt` (já no repo) |
| Erros LTO / `wrapexcept` no link | `-flto` no Windows | `FindLTO.cmake` desativa LTO em `WIN32` |
| `Can't connect to MySQL` (10061) | MariaDB parado | Iniciar serviço e importar `global.sql` |
| DLL ausente ao rodar `tfs.exe` | Runtime MinGW | Adicionar `C:\msys64\mingw64\bin` ao PATH |

---

## Checklist rápido para o agente

- [ ] MSYS2 em `C:\msys64`, toolchain **mingw64** (não confundir com ucrt64/msys)
- [ ] Pacotes `mingw-w64-x86_64-*` listados acima instalados
- [ ] PATH: `mingw64\bin` + `usr\bin`
- [ ] Build em `build_win/` com `-G "MinGW Makefiles"`
- [ ] `tfs.exe` copiado para raiz junto de `config.lua` e `data/`
- [ ] MariaDB rodando; banco `global` criado a partir de `global.sql`
- [ ] Não usar WSL obrigatoriamente — build nativa MinGW já funciona neste projeto

---

## Referências

- Repositório base: The Forgotten Server (TFS) — fork “Fazendo Tibia 860”
- `config.lua` — portas 7171/7172, versão cliente 8.60
- `Restart.sh` — loop Linux: `while true; do ./tfs; done`
- **Cliente OTClientV8:** [`docs/CLIENT.md`](./CLIENT.md) — pasta `c:\8.6\\otserv_860-orig\\otclientv8\`
- **Layout servidor + cliente:** [`docs/PROJECT.md`](./PROJECT.md)
- Documentação do agente: `.cursorrules`

