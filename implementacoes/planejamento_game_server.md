# Planejamento: Conexão ao Game Server e Renderização do Mapa

Este documento serve como mapa de desenvolvimento para a próxima fase do cliente Godot: estabelecer a conexão persistente com o servidor de jogo (porta 7172) e renderizar a visão inicial do mundo ao redor do jogador.

---

## 📅 Roadmap de Implementação

```
[Fase 1: Conexão TCP 7172] ➔ [Fase 2: Protocolo Game & XTEA] ➔ [Fase 3: Parser do Mapa] ➔ [Fase 4: Renderizador 2D]
```

---

## 🛠️ Detalhamento Técnico das Fases

### Fase 1: Conexão TCP (Game Server)
* **Objetivo:** Abrir conexão persistente na porta 7172 após a seleção do personagem na interface.
* **Ações:**
  1. Fechar a conexão do Login Server (porta 7171).
  2. Iniciar conexão TCP no IP e Porta recebidos na lista de personagens.
  3. Emitir sinal indicando que a conexão com o Game Server está pronta para o handshake.

### Fase 2: Protocolo Game & Envio do Handshake
* **Objetivo:** Enviar o primeiro pacote de entrada (Client Login Game Packet) encriptado com XTEA.
* **Estrutura do Pacote de Entrada (Game Handshake):**
  * `Opcode` (1 byte): `0x0A` (ou `14` em alguns servidores clássicos) indicando entrada no jogo.
  * `Chave XTEA` (16 bytes / U32[4]): Enviamos a mesma chave XTEA gerada no login para que o servidor continue encriptando o tráfego do jogo com ela.
  * `Nome do Personagem` (String U16).
  * `Conta` (String U16).
  * `Senha` (String U16).
* **Leitura dos Opcodes de Resposta:**
  * O servidor aceitará a conexão e passará a mandar pacotes contendo opcodes de jogo:
    * `0x0A` (10) - Login bem-sucedido / Configuração de luz e temperatura local.
    * `0x64` (100) - Descrição completa do mapa inicial (a janela de visualização do jogador).

### Fase 3: Parser de Mapa do Tibia (Opcode 100)
* **Objetivo:** Traduzir os dados binários do pacote de mapa para uma estrutura de dados de tiles.
* **Especificação do Mapa no Protocolo Tibia:**
  * O servidor envia uma janela de visualização correspondente a **18 colunas (X)**, **14 linhas (Y)** e **andares próximos (Z)**.
  * O mapa é lido de forma tridimensional. Para cada Tile, o pacote envia informações sequenciais dos itens ali presentes (chão, paredes, objetos decorativos e criaturas) até encontrar o byte terminador de Tile.
  * Se o Tile estiver vazio, o pacote pula para o próximo.

### Fase 4: Renderizador de Mapa na Godot
* **Objetivo:** Exibir os tiles, paredes, criaturas e o jogador na tela do jogo usando leitores de `.spr` e `.dat`.
* **Ações:**
  1. Desenhar a camada do chão (Grounds) usando os IDs gráficos associados no `Tibia.dat`.
  2. Desenhar objetos estáticos (Paredes, Portas).
  3. Desenhar a criatura do próprio jogador no centro da tela (`9, 7` da grade).
  4. Implementar movimentação básica do jogador enviando pacotes de direção (Norte/Sul/Leste/Oeste) e atualizando a câmera.

---

## 📂 Organização dos Arquivos a Serem Criados

Seguindo a nossa Skill de Arquitetura da Godot Engine:

* 📄 `res://src/autoload/GlobalNetwork.gd` (Singleton para manter a conexão persistente ativa nas trocas de cena).
* 📄 `res://src/game/map/TileMap.gd` (Controlador da grade tridimensional de tiles do jogo).
* 📄 `res://src/game/creatures/Creature.gd` (Objeto visual que representa o jogador e monstros no mapa).
* 📄 `res://src/ui/game_hud/GameHUD.tscn` (A interface de jogo contendo chat, barra de vida, e inventário).
