# Análise de Renderização de Mapa: OTClient vs Godot 4

## 1. Como o OTClient (OTC) renderiza o mapa
Após analisar os arquivos `mapview.cpp` e `tile.cpp` do OTClient em C++, identifiquei a arquitetura central de renderização que garante a alta performance e a ordem correta dos sprites (Z-sorting) no Tibia.

### A. Culling e Cache de Tiles Visíveis (`MapView::updateVisibleTilesCache`)
O OTC **não** itera sobre todos os tiles do mapa a cada frame. Ele recalcula uma lista de tiles visíveis (`m_cachedVisibleTiles`) **apenas** quando a câmera se move ou um tile é atualizado. 
- **Occlusion Culling Dinâmico:** Ele calcula o `FirstVisibleFloor`. Se você está no andar 7 (térreo) e há um telhado totalmente opaco no andar 6 acima de você, ele não renderiza nada acima disso. Da mesma forma, não renderiza andares abaixo do solo se você não puder vê-los.

### B. Renderização por Camadas (Passes)
O erro mais comum ao refazer clientes de Tibia é renderizar "Tile por Tile" (desenhar o chão, a parede e a criatura do Tile A, depois ir para o Tile B). Isso causa bugs onde criaturas ficam "embaixo" de paredes de tiles adjacentes.
O OTC resolve isso renderizando por camadas em **todos** os tiles visíveis sequencialmente:
1. **Passo 1:** `drawGround` (Desenha o chão de todos os tiles)
2. **Passo 2:** `drawBottom` (Desenha paredes e itens de base de todos os tiles)
3. **Passo 3:** `drawCreatures` (Desenha criaturas de todos os tiles)
4. **Passo 4:** `drawTop` (Desenha telhados e efeitos de todos os tiles)

### C. Elevação e Pseudo-3D (`m_drawElevation`)
Tibia não é apenas um grid 2D. Quando itens são empilhados no mesmo tile, eles sofrem um "offset" (deslocamento) no eixo X e Y (geralmente 1 ou 2 pixels para noroeste) dependendo da propriedade `elevation` do Item (ex: caixas, moedas). O `tile.cpp` acumula o `m_drawElevation` conforme itera pelos itens para desenhar as coisas empilhadas.

### D. Correção de Cadáveres (Corpse Correction)
Cadáveres grandes (como Dragões) ultrapassam o limite de 32x32 do tile. O OTC possui a função `calculateCorpseCorrection()`, que identifica cadáveres que "vazam" para os tiles vizinhos (Norte/Oeste) e força os tiles vizinhos a redesenharem seus próprios Top Items e Criaturas para garantir que o jogador não fique "escondido" debaixo da asa de um dragão morto que está no tile de baixo.

### E. Sistema de Luz e Sombras (`LightView`)
A iluminação é feita renderizando luzes em uma textura separada (`m_lightTexture`). Chãos opacos bloqueiam luz, e chãos translúcidos não.

---

## 2. Checklist para o Cliente em Godot 4
Baseado nessa análise, aqui está a lista completa de coisas que precisamos verificar e implementar no Godot para ter um mapa fluido e sem bugs visuais:

### Arquitetura e Performance
- [ ] **Abandonar o TileMap nativo para Y-Sorting de itens dinâmicos (Se usado):** O nó `TileMap` do Godot é ótimo para o chão estático, mas péssimo para lidar com o empilhamento dinâmico do Tibia (chão -> caixas -> criaturas -> efeitos -> telhados). Devemos usar nós customizados (`_draw` no Godot CanvasItem) ou `MultiMeshInstance2D` controlados via script.
- [ ] **Cache de Visibilidade (Tile Culling):** Implementar um array 2D/3D no Godot contendo apenas os dados dos Tiles visíveis (chunking/viewport). Atualizar essa matriz APENAS no sinal de `camera_moved` ou `tile_updated`.
- [ ] **Oclusão de Andares:** Implementar a lógica de não desenhar andares acima (0-6) se o tile do telhado não for "look through" (look_possible == false).

### Lógica de Renderização
- [ ] **Loop Multi-Pass:** O método `_draw()` principal do mapa (ou os CanvasGroups) deve desenhar separadamente:
  - `Layer 0`: Chão (Grounds e Ground Borders)
  - `Layer 1`: Itens de baixo (Bottoms, Paredes)
  - `Layer 2`: Criaturas
  - `Layer 3`: Itens do topo (Tops, Telhados)
- [ ] **Off-set de Elevação:** O sistema precisa ler a elevação (em pixels) do `DatItems` e deslocar a posição de desenho `(-elevation, -elevation)` ao iterar pela pilha (stack) de um tile.
- [ ] **Animação Sincronizada (Walking):** Criaturas andando (`walking_creatures`) devem ter sua posição interpolada (LERP) do tile de origem para o tile de destino subtraindo o offset da elevação, garantindo que subam/desçam rampas suavemente.
- [ ] **Corpse Correction:** Implementar a checagem de bounding boxes (Tamanho do Sprite > 32x32). Se o cadáver vazar para (X-1, Y-1), o jogador que pisar na posição (X-1, Y-1) DEVE ser renderizado por cima (Z-index maior).

### Efeitos e Luz
- [ ] **Shader de Iluminação:** Em Godot, não precisamos desenhar pixels manualmente. Podemos usar o sistema de `PointLight2D` ou, para melhor performance 2D clássica, um `SubViewport` que renderiza luzes com `BlendMode = Add` e então multiplica (Multiply) sobre o Canvas do mapa principal.
- [ ] **Transições de Andar (Floor Fading):** Implementar um `Tween` ou temporizador na opacidade (`modulate.a`) de andares superiores (Z < 7) quando o jogador sobe ou desce escadas, replicando o "FloorFading" do OTC.
