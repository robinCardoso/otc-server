# Pesquisa Zezenia vs Tibia / OTCv8 — status no projeto



Documento base: notas sobre fluidez (LERP, input lock, rede, `config.lua`).  

Repositórios: cliente `otcv8-dev/`, servidor `otserv_860/`.



---



## Tabela geral — aplicado / parcial / pendente



| Item | Camada | Status | Onde |

|------|--------|--------|------|

| `getWalkOffset()` tempo real (8.60) | Cliente | **Aplicado** | `creature.cpp` |

| Progresso float + smoothstep | Cliente | **Aplicado** | `creature.cpp` |

| `Point` float na renderização | Cliente | **Pendente** | Ainda `std::lround` → `Point` int |

| Frametime dinâmico no progresso | Cliente | **Pendente** | — |

| Câmera `getLastStepFromPosition` | Cliente | **Aplicado** | `mapview.cpp` |

| Chão via `calcFramebufferSource` + offset | Cliente | **Aplicado** | `mapview.cpp` |

| Foreground criaturas alinhado (follow) | Cliente | **Aplicado** | `mapview.cpp` |

| Autowalk sem `terminateWalk` entre passos | Cliente | **Aplicado** | `localplayer.cpp` |

| Encadear passos (`walk` chain) | Cliente | **Aplicado** | `creature.cpp` |

| Predição visual autowalk 8.60 (sem 2 sqm) | Cliente | **Aplicado** | `game.cpp`, `localplayer.cpp` |

| `preWalk` no autowalk 8.60 | Cliente | **Não usar** | Causa 2 sqm; substituído por `tryVisualWalkStep` |

| `preWalk` teclado (walking.lua) | Cliente | **Aplicado** | Só se tile livre em cardinal |

| Bloqueio cardinal com criatura (sem movimento/câmera) | Cliente | **Aplicado + validado** | `blocksCardinalWalk`, `walking.lua`, `game.cpp` |

| Offset/câmera parado (`!m_walking` → 0) | Cliente | **Aplicado + validado** | `creature.cpp`, `mapview.cpp` |

| `game.cpp` sem preWalk autowalk 8.60 | Cliente | **Aplicado** | Mantido |

| `maxPacketsPerSecond = 1000` | Servidor | **Aplicado** | `config.lua` |

| `timeBetweenActions/Ex = 100` | Servidor | **Aplicado** | `config.lua` |

| Walkthrough só **diagonal** | Servidor | **Aplicado** | `tile.cpp`, `player.cpp` |

| Walkthrough boss/trap | Servidor | **Aplicado** | `allowWalkthroughForCreature()` |

| `floorFading = 0`, migração v4 | Cliente Lua | **Aplicado** | `options.lua` |

| FPS 60, dash, smart walk | Cliente Lua | **Aplicado** | `options.lua` |

| Vulkan / frame pacing | Cliente | **Pendente** | Só GL/DX no OTCv8 |

| Ease-in-out forte (curvas extras) | Cliente | **Parcial** | smoothstep leve |

| Igualar `getStepDuration` ao server beat | Cliente | **Pendente** | `MAP-SMOOTH.md` |

| Testar DX vs GL / vsync | Teste | **Pendente** | Manual |



---



## Como saber se o problema é cliente ou servidor



| Sintoma | Provável camada | Como confirmar |

|--------|-----------------|----------------|

| Câmera/tocha “dá coice” mas o personagem **não volta** de tile | **Cliente** | `127.0.0.1`; sumiu com LERP em `creature.cpp` |

| Personagem **volta** um sqm / borracha | **Servidor** | `sendCancelWalk`, log TFS |

| Travou ao usar item andando | **Servidor** | `actions.cpp` + `timeBetweenActions` |

| **Desconectou** correndo | **Servidor** | `exceeding packet per second limit` |

| Bloqueio em linha reta em player/mob | **Servidor** | Walkthrough só diagonal |

| Personagem **fora do centro** ao bater em mob (reta) | **Cliente** | `preWalk` antes do fix; usar build com `blocksCardinalWalk` |

| Trapado (sem saída): teclado/clique **não move**, câmera **estável** | **Cliente** | **Validado** — comportamento correto pós-fix |

| 1 clique = **2 sqm** | **Cliente** | `game.cpp` — não usar `preWalk` no autowalk 8.60 |



---



## Detalhe dos 3 blocos C++ (pesquisa Zezenia)



### 1. Suavização do offset — **Aplicado** (parcial em Point int)



- `getWalkOffset()`: `progress` linear + **smoothstep** leve.

- `pixelsToWalkOffset(float)`: cálculo float, retorno `Point` com `lround`.

- **Pendente:** `PointF` na draw / frametime dinâmico (ganho em UI scale alto).



### 2. Âncora da câmera — **Aplicado**



- `getCameraPosition()`: `getLastStepFromPosition()` se andando; senão `getPosition()`.

- Mapa: `calcFramebufferSource()` + `getWalkOffset()`.

- Foreground (follow): mesmo anchor ao desenhar criatura seguida.



### 3. Autowalk sem gargalo — **Aplicado** + extensões



- Fim de passo autowalk: não `terminateWalk()`; offset em `spriteSize`.

- **Novo:** `tryVisualWalkStep` — animação sem `m_preWalking` / pacote extra.

- **Novo:** predição do próximo sqm a **85%** do passo (`AUTO_WALK_PREDICT_PROGRESS`) + `setAutoWalkPath`.

- **Novo:** `Creature::walk` encadeia se `oldPos == m_lastStepToPosition`.



---



## Servidor (`otserv_860`)



Ver `otserv_860/docs/SERVER-CHANGES.md`.



| Parâmetro | Valor |

|-----------|-------|

| `maxPacketsPerSecond` | 1000 |

| `timeBetweenActions` / `Ex` | 100 |

| `allowWalkthrough` | true (diagonal + exceções boss/trap) |



---

## Ajuste fino — lag e frame pacing

### Desync / “puxão” em ping alto

| Comportamento | O que acontece |
|---------------|----------------|
| Predição a **85%** do passo | Cliente anima o próximo sqm antes do ACK do servidor |
| Servidor rejeita (mob, campo, lag) | `stopWalk()` / `m_visualPredictedDest` invalida → char **volta** um tile |
| Reclamação de micro-teleporte | Subir `AUTO_WALK_PREDICT_PROGRESS` em `localplayer.cpp` para **0.90f** |

Constante atual: `AUTO_WALK_PREDICT_PROGRESS = 0.85f` (era 0.75 na primeira versão).

### V-Sync e limite de FPS (OTCv8) — revisão técnica

| Config | Onde | Recomendação para deslize do mapa |
|--------|------|-----------------------------------|
| **V-Sync** | Opções → Gráficos → `vsync` → `g_window.setVerticalSync()` | **Desligado** (default do projeto). Ligado prende ao refresh do monitor e pode somar atraso com o limitador de FPS. |
| **Game framerate limit** | `backgroundFrameRate` → `g_app.setMaxFps()` | **60** ou **max** (201). Evite 10–35 só para “teste”; o LERP precisa de frames estáveis. |
| **Frame pacing interno** | `graphicalapplication.cpp` | `frameDelay = 1_000_000 / m_maxFps` + `millisleep(1)` entre frames |
| **V-Sync no Windows** | `win32window.cpp` | Com tear (`WGL_EXT_swap_control_tear`), intervalo **-1** = adaptive; ainda limita apresentação |

**Não há Vulkan** neste fork — apenas OpenGL (`otclient_gl.exe`) e DirectX (`otclient_dx.exe`).

**Combinações que costumam dar melhor resultado:**

1. `vsync = false`, `backgroundFrameRate = 60` (ou max se o PC aguenta 144+ estável).
2. Se houver **tearing** (rasgo horizontal): testar `otclient_dx.exe` ou ligar vsync **sabendo** que o deslize pode ficar menos suave.
3. **Não** usar vsync ON + FPS 60 ao mesmo tempo sem testar — dupla limitação pode gerar “vibrada” no chão.
4. `floorFading = 0`, `optimizationLevel = Automatic` ou Low.

O **smoothstep** em `getWalkOffset()` roda a cada frame de render; se o driver entregar frames irregulares (vsync + cap errado), a curva fica correta mas a **apresentação** treme — isso é pacing de GPU, não bug do LERP.

---

## Teste do sistema completo



1. Recompilar cliente: `.\scripts\build-client.ps1`

2. Reiniciar `tfs.exe` (se não recompilou TFS, usar binário atual na raiz).

3. Abrir `otclient_gl.exe` — perfil atualiza `floorFading=0` (v4).

4. **Teclado:** andar reto/diagonal — mapa desliza; diagonal passa em criaturas; reta bloqueia.

4b. **Trapado / mob na frente (cardinal):** sem movimento (teclado e mapa), personagem **no centro**, sem *Sorry, not possible.* — **validado**.

5. **Autowalk:** clique longo no mapa — deslize contínuo, sem 2 sqm no primeiro passo.

6. **Servidor:** sem kick; console sem packet limit.

7. Opcional: `otclient_dx.exe`, vsync off, FPS 60+.



Debug: `g_extras.debugWalking` — duração/offset no nome do char.



---



## Referências



- `docs/CLIENT-CHANGES.md`

- `docs/MAP-SMOOTH.md`

- `otserv_860/docs/SERVER-CHANGES.md`

- `otserv_860/docs/walkthrough` → `otcv8-dev/docs/walkthrough-mitigacao.md`



---



## Notas Zezenia (referência)



<details>

<summary>Resumo original</summary>



- LERP entre tiles no cliente; input paralelo; cliente leve; lag protection em protocolos novos.

- No 8.60: predição visual local + servidor valida cada passo.

- V-Sync / tearing: testar DX, FPS alto, vsync off.



</details>


A pesquisa nos tópicos do OtLand revela que essa micro-parada a cada SQM (o famoso step stall ou dashing/stuttering bug) é um problema amplamente documentado pela comunidade.Os desenvolvedores seniores do fórum (como Ninja, El Bringy e diath) explicam que a causa raiz é matemática: o cálculo de tempo de passo (stepDuration) que o OTCv8 faz localmente não bate exatamente com o milissegundo calculado pela Source do TFS. Se o cliente calcula que o passo dura 200ms, mas o servidor calcula 250ms, o cliente congela por 50ms a cada tile esperando o aval do servidor. No protocolo antigo (8.60), o jogo é travado em múltiplos rígidos de 50ms, o que acentua o problema.Abaixo estão as três soluções mais eficazes documentadas no OtLand para remover esse gargalo:1. Ajuste na Source (creature.cpp do Servidor) — O Arredondamento RígidoNo TFS, a função que dita a duração do passo trunca o valor usando múltiplos de 50ms. Isso gera uma incompatibilidade com o cálculo dinâmico de floats do OTCv8.Abra o seu src/creature.cpp no servidor, localize a função int64_t Creature::getStepDuration() e veja se ela possui essa estrutura clássica do TFS:cppint64_t Creature::getStepDuration() const {
    // ... cálculo da velocidade ...
    double duration = std::floor(1000 * groundSpeed) / stepSpeed;
    int64_t stepDuration = std::ceil(duration / 50) * 50; // O VILÃO
    return stepDuration;
}
Use o código com cuidado.A Correção Recomendada: Esse arredondamento de * 50 força atrasos artificiais. Para dar a precisão cirúrgica do Zezenia, remova esse arredondamento em bloco e retorne o valor bruto de milissegundos com uma margem de folga para o cliente poder antecipar o input sem sofrer rejeição:cppint64_t Creature::getStepDuration() const {
    if (isRemoved()) { return 0; }
    uint32_t groundSpeed = 150;
    int32_t stepSpeed = getStepSpeed();
    
    Item* ground = tile->getGround();
    if (ground && Item::items[ground->getID()].speed != 0) {
        groundSpeed = Item::items[ground->getID()].speed;
    }

    double duration = (1000.0 * groundSpeed) / stepSpeed;
    
    // Retorna o valor exato em milissegundos sem forçar múltiplos de 50ms.
    // Subtraímos 10-20ms como "network buffer" para sincronizar com o OTCv8 localmente.
    return std::max<int64_t>(100, static_cast<int64_t>(duration) - 15);
}
Use o código com cuidado.2. Ajuste nas Ações (actions.cpp do Servidor) — O Bug do Uso de Itens AndandoSe a sua travadinha a cada SQM piora consideravelmente quando você tenta abrir backpacks ou usar runas/potions em movimento, o desenvolvedor diath (colaborador oficial do OTClient) documentou no GitHub que o TFS força o cancelamento e reinício do passo ao executar ações na mesma thread.A Correção Recomendada: Vá em src/actions.cpp e procure por chamadas de:cppplayer->stopWalk();
Use o código com cuidado.Dentro do escopo de uso de itens normais (Actions::useItem), comente ou remova a linha player->stopWalk();. Isso impede que uma ação de clique na interface quebre a fila de movimentação contínua do jogador.3. Ajuste no Cliente (creature.cpp do OTCv8) — Fator de SincroniaNo lado do cliente, a animação de caminhada tenta se ajustar dinamicamente ao valor de velocidade enviado pelo servidor. Conforme documentado nos tópicos de Dashing e Smooth Walking, definir o multiplicador de passo interno do cliente para um valor fixo e limpo força a sincronia.Abra o arquivo src/client/creature.cpp nas fontes do seu OTCv8:Procure por referências onde o getStepDuration() do cliente multiplica a velocidade por algum fator de escala.Fixe o fator de velocidade da animação em 1 ou remova coeficientes decimais flutuantes que alterem o tempo de renderização do frame em relação ao clock do servidor.