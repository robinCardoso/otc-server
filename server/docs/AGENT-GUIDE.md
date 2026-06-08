# Guia do agente — otserv_860-orig

Documento principal para implementar features no stack **-orig** sem reintroduzir bugs validados em maio/2026.

## Pastas e papéis

| Papel | Caminho |
|-------|---------|
| Servidor (editar) | `C:\8.6\otserv_860\otserv_860-orig\` |
| Cliente (editar) | `C:\8.6\otserv_860\otcv8-dev-orig\` |
| Referência estável | `C:\8.6\otserv_860_sem_erro\` — TFS sem combat power; usar para diff de login/protocolo |
| Dev (não editar) | `otserv_860/`, `otcv8-dev/` |
| Docs de referência | `otserv_860/docs/`, `otcv8-dev/docs/` |

## Lições aprendidas (resumo)

### 1. Viewport 25×20 — alinhar servidor e cliente

O TFS deste fork envia mapa **25×20** (`map.h` → `protocolgame.cpp`: `GetMapDescription(..., Map::clientMapWidth, Map::clientMapHeight)`).

O OTC espelha em `resetAwareRange()` → left=12, top=9, right=12, bottom=10 (`client/map.cpp`, `game_viewport/viewport.lua`).

**Classic view** (opção Interface) altera só o **zoom** no cliente — **não** o pacote de rede. Ver [`../client/docs/VIEWPORT-CLASSIC-VIEW.md`](../client/docs/VIEWPORT-CLASSIC-VIEW.md) e [`VIEWPORT-MODULE.md`](VIEWPORT-MODULE.md).

Se cliente e servidor divergirem (ex.: OTC pedindo **29×20** com TFS em 18×14), o parser do opcode **0x64** lê bytes de coordenada como `itemId` → log `invalid id 61823` / `62078` e desconexão. **Não** é DAT/SPR corrompido — é dessincronia de protocolo.

**Não** usar `changeMapAwareRange(31,21)` nem opcode **206** no login sem alinhar TFS + rebuild C++.

### 2. Extended opcodes — handler separado por número

Shop (**201**), Spell List (**202**), Combat Power (**203**) e Bestiary (**207**) **nunca** no mesmo `onExtendedOpcode`.

Registro correto no login:

```lua
player:registerEvent("ExtendedOpcodeShop")
player:registerEvent("ExtendedOpcodeSpellList")
player:registerEvent("ExtendedOpcodeCombatPower")
player:registerEvent("ExtendedOpcodeStock")
player:registerEvent("ExtendedOpcodeBestiary")
player:registerEvent("BestiaryKill")
```

Doc Bestiary: [`BESTIARY-MODULE.md`](BESTIARY-MODULE.md) + [`../../client/docs/BESTIARY-MODULE.md`](../../client/docs/BESTIARY-MODULE.md).

`creaturescripts.xml` declara eventos `type="extendedopcode"` distintos (e `type="kill"` para BestiaryKill).

### 3. Combat Power — crash e teste A/B

| Sintoma | Causa |
|---------|--------|
| `tfs.exe` fecha com `0xC0000005` logo após login OTC | Opcode **203** → `player:getCombatPreview()` → `CombatPreview::pushSpellPreviews` |
| Login OK com `ExtendedOpcodeCombatPower` comentado | Confirma culpado 203 |

**Fixes em C++** (`src/combatpreview.cpp`):

- `isSpellForPlayerVocation` — só magias da vocação do player; ignora spells sem voc map (house/monster).
- Grupos só **attack** e **healing**; exclui `House *`.
- Null checks em `g_spells`, runas, containers.
- `ValueCallback::getPreviewValues` valida script antes de push (ver comentário em `data/lib/otcv8_combatpower.lua`).

Doc dedicada: [COMBAT-POWER.md](./COMBAT-POWER.md).

### 4. Login — outros crashes evitados

| Problema | Fix |
|----------|-----|
| Crash no primeiro login OTC | `sendOutfitWindow` só se `client.os < 10` (`login.lua`) |
| Crash / tabela MEMORY | Remover INSERT duplicado em `players_online` no Lua (C++ já insere) |
| Mapa Yasir corrompido | Desabilitar spawn Yasir (`yasirEnabled = false` ou globalevent off) |
| Char nasce em 0,0,0 | MyAAC: `getTemplePositionForTown()` em `CreateCharacter.php` |

### 5. Performance no login

- Cliente: primeira requisição 203 após **900 ms**; debounce **450 ms** em equip/skill (`scheduleRequest`).
- Servidor: **uma** chamada `getCombatPreview()` por resposta (`Otcv8CombatPower.buildPlayerCombatPower`).
- C++: não iterar todas instant spells do servidor — filtrar por vocação antes de preview de dano.

### 6. Depot / Estoque — persistência RAM vs banco

O Estoque (opcode **205**) usa o depot TFS normal (`player_depotitems`), **não** tabela própria.

| Conceito | Detalhe |
|----------|---------|
| RAM | `Player::depotChests` — preenchido por `getDepotChest(id, true)` |
| Flag mapa | `lastDepotId` — só muda ao abrir **locker no mapa** (`actions.cpp`) |
| Save | `IOLoginData::savePlayer` grava depot se `lastDepotId != -1 \|\| !depotChests.empty()` |
| Armadilha | UI do Estoque lê RAM — catálogo OK **não prova** que o DB foi gravado |

**Bug histórico (maio/2026):** save só com `lastDepotId != -1` → deposit all via Estoque sem abrir depot no mapa → logout perdia itens permanentemente.

**Nunca reverter** a condição dupla em `src/iologindata.cpp` sem reler [DEPOT-SYSTEM.md](./DEPOT-SYSTEM.md).

Checklist após mudança no depot/Estoque: Teste A/B em [STOCK-MODULE.md](./STOCK-MODULE.md) + SQL em `player_depotitems`.

## Erros comuns

| Erro / sintoma | Interpretação errada | Causa real |
|----------------|---------------------|------------|
| `invalid id 62078` no 0x64 | “item errado no mapa” | Viewport/parse dessincronizado |
| `corrupt data (id: 440…)` no DAT | “DAT quebrado” | 1ª leitura U16 em pack Extended; 2ª com U32 OK |
| Crash só com OTC | “bug do cliente” | Muitas vezes opcode extended ou outfit no login |
| Shop e Power no mesmo script | “menos arquivos” | Opcode errado tratado → JSON inválido ou crash |
| Itens sumiram após relog (Estoque) | “bug do cliente OTC” | Save ignorou depot (`lastDepotId==-1`); mochila vazia foi salva |
| Catálogo Estoque OK na sessão | “está persistido” | Catálogo lê `depotChests` em RAM — validar SQL |

## Como debugar

### Logs TFS

Ver [LOGS.md](./LOGS.md). Resumo:

1. `enableTfsConsoleLog = true` → `rodar-tfs-novo.bat` → `data/logs/tfs/tfs-console_*.log`
2. `enableTfsDiagnosticLog = true` → rebuild → linhas `[login]` / `[extopcode]` no console
3. Teste in-game: `!power` (combat), mensagens em `otcv8_combatpower.lua` com `print` em falha de `send`

### Teste A/B (isolamento)

1. Comentar **uma** linha `registerEvent` no `login.lua`.
2. Reiniciar TFS, login OTC.
3. Se crash sumir → culpado o módulo desregistrado.
4. Reativar e corrigir na fonte (C++ ou Lua), não “só desligar”.

### Diff com sem_erro

Para login/mapa/protocolo base:

```powershell
fc /n C:\8.6\otserv_860\otserv_860_sem_erro\src\protocolgame.cpp C:\8.6\otserv_860\otserv_860-orig\src\protocolgame.cpp
```

Combat power existe só em `-orig`; não esperar paridade com `sem_erro` nessa feature.

## Checklist antes de merge de feature OTC

- [ ] Opcode numérico único documentado
- [ ] `creaturescripts.xml` + `login.lua` com nome de evento dedicado
- [ ] Cliente registra JSON opcode uma vez (sem duplicar em dois módulos)
- [ ] Teste A/B no login
- [ ] `!power` ou talkaction de diagnóstico se aplicável
- [ ] Rebuild se tocou `src/`
- [ ] Atualizar `.cursorrules` ou este guia se nova armadilha aparecer

## Conta e conexão de teste

| Campo | Valor |
|-------|--------|
| Host | `127.0.0.1:7171:860` |
| Conta | `robinadmin` |
| Senha | `GodPcs759153` |
| Personagens | ADM, Testerman |

## Referências rápidas

- Build servidor: [BUILD.md](./BUILD.md)
- Combat Power: [COMBAT-POWER.md](./COMBAT-POWER.md)
- Estoque depot: [STOCK-MODULE.md](./STOCK-MODULE.md) — opcode **205**, cliente **Ctrl+Shift+E**, `!estoque`
- Assign Spell: [SPELL-LIST-MODULE.md](./SPELL-LIST-MODULE.md) — opcode **202**, `spells.xml`, `!spelllist`
- **Depot TFS (persistência):** [DEPOT-SYSTEM.md](./DEPOT-SYSTEM.md) — ler antes de tocar `iologindata.cpp` ou save/load
- Regras Cursor: `../.cursorrules`
