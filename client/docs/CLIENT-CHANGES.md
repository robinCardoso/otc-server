# Alterações no cliente (Lua / C++ / projeto)

Registro das mudanças feitas além do upstream OTCv8 para funcionar com TFS 8.60 e o ambiente Windows deste projeto.

## C++ (`src/`)

### `src/client/game.cpp` — autoWalk sem preWalk no 8.60

**Problema:** um clique no mapa movia o personagem **2 sqm** (preWalk visual + passo do servidor no protocolo antigo).

**Correção:** `preWalk` no início do `autoWalk` só se `GameNewWalking` estiver ativo (protocolos novos). No 8.60 envia apenas o caminho ao servidor.

**Requer:** `.\scripts\build-client.ps1`

### `src/client/game.cpp` — Predição Local de Direção (Turn de 0ms)

**Problema:** Ao segurar `Ctrl` e girar o personagem (mudar de direção), ocorria um delay visual. Isso porque no protocolo 8.60 (sem `GameNewWalking`), o motor C++ só atualizava a direção do sprite após receber o pacote de confirmação do servidor (`Proto::Creature` turn), atrelando a velocidade visual diretamente ao ping.

**Correção:** Removido o teste condicional de `GameNewWalking` na função `Game::turn(direction)`, de forma que `m_localPlayer->setDirection(direction)` seja disparado instantaneamente no cliente (0ms) no momento do clique, enquanto o pacote de rede é transmitido em segundo plano.

**Requer:** `.\scripts\build-client.ps1`

### `src/client/creature.cpp` — `getStepDuration` + fim de passo (8.60)

**Problema:** animação usava `getStepDuration(true)` (sem ×3 na diagonal), mas `terminateWalk` esperava `getStepDuration()` (com ×3) → parada longa a cada SQM, pior com hold de 100 ms.

**Correção:** `localplayer.cpp` termina o passo com `getStepDuration(true)`; no 8.60 o intervalo usa a lei do TFS + grade de `serverBeat` (50 ms).

### `src/client/creature.cpp` — offset de caminhada desacoplado do FPS

**Problema:** no protocolo 8.60 (`!GameNewUpdateWalk`), `m_walkOffset` só mudava nos eventos agendados de `updateWalk()`; a renderização a 60 FPS repetia o mesmo offset vários frames e depois “saltava” (câmera/tocha com coice).

**Correção:**

- `getWalkOffset()` calcula o deslocamento em tempo real a partir de `m_walkTimer.ticksElapsed()` e `getStepDuration()`.
- `nextWalkUpdate` agenda ticks fixos de **16 ms** no protocolo antigo (em vez de `getStepDuration()/spriteSize`).
- `draw()`, `getDrawOffset()` e `updateWalkingTile()` usam `getWalkOffset()`.
- **v2:** progresso float (LERP sub-pixel), câmera em `getLastStepFromPosition()` (`mapview.cpp`), autowalk sem zerar offset entre passos (`localplayer.cpp`).
- **v3:** smoothstep, encadear `walk()`, predição visual autowalk (`tryVisualWalkStep`), foreground alinhado.
- **v4 (Caminhada Deslizante Zezenia-Style):**
  * Sincronização diagonal: Fator multiplicador diagonal reduzido de `3` para `2` em `Creature::getStepDuration` (C++) para perfeita sincronização com o servidor.
  * Movimento 100% linear: Comentado o `smoothstep` (ease-in-out) em `Creature::getWalkOffset` (C++) para remover qualquer desaceleração na junção de tiles.
  * Agendamento síncrono: Modificado `onWalkFinish` (Lua) para disparar passos subsequentes de forma síncrona imediata, evitando o lag de ticks do dispatcher (10-16ms).
  * Sem travas: Removido `walkLock` de `30ms` em `walk()` (Lua).
- `mapSmoothSettingsVersion` 4: `floorFading = 0`.

Ver também: `docs/MAP-SMOOTH.md`

**Requer:** `.\scripts\build-client.ps1`

### Bloqueio em linha reta + câmera estável (8.60) — **validado em jogo**

**Problema:** mob na frente (cardinal) → `preWalk`/predição visual iniciava animação e deslocava câmera/personagem fora do centro; servidor respondia *"Sorry, not possible."*

**Correção (Tibia clássico):** em **N/S/L/O**, se o tile destino tem criatura visível, **não** inicia movimento (sem `preWalk`, sem pacote, sem animação, sem mensagem do servidor).

| Arquivo | O quê |
|---------|--------|
| `tile.cpp` / `tile.h` | `blocksCardinalWalk()` |
| `walking.lua` | Checagem antes de `preWalk` / `g_game.walk` |
| `game.cpp` | `Game::walk` não envia pacote se bloqueado |
| `localplayer.cpp` | `tryVisualWalkStep` respeita o mesmo bloqueio |

**Teste validado (usuário, imagem “trapado”):** personagem cercado (paredes + Rat + Bat) — **teclado e clique no mapa** não movem o char e **não há deslocamento da câmera** (personagem permanece centralizado).

**Autowalk / clique no mapa:** `map.cpp` — A* não entra em tile com criatura (reto nem diagonal). `gameinterface.lua` delega ao pathfinder.

**Câmera vs personagem (delay):** não é TFS — usar `getLastStepFromPosition()` + `getWalkOffset()` em `mapview.cpp`.

**Sprite na direção oposta antes de andar:** `preWalk` no 8.60 — `isPreWalking` usa offset invertido. Corrigido: `preWalk` só com `GameNewWalking` em `walking.lua`; `updateWalkOffset` oposto só no protocolo novo.

**Requer:** `.\scripts\build-client.ps1`

## Projeto Visual Studio (`vc16/`)

- **PlatformToolset v143** em todas as configurações Win32.
- **VcpkgRoot** em `settings.props`.
- Caminho de libs debug corrigido (removido `D:\a\otclient\vcpkg\...` do CI).

## Lua — interface e login

### `modules/game_console/console.lua`

- **Atalho `Ctrl+F`**: Adicionado atalho global para alternar o Chat Mode (ativar/desativar chat para habilitar movimentação via ASDW).
- Correção de unbind do atalho no `terminate`.

### `modules/corelib/keyboard.lua`

- **Reversão para a Versão Original**: Mantida a velocidade nativa de baixo nível original do teclado. Em vez de filtrar modificadores no processamento global do teclado, a barreira de modificadores foi migrada para o topo do módulo de caminhada em `walking.lua`.

### `modules/game_walking/walking.lua`

- **Rotação Instantânea e Transição Fluida**:
  - **Barreira de Modificadores no Walk**: Adicionada checagem no início de `walk()` para abortar passos físicos se modificadores (`Ctrl`, `Shift` ou `Alt`) estiverem pressionados, impedindo que o jogador ande por engano ao virar o personagem.
  - **Remoção da Trava Rígida de 200ms**: Alterado o `lockWalk(200)` ao soltar a tecla (`KeyUp` de rotação) para respeitar dinamicamente a configuração do usuário `walkTurnDelay` (que é de `0ms` por padrão), zerando todo atraso de movimento pós-rotação.

### `modules/game_interface/gameinterface.lua` — Classic control + botão direito

**Problema:** com **Classic control** ativo (Options → Game), RMB no mapa chamava `g_game.use()` no chão (`useThing` = ground) e o personagem **andava** até o tile.

**Correção:** no bloco classic, RMB sem modificador: ataca criatura; `use` só se `useThing` não for chão; tile vazio retorna sem ação; guarda extra impede `autoWalk` com RMB.

**Requer:** reiniciar `otclient_gl.exe` (só Lua).

### `modules/gamelib/ui/uiminimap.lua` — Classic control + minimapa

Com **Classic control**, clique no minimapa **não** dispara `player:autoWalk()` (HUD, painel lateral e mapa expandido). RMB continua só com menu **Create mark**.

### `modules/game_interface/gameinterface.lua` (outros)

- Guard em `game_actionbar.switchMode` (evita crash se função ausente).
- Fade-in/out ao entrar/sair do jogo (`g_effects.fadeIn` / `fadeOut`).
- `GameForceFirstAutoWalkStep` **desligado** no `onGameStart`.

### `modules/game_actionbar/actionbar.lua`

- **Correção "Assign Spell" (lista vazia)**:
  - **`translateVocation`**: Para protocolo **8.60** (`getClientVersion()` 860–1099), usa o id de vocação do servidor direto (igual `game_spelllist`), sem mapear 1→8 etc. que escondia todas as magias quando `getClientVersion() >= 910`.
  - **Filtro de nível**: `spellData.level` passou a ser copiado para `widget.spellData`; antes `level` era `nil` e com "Only show usable spells (Level)" marcado **nenhuma** magia aparecia.
  - **Rookgaard**: vocação `0` continua desmarcando filtro de vocação ao abrir a janela.
- **Lista do TFS (opcode 202)**:
  - `registerExtendedJSONOpcode(202)` — cache `serverSpellList` após login (~800 ms) e ao abrir Assign Spell.
  - Lista = `player:getInstantSpells()` no servidor; ícones/exhaust/grupos do `SpellInfo` local quando o nome coincide.
  - Filtro "vocation" desligado com lista do servidor; fallback para `SpellInfo` se o opcode não responder.
  - Doc: `docs/ASSIGN-SPELL.md`, plano em `otserv_860/docs/SPELL-LIST-PLAN.md`.

### `modules/game_combatpower/` (opcode 203) ✅

Modal **Combat Power** — preview de `player:getCombatPreview()` no TFS.

| Item | Detalhe |
|------|---------|
| Arquivos | `combatpower.lua`, `combatpower.otui`, `combatpower.otmod` |
| Abrir | Botão top bar (*unjustified points*) ou **Ctrl+Shift+O** |
| Layout | Modal **580×640** — stats Ataque\|Defesa, equipamento, magias, runas de cura |
| Ícones | `Spells.getSpellIcon` / `getRuneDisplayIcon` / `applyItemIcon` — **`clientId`** do servidor |
| Refresh | Equip, skill, level, ML, fight mode; debounce 450 ms |

Doc completa: [`docs/COMBAT-POWER-MODULE.md`](COMBAT-POWER-MODULE.md). Plano servidor: `otserv_860/docs/COMBAT-POWER-PLAN.md`.

### `modules/client_options/options.lua`

Defaults de **movimento fluido** e migração `walkSettingsVersion = 2`:

| Opção | Default |
|--------|---------|
| dash | true |
| smartWalk | true |
| hotkeyDelay | 30 ms |
| walkFirstStepDelay | 0 ms |
| walkTurnDelay | 0 ms |
| walkCtrlTurnDelay | 0 ms |
| walkStairsDelay | 0 ms |
| walkTeleportDelay | 150 ms |
| floorFading | 0 ms (mapa; migração `mapSmoothSettingsVersion`) |
| classicView | false |
| vsync | false |
| backgroundFrameRate | 201 (max) |
| optimizationLevel | 0 (Automatic) |
| cacheMap | false |

Perfis antigos em `%AppData%\otclientv8\` são atualizados na primeira abertura após a migração.

### `modules/client_options/game.otui`

- Slider `walkFirstStepDelay`: mínimo **0** (antes 50).
- Label ctrl turn usa `walkCtrlTurnDelay` (bug de cópia corrigido).

## Viewport 25×20 e Classic view ✅

Mapa na rede alinhado ao TFS (**25×20**). A opção **Classic view** (Interface) altera **só o zoom** do mapa no painel — layout de painéis, chat e action bar permanece o mesmo.

| Classic view | Comportamento |
|--------------|---------------|
| **ON** | Proporção Tibia (~15×11), `keepAspectRatio`, barras cinzas (letterbox) |
| **OFF** | `fitZoomToScreen` preenche largura com os 25 tiles do servidor — sem faixas pretas |

**Doc canônica:** [`docs/VIEWPORT-CLASSIC-VIEW.md`](VIEWPORT-CLASSIC-VIEW.md) + [`../server/docs/VIEWPORT-MODULE.md`](../server/docs/VIEWPORT-MODULE.md).

### C++ (`src/client/`)

| Arquivo | Mudança |
|---------|---------|
| `map.cpp` | `resetAwareRange()` → 12, 9, 12, 10 |
| `uimap.cpp` | `fitZoomToScreen`, `refreshMapGeometry`, `clampVisibleDimensionToAwareRange`, `getMapRect` |
| `mapview.cpp` | `setStretchMap(false)` — sem esticar sprites |
| `luafunctions_client.cpp` | Bindings Lua para os métodos acima |

**Requer:** `.\scripts\build-client.ps1`

### Lua / UI

| Arquivo | Mudança |
|---------|---------|
| `init.lua` | `CLASSIC_MAP_TARGET_TILE_PX`, `CLASSIC_MAP_ZOOM_FALLBACK`, `CLASSIC_MAP_ZOOM_MAX` |
| `modules/game_viewport/viewport.lua` | `g_map.setAwareRange(12,9,12,10)` — sem opcode 206 no login |
| `modules/game_interface/gameinterface.lua` | `refreshViewMode` (layout clássico fixo), `updateClassicMapView` (zoom ON/OFF) |
| `modules/game_features/features.lua` | `GameBiggerMapCache` no protocolo 860 |
| `modules/game_bestiary/bestiary.lua` | Toast de kill via `getMapRect()` — canto dos tiles, não faixa cinza |

**Requer:** reiniciar `otclient_gl.exe` (Lua); **relog** após novo `tfs.exe`.

**Não usar:** modo wide OTC original (`fill('parent')` no mapa, painéis transparentes, `setStretchMap(true)`).

## Shop OTCv8 (`game_shop`)

Loja premium via **extended opcode 201** — não é NPC trade (`game_npctrade`).

**Novos itens na loja:** editar **`otserv_860/data/creaturescripts/scripts/otcv8_shop.lua`** (`initShop()`), não este módulo.

Documentação: `docs/SHOP-MODULE.md` + `otserv_860/docs/SHOP-MODULE.md`. Cliente: `GameExtendedOpcode` ≥ 860 em `features.lua`.

## Minimap ampliado (centralizado)

| Item | Detalhe |
|------|---------|
| Botão **Expand** | No minimap (canto superior esquerdo, ao lado de Center) |
| Atalho | **Ctrl+Shift+M** (já existia; agora com overlay centralizado) |
| Fechar | Botão **Close** na barra do overlay (`onClick` em Lua), **Expand**, clique no fundo escuro, **Escape** |
| Arquivos | `modules/game_minimap/minimap.lua`, `minimap_overlay.otui`, `data/styles/40-minimap.otui` |

**Cliente:** reiniciar `otclient_gl.exe` (só Lua/UI).

## Minimap — party (opcode 204)

| Item | Detalhe |
|------|---------|
| Você | Cruz **azul** (`#3388FF`) — `uiminimap.lua` |
| Membros | Quadrado **verde** 8×8 na posição X/Y (**qualquer distância** no mapa) |
| Outro andar | Mesmo X/Y no plano da câmera, quadrado **pisca** (~450 ms); tooltip com andar |
| Dados | Opcode **204** + cache `partyRemoteMembers`; refinamento por espectadores se na tela |
| Atualização | Servidor push 500 ms; cliente pede 250 ms; desenho 150 ms |
| Registro opcode | `registerExtendedJSONOpcode(204)` **sempre** no init/online (igual Shop 201) |

**Arquivos:** `modules/game_minimap/`, `modules/game_party/`, `uiminimap.lua`, `40-minimap.otui`.

**Painel Party:** `modules/game_party/` — Ctrl+Shift+P; lista membros HP/mana, convites, shared exp.

**Doc:** `docs/PARTY-MINMAP-MODULE.md` + `otserv_860/docs/PARTY-MODULE.md`.

Convidados pendentes **não** aparecem. **Cliente:** reiniciar `otclient_gl.exe`. **Servidor:** reiniciar `tfs.exe` após Lua/GlobalEvent.

## Action bar — Equip/Unequip (8.60 + TFS custom)

| Item | Detalhe |
|------|---------|
| Módulo | `modules/game_actionbar/actionbar.lua` |
| Ação | `ACTION.EQUIP` → `g_game.equipItemId(clientId, subType)` |
| Versão | Antes só rodava com `getClientVersion() >= 910`; corrigido para **`>= 860`** |
| Pacote | `g_game.equipItem` → `sendEquipItem` — opcode **119** (`0x77`), mesmo handler no servidor |

**Cliente:** reiniciar `otclient_gl.exe` (só Lua, sem rebuild C++).

**Servidor:** ver `otserv_860/docs/SERVER-CHANGES.md` — `playerEquipItem` com `internalMoveItem` (equip andando) e `playerUseItem` para abrir backpack/bags no inventário sem fila cancelada pelo walk.

## Servidor relacionado (`otserv_860`)

Ver **`otserv_860/docs/SERVER-CHANGES.md`** — fluidez rede/ações/walkthrough:

- `config.lua`: `maxPacketsPerSecond = 1000`, `timeBetweenActions/ExActions = 100`, `allowWalkthrough = true`
- C++: `ALLOW_WALKTHROUGH` em `configmanager` + `player.cpp`
- C++ (`server.cpp`): desativação do algoritmo de Nagle (`tcp::no_delay(true)`) na aceitação da conexão em `ServicePort::onAccept` para latência de rede zero nos passos do player.

Também: `enableLiveCasting = false`, fixes `iologindata` / `protocollogin`

## Assets obrigatórios

```
data/things/860/Tibia.dat
data/things/860/Tibia.spr
```

Sem arquivos válidos 8.60: erro no log, mapa/sprites incorretos ou crash ao entrar no jogo.

## Log útil

`otcv8-dev/otclientv8.log` — erros de dat, Lua (`switchMode`), `Login to 127.0.0.1:7172`, etc.
