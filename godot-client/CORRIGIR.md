# Correções de parse — camada de rede (load / autoload)

## Problema

Scripts carregados cedo (autoloads) ou via `load()` em runtime falham no parse quando referenciam `class_name` que ainda não estão no escopo da cadeia de dependências:

- **Erro A:** `Could not find type "TibiaGameWorld"` — type hint em script que não preloada `GameWorld.gd`.
- **Erro B:** `Could not resolve external class member "dispatch"` — efeito colateral: `OpcodeDispatcher.gd` não parseia e o preload perde métodos estáticos.
- **Erro C:** `Invalid call. Nonexistent function 'new' in base 'GDScript'` — `preload("GameWorld.gd")` retorna script inválido quando a árvore `src/world/` tem type hints `TibiaMapManager` etc. sem ordem de registro garantida.

## Desync 0x64 (item id 40963 / 0xA003)

Sintoma: `ThingReader: item id 40963 ausente no .dat` e `Proximos bytes: 68 10...` em vez de `78` (inventário).

**Causa:** `0xA003` = bytes `03 A0` (LE) — leitura **1 byte atrás** do alinhamento real. Padrão típico:

1. Criatura `0x61` sem consumir `emblem` (byte `0x03`) → próximo u16 lê `03 A0`.
2. Item stackable com `count=3` antes de item `0x00A0` sem ler o byte de count.
3. Item ausente no `.dat` retornando sem consumir count (abort agora impede cascata).

**OTC referência:** `getCreature()` lê emblem só quando `!known` (`type == 0x61`); `getItem()` lê count para `stackable || chargeable` ou fluid/splash.

## Padrão uniforme

1. **Sem `class_name` como type hint** em `GlobalNetwork.gd`, `GameProtocol.gd`, `OpcodeDispatcher.gd`, `GameOpcodeReader.gd` e **`src/world/*`** + `PlayerController.gd` para managers.
2. **Variáveis de sessão untyped** — `var session_world = null`, `var game_world = null`, parâmetros `world` sem tipo.
3. **`GameWorld.gd` via `load()` tardio** em `GameProtocol._get_game_world_script()` — não `preload`.
4. **Mapa 0x64:** `parse_full_map()` retorna `{ok, state, error}`; `game_world` só é criado se `ok == true`.
5. **Wrappers na fronteira** — `GameWorld.can_walk()` evita `session_world.player` no autoload.
6. **`preload` só para utilitários estáveis** (crypto, readers, parsers).

## Arquivos corrigidos

| Arquivo | Mudança |
|---------|---------|
| `GlobalNetwork.gd` | `session_world` untyped; `can_walk()` wrapper |
| `GameProtocol.gd` | `load()` GameWorld; `game_world` sem type hint; abort 0x64 se parse falhar |
| `OpcodeDispatcher.gd` | parâmetro `world` untyped; `parse_full_map` → Dictionary |
| `GameWorld.gd` + `src/world/*` | vars/`_init` untyped (sem `TibiaMapManager` etc.) |
| `PlayerController.gd` | `_map`, `_creatures`, `auto_walk` untyped |
| `MapParser.gd` | fail-fast com `_parse_failed`; `is_valid_item_id` antes de `read_thing`; trailing skip só se OK |
| `ThingReader.gd` | `known` espelha OTC; emblem só `!known` |

## Critério de aceite

- [ ] `GlobalNetwork.gd` e `GameProtocol.gd` parseiam sem erro no editor
- [ ] Login ADM → 0x64 completo sem `item id` inválido
- [ ] `Proximos bytes` após mapa = `78` ou opcode pós-login válido
- [ ] `load("res://src/world/GameWorld.gd").new(map_state)` instancia com sucesso
- [ ] `0x6D` processado após mapa (sem warning "antes do mapa")
- [ ] `send_walk` / `session_world` preservados em runtime

## Como testar

1. Subir TFS (login 7171 + game 7172).
2. F5 no Godot → LoginScreen.
3. Login → selecionar personagem **ADM**.
4. Console esperado:
   - `GameProtocol: Login OK` (0x0A)
   - `MapParser: Mapa parseado ... Proximos bytes: 78 ...` (sem `[FALHOU]`)
   - Sem `Invalid call ... 'new'`
   - Sem `opcode 0x6D antes do mapa`
5. Se desync persistir: copiar bloco `MapDesync:` (tile, stack, hex) — indica o **primeiro** tile errado.
