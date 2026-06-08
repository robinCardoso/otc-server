# Bestiary — ideias e meta (Charm Points / Total Kills)

Documento de design. A **Fase 1 (Ataque)** já está implementada — ver [`BESTIARY-MODULE.md`](BESTIARY-MODULE.md#charms--upgrades-permanentes-opcode-207).

---

## Teto de Charm Points (catálogo completo)

Completando **100%** do catálogo (~1399 espécies), com pontos por dificuldade:

| Pontos por mob | Qtd | Subtotal |
|----------------|-----|----------|
| 1 | 421 | 421 |
| 15 | 226 | 3.390 |
| 25 | 374 | 9.350 |
| 50 | 378 | 18.900 |
| **Total** | **1399** | **~32.061** |

Um jogador real terá bem menos. O design **impede maxar tudo** — escolhas de build.

---

## Upgrades permanentes (meta longa)

Gasta pontos uma vez e fica para sempre.

| Upgrade | Cap | Custo total max (1 trilha) | Status |
|---------|-----|----------------------------|--------|
| **Ataque Melee** (+1% sword/axe/club) | 20% | 1.875 pts | **Implementado** |
| **Ataque Distance** (+1% bow/crossbow/throw) | 20% | 1.875 pts | **Implementado** |
| **Magia elemental** (+1% por elemento) | 20% / elem | 1.875 / elem | **Implementado** (7 elementos) |
| +1% resistência (por elemento, incl. físico) | 20% | 1.875 / elem | Em breve |
| +2% chance de loot | 20% | 1.875 | Em breve |
| +1% CAP | 20% | 1.875 | Em breve |

**Fase 1 (só ataque):** 9 trilhas (Melee + Distance + 7 magias) → max teórico **16.875 pts** se maxar só ataque — ainda cabe no teto global, mas somado a resist/loot/cap futuros força escolha.

### Custo escalonado por trilha (nível atual → próximo)

| Níveis | Custo por +1% |
|--------|----------------|
| 1–5 | 25 pts |
| 6–10 | 50 pts |
| 11–15 | 100 pts |
| 16–20 | 200 pts |

**Total para maxar 1 trilha (20 níveis):** 25×5 + 50×5 + 100×5 + 200×5 = **1.875 pts**.

Config no servidor: `data/lib/otcv8_bestiary_charms.lua` (`COST_TIERS`, `MAX_LEVEL`).

---

## UI da interface (implementada)

### Navegação

Abas **horizontais no topo** da janela Bestiary (800×520):

```
┌─ Bestiary ─────────────────────────────── [X] ─┐
│ [ Catálogo ] [ Charms ] [ Conquistas ]         │
│                          Charm Points: 42      │
│                          Total Kills: 71       │
├──────────────┬────────────────────────────────┤
│ CHARM        │  ATAQUE                          │
│ UPGRADES     │  ┌ Melee ──── 8/20 ── [Buy] ┐  │
│              │  └ Distance ─ 3/20 ── [Buy] ┘  │
│ > Ataque     │  Magia elemental               │
│   Resist.    │  [Fogo][Gelo][Energy][Terra]   │
│   Loot       │  [Sagr][Death][Físico]         │
│   Cap        │                                │
└──────────────┴────────────────────────────────┘
```

| Aba | Sidebar | Conteúdo |
|-----|---------|----------|
| **Catálogo** | CREATURE CLASSES | busca + filtros + grid (inalterado) |
| **Charms** | CHARM UPGRADES (Ataque default) | cards Melee, Distance, grid 7 elementos |
| **Conquistas** | — | placeholder "Em breve" |

**Charm Points / Total Kills** ficam fixos no canto superior direito (visíveis em Catálogo e Charms).

### Card de upgrade (`BestiaryCharmRow`)

```
┌─────────────────────────────────────────────┐
│ [ícone]  Ataque Melee          12% / 20%   │
│ ████████████░░░░░░░░  (barra dourada)       │
│ Próximo nível: +1%  •  Custo: 75 pts        │
│                        [ Comprar +1% ]      │
└─────────────────────────────────────────────┘
```

Botão desabilitado se: nível = 20, pontos insuficientes, ou offline.

Arquivos: `client/modules/game_bestiary/bestiary.otui`, `bestiary.lua`.

---

## Conquistas / milestones (futuro)

| Total kills | Recompensa |
|-------------|------------|
| 100 | 5 Charm Points + mensagem |
| 500 | Título + item decorativo |
| 2.500 | Outfit exclusivo |
| 10.000 | Mount ou aura no OTC |
| 50.000 | Sala/nome no hall of fame do site |

Script no servidor: ao `addKill`, se `getTotalKills(player) >= limite` e storage ainda não marcada → premia.

---

## Ranking (futuro)

Top hunters por total kills (e outro por charm points).

No cliente: aba "Ranking" no Bestiary (opcode extra) ou reutilizar site MyAAC.

---

## Referências

| Tópico | Doc |
|--------|-----|
| Cliente (UI, opcode) | [`BESTIARY-MODULE.md`](BESTIARY-MODULE.md) |
| Servidor (storages, combate C++) | [`../../server/docs/BESTIARY-MODULE.md`](../../server/docs/BESTIARY-MODULE.md) |
