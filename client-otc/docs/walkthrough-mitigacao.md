# Walkthrough — mitigação de riscos (Zezenia × Tibia)

Com `allowWalkthrough = true`, o servidor aplica duas camadas:

1. **Direção do passo** (`tile.cpp`): só diagonal escapa bloqueio de criatura; **linha reta (N/S/L/O) sempre bloqueia** como Tibia clássico.
2. **Tipo de criatura** (`allowWalkthroughForCreature()` em `player.cpp`): em diagonal, ainda valem exceções de boss/trap.

## O que ainda atravessa (passo diagonal)

- Outros **players**
- **NPCs** de cidade
- Monstros **comuns** (rat, rotworm, etc. — em geral pushable e sem immunities de boss)

## O que continua bloqueando o passo

| Situação | Resultado |
|----------|-----------|
| Andar **em linha reta** contra player/mob no tile | **Bloqueado** (sempre) |
| Diagonal em boss/trap | Bloqueado pelas regras abaixo |

### Em diagonal, ainda bloqueia se:

| Regra | Exemplo |
|-------|---------|
| Imune a invis no XML | Demons, bosses de quest com `<immunities>` |
| `rewardboss="1"` no XML | Boss de reward chest |
| Hostile + não pushable | Corpo “parede” para trap em hunt |

## Riscos que o servidor **não** resolve sozinho

### Monstros atravessando jogadores

`canWalkthrough` só vale quando um **player** entra no tile. A IA do monstro não usa essa função — o knight ainda pode segurar mob na prática se o monstro não conseguir entrar no tile do player por outras regras.

### Sprites no mesmo tile (stacking)

Vários corpos no mesmo sqm confundem clique/ataque. Mitigações:

- Cliente OTCv8: **Highlight things under cursor** (Opções)
- Design de mapa: corredores largos em áreas com muitos players
- PZ com walkthrough só entre players (comportamento antigo se desligar walkthrough global)

### Quest sem immunities no XML

Se um boss de quest **não** tiver immunities invis no `data/monster/`, o player ainda pode atravessar. Corrija no XML:

```xml
<immunities>
    <immunity invisible="1"/>
</immunities>
```

ou `rewardboss="1"` nas flags do monstro.

## Ajuste fino por monstro

Edite `data/monster/<nome>.xml`:

- Hunt fluida: mantenha pushable, sem invis immunity
- Sala de boss: invis immunity ou `rewardboss`
- Mob “parede” de trap: `pushable="0"` + `hostile="1"`
