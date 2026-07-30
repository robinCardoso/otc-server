# Plano de Implementação (Revisado): Sistema de Walking

> Baseado na análise completa do código real do OTClient (`creature.cpp`, `creature.h`, `mapview.cpp`, `protocolgameparse.cpp`)

---

## 1. Como o OTClient Funciona de Verdade (Análise do Código Real)

### 1.1 Ciclo de Vida de um Passo
Quando o servidor envia o opcode `0x6D` (GameServerMoveCreature / opcode 109):
1. O mapa move a criatura do Tile antigo para o novo **imediatamente** nos dados lógicos.
2. A função `creature->walk(oldPos, newPos)` é chamada, que:
   - Calcula a direção (`m_lastStepDirection = oldPos.getDirectionFromPosition(newPos)`).
   - Salva `m_lastStepFromPosition = oldPos` e `m_lastStepToPosition = newPos`.
   - Define `m_walking = true` e reinicia o `m_walkTimer`.
   - Chama `nextWalkUpdate()` para agendar o primeiro tick de animação.
3. **`getPrewalkingPosition()`** — a posição de *âncora de desenho* — retorna `m_lastStepFromPosition` enquanto a criatura ainda está andando, não a posição atual. O sprite é desenhado a partir do tile ANTIGO e desloca **para frente** com o offset calculado.

### 1.2 A Fórmula Real de Duração do Passo (TFS 8.60)
Extraída de `getStepDuration()` em `creature.cpp`:
```
// Constantes fixas para protocolo 8.60 (client_version < 981)
kSpeedA = 857.36
kSpeedB = 261.29
kSpeedC = -4795.01

calculatedStepSpeed = max(1, floor(kSpeedA * log(speed/2.0 + kSpeedB) + kSpeedC + 0.5))
interval = floor((1000 * groundSpeed) / calculatedStepSpeed)

// Arredondar para cima para o múltiplo mais próximo do ServerBeat (50ms)
interval = ceil(interval / serverBeat) * serverBeat

// Diagonal custa 1.5x mais tempo
if direction is diagonal:
    interval *= 1.5
```
- `speed` = velocidade da criatura (enviada pelo servidor, padrão 200)
- `groundSpeed` = velocidade do chão do tile de DESTINO (ex: Grass=150, Mud=180, Ice=120)
- `serverBeat` = 50ms (enviado no pacote de login)

### 1.3 Cálculo do Walk Offset (Função Real)
Extraído de `getWalkOffset()` e `pixelsToWalkOffsetFromSource()`:
```
stepDuration_ms = getStepDuration(ignoreDiagonal=true)
elapsed_ms      = walkTimer.ticksElapsed()
progress        = clamp(elapsed_ms / stepDuration_ms, 0.0, 1.0)
pixelsWalked    = progress * 32  # 32 = sprite size

# Offset a partir do tile de ORIGEM:
match direction:
    Norte:   walkOffset = (0,       -pixelsWalked)
    Sul:     walkOffset = (0,        pixelsWalked)
    Leste:   walkOffset = (pixelsWalked, 0)
    Oeste:   walkOffset = (-pixelsWalked, 0)
    NE:      walkOffset = (pixelsWalked, -pixelsWalked)
    SE:      walkOffset = (pixelsWalked,  pixelsWalked)
    SO:      walkOffset = (-pixelsWalked, pixelsWalked)
    NO:      walkOffset = (-pixelsWalked,-pixelsWalked)
```
**ATENÇÃO:** O offset parte do tile de ORIGEM (posição anterior). Quando `progress=0`, a criatura está no tile antigo (offset zero). Quando `progress=1`, ela chegou ao tile novo (offset == 32 px na direção do passo). A câmera compensa subtraindo esse offset.

### 1.4 Fases de Animação (Pernas Mexendo)
Extraído de `updateWalkAnimation()`:
```
footAnimPhases = totalAnimPhases - 1  # ex: 3 fases totais => 0,1,2
footDelay = ceil((stepDuration + 20) / footAnimPhases)  # ms por frame
footDelay = max(footDelay, 20)

# Troca de frame:
if currentTime >= lastFootStepTime + footDelay AND pixelsWalked < 32:
    footStep++
    walkAnimPhase = 1 + (footStep % footAnimPhases)
    # reset timer
    lastFootStepTime += footDelay

# Ao completar o passo:
if pixelsWalked == 32:
    # Agendar reset para 50ms depois
    walkAnimPhase = 0  # volta à pose parada
    footStep = 0
```

---

## 2. Arquitetura de Alto Desempenho para o Godot 4

### Princípio Central
> **NÃO usar Tween, AnimationPlayer ou Node2D para cada criatura.**  
> Todos os cálculos de movimento são matemáticos (baseados em `Time.get_ticks_msec()`) e executados no momento do `_draw()`. Sem objetos temporários. Sem alocações por frame.

### 2.1 Estrutura de Dados: `CreatureState` (classe leve)
Criar um `Resource` ou dicionário-padrão por criatura com os campos:
```gdscript
# Campos estáticos (do protocolo)
var id: int
var name: String
var speed: int          # velocidade recebida do servidor
var direction: int      # 0=Norte, 1=Leste, 2=Sul, 3=Oeste
var look_type: int
var health_percent: int
var tile_pos: Vector3i  # posição ATUAL (tile de destino)

# Campos dinâmicos de walking
var is_walking: bool = false
var walk_start_ms: int = 0           # Time.get_ticks_msec() no início do passo
var step_duration_ms: int = 0        # calculado pela fórmula
var walk_direction: int = 2          # direção do passo atual
var from_tile_pos: Vector3i          # tile de ORIGEM (âncora de desenho)
var walked_pixels: int = 0           # max pixels andados (anti-paralyze)

# Campos de animação de sprite
var walk_anim_phase: int = 0
var foot_step: int = 0
var foot_last_step_ms: int = 0
```

### 2.2 Novo Script: `CreatureWalker.gd` (Singleton ou static)
Responsável por toda a matemática de walking. Não tem estado próprio:
```gdscript
# Constantes TFS 8.60
const SPEED_A := 857.36
const SPEED_B := 261.29
const SPEED_C := -4795.01
const TILE_SIZE := 32
const DIAGONAL_FACTOR := 1.5

static func calc_step_duration(speed: int, ground_speed: int,
                               server_beat: int, is_diagonal: bool) -> int:
    if speed < 1: return 0
    var step_speed := maxf(1.0, floor(SPEED_A * log(speed / 2.0 + SPEED_B) + SPEED_C + 0.5))
    var interval := int(floor(1000.0 * ground_speed / step_speed))
    # Arredondar para cima no múltiplo do beat
    interval = int(ceil(float(interval) / server_beat)) * server_beat
    if is_diagonal:
        interval = int(interval * DIAGONAL_FACTOR)
    return max(interval, server_beat)

static func get_walk_offset(creature) -> Vector2:
    if not creature.is_walking:
        return Vector2.ZERO
    var elapsed := Time.get_ticks_msec() - creature.walk_start_ms
    if elapsed >= creature.step_duration_ms:
        return Vector2.ZERO
    # progress linear (idêntico ao OTC para protocol 860)
    var progress := float(elapsed) / float(creature.step_duration_ms)
    var pixels := progress * TILE_SIZE
    return _direction_to_offset(creature.walk_direction, pixels)

static func _direction_to_offset(dir: int, pixels: float) -> Vector2:
    match dir:
        0: return Vector2(0, -pixels)           # Norte
        1: return Vector2(pixels, 0)            # Leste
        2: return Vector2(0, pixels)            # Sul
        3: return Vector2(-pixels, 0)           # Oeste
        4: return Vector2(pixels, -pixels)      # NE
        5: return Vector2(pixels, pixels)       # SE
        6: return Vector2(-pixels, pixels)      # SO
        7: return Vector2(-pixels, -pixels)     # NO
    return Vector2.ZERO

static func get_anim_phase(creature, total_phases: int) -> int:
    if not creature.is_walking or total_phases <= 1:
        return 0
    return creature.walk_anim_phase

static func update_walk(creature, server_beat: int) -> void:
    var elapsed := Time.get_ticks_msec() - creature.walk_start_ms
    var pixels_walked := min(int(float(elapsed) * TILE_SIZE / max(creature.step_duration_ms, 1)), TILE_SIZE)
    creature.walked_pixels = max(creature.walked_pixels, pixels_walked)
    _update_anim_phase(creature)
    if elapsed >= creature.step_duration_ms:
        _terminate_walk(creature)

static func _update_anim_phase(creature) -> void:
    var foot_phases := 2  # trocar por dado real do DAT depois
    if foot_phases <= 0:
        return
    var foot_delay := max(int(ceil(float(creature.step_duration_ms + 20) / foot_phases)), 20)
    var now := Time.get_ticks_msec()
    if creature.walked_pixels < TILE_SIZE and now >= creature.foot_last_step_ms + foot_delay:
        creature.foot_step += 1
        creature.walk_anim_phase = 1 + (creature.foot_step % foot_phases)
        creature.foot_last_step_ms += foot_delay

static func _terminate_walk(creature) -> void:
    creature.is_walking = false
    creature.walked_pixels = 0
    creature.walk_anim_phase = 0
    creature.foot_step = 0
```

### 2.3 Modificação no `MapView.gd`

#### a) Habilitar `_process` para redraw somente quando há movimento:
```gdscript
var _any_creature_walking := false

func _process(_delta: float) -> void:
    if _any_creature_walking:
        queue_redraw()

func render(map_state, player_id: int) -> void:
    # ... código existente ...
    # Detectar se há criaturas em movimento
    _any_creature_walking = _has_walking_creatures()
    queue_redraw()
```

#### b) Compensação da câmera (Smooth Scroll):
```gdscript
var _camera_walk_offset := Vector2.ZERO

func _get_camera_offset(player_id: int) -> Vector2:
    # Encontrar a criatura do jogador local e pegar seu walk_offset
    var local_player = _find_creature_by_id(player_id)
    if local_player == null or not local_player.is_walking:
        return Vector2.ZERO
    return CreatureWalker.get_walk_offset(local_player)

func _tile_base_position(tile_pos: Vector3i) -> Vector2:
    var z_shift: int = _camera_pos.z - tile_pos.z
    var dest := Vector2i(
        (tile_pos.x - _camera_pos.x + MapState.MAP_LEFT - z_shift) * TILE_SIZE,
        (tile_pos.y - _camera_pos.y + MapState.MAP_TOP - z_shift) * TILE_SIZE
    )
    # Subtrair o offset da câmera (compensa o movimento do jogador)
    return Vector2(dest) - _camera_walk_offset
```

#### c) Aplicar walk_offset na posição das criaturas durante o draw:
```gdscript
func _draw_creatures_at(tile, tile_pos: Vector3i, base_pos: Vector2) -> void:
    var elevation: int = _tile_state(tile_pos).draw_elevation
    for creature in tile.creatures:
        var walk_offset := CreatureWalker.get_walk_offset(creature)
        # A âncora de desenho é o tile de ORIGEM do passo
        var anchor_pos := base_pos
        if creature.is_walking:
            # Calcular a posição base a partir do tile de origem
            anchor_pos = _tile_base_position(creature.from_tile_pos)
        _append_creature_drawable(creature, anchor_pos + walk_offset, elevation)
```

### 2.4 Modificação no `GameOpcodeReader.gd` (Opcode 0x6D)
Atualmente o opcode `0x6D` apenas pula os bytes. Precisamos processar o movimento:
```gdscript
# No GameProtocol.gd ou num novo handler:
func _handle_creature_move(buffer: StreamPeerBuffer) -> void:
    # Estrutura do pacote 0x6D (TFS 8.60):
    # oldPos (3 bytes: x=u16, y=u16, z=u8) + oldStackPos (u8)
    # newPos (3 bytes)
    var old_pos := ProtocolReader.read_position(buffer)
    var old_stack_pos := buffer.get_u8()
    var new_pos := ProtocolReader.read_position(buffer)
    
    # Localizar criatura no tile antigo
    var old_tile = map_state.get_tile(old_pos)
    if old_tile == null: return
    var creature = _get_creature_at_stack(old_tile, old_stack_pos)
    if creature == null: return
    
    # Mover criatura nos dados lógicos
    old_tile.creatures.erase(creature)
    var new_tile = map_state.get_or_create_tile(new_pos)
    new_tile.creatures.append(creature)
    
    # Calcular duração do passo
    var is_diagonal = _is_diagonal(old_pos, new_pos)
    var ground_speed = _get_ground_speed(map_state, new_pos)
    var duration = CreatureWalker.calc_step_duration(
        creature.speed, ground_speed, SERVER_BEAT, is_diagonal
    )
    
    # Iniciar animação de walking
    creature.tile_pos = new_pos
    creature.from_tile_pos = old_pos
    creature.walk_direction = _direction_from_positions(old_pos, new_pos)
    creature.is_walking = true
    creature.walk_start_ms = Time.get_ticks_msec()
    creature.step_duration_ms = duration
    creature.walked_pixels = 0
    creature.direction = creature.walk_direction
```

---

## 3. Arquivos a Criar ou Modificar

| Arquivo | Ação | Descrição |
|---|---|---|
| `src/game/creature/CreatureState.gd` | **[CRIAR]** | Classe de dados da criatura com campos de walking |
| `src/game/creature/CreatureWalker.gd` | **[CRIAR]** | Toda a matemática de walking (static) |
| `src/game/map/MapView.gd` | **[MODIFICAR]** | Integrar walk_offset, camera_offset, _process redraw |
| `src/core/network/GameOpcodeReader.gd` | **[MODIFICAR]** | Processar opcode `0x6D` corretamente |
| `src/game/map/MapState.gd` | **[MODIFICAR]** | Adicionar `get_or_create_tile()` e registro de criaturas |
| `src/io/ThingSpriteFactory.gd` | **[MODIFICAR]** | Aceitar `animation_phase` no `get_creature_texture()` |

---

## 4. Detalhes de Performance

| Técnica | Motivo |
|---|---|  
| Cálculo do offset por `Time.get_ticks_msec()` no `_draw` | Evita alocações por frame; sem Tween/Timer por criatura |
| `_process` só chama `queue_redraw()` se há walking | CPU vai a 0% quando ninguém está se movendo |
| `CreatureWalker` é totalmente `static` | Sem instância, sem referências, sem GC |
| `from_tile_pos` salvo na criatura | Evita recalcular a posição de âncora a cada frame |
| `walked_pixels` acumulativo | Proteção contra slow-motion por paralyze (igual ao OTC) |

---

## 5. Ordem de Implementação Recomendada
1. Criar `CreatureState.gd` — substituir os dicionários de criatura brutos
2. Criar `CreatureWalker.gd` — implementar todas as funções static
3. Modificar `GameOpcodeReader.gd` — processar opcode `0x6D` de verdade
4. Modificar `MapView.gd` — integrar walk_offset e câmera suave
5. Modificar `ThingSpriteFactory.gd` — adicionar suporte a `animation_phase`
6. Testar com o ADM e verificar se o passo está sincronizado com o servidor
