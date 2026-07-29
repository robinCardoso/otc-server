---
name: godot-game-architecture
description: Padrões de design de software, arquitetura de pastas e gerenciamento de ciclo de vida (Game Loop) para projetos estruturados e escaláveis na Godot Engine 4.7+.
---

# SKILL: Arquitetura de Jogos na Godot Engine 4.7+

Esta skill define os padrões e diretrizes para a estruturação técnica de projetos de jogos escaláveis na Godot Engine (versão 4.7+), focando em desacoplamento de componentes, gerenciamento de estado e organização de diretórios.

---

## 1. Princípios de Design na Godot Engine

A Godot utiliza um modelo mental único baseado em **Cenas (Scenes) e Nós (Nodes)**. Para manter o código modular, siga as diretrizes abaixo:

* **Orientação a Recursos (Feature-Based Layout):** Agrupe todos os arquivos relacionados a uma funcionalidade na mesma pasta. Scripts (`.gd`), Cenas (`.tscn`), Recursos Customizados (`.tres`) e Texturas locais devem residir no mesmo diretório de recurso (Ex: `src/ui/login/`).
* **Regra de Ouro da Godot ("Signals Up, Call Down"):**
  * **Chamar para baixo (Call Down):** Um nó pai pode referenciar diretamente seus filhos e invocar suas funções (ex: `$VBox/ItemList.select()`).
  * **Sinalizar para cima (Signals Up):** Um nó filho **nunca** deve acessar propriedades do nó pai diretamente. Em vez disso, ele deve emitir sinais (`signal`) que o pai conecta e trata. Isso mantém os filhos independentes e testáveis isoladamente.
* **Recursos vs Nós:** Use `Resource` para dados estáticos, configurações, ou dados puros que não precisam de representação 2D/3D no ciclo do frame (ex: dados de um item, estatísticas de uma magia). Isso economiza memória e processamento do Game Loop.

---

## 2. Estrutura de Diretórios Recomendada

Organize o projeto dividindo-o entre dados estáticos (`assets/`) e código lógico/cenas (`src/`):

```text
res://
├── assets/                     # Arquivos de mídia crus (sem lógica de script)
│   ├── client/                 # Dados legados ou pacotes binários
│   ├── fonts/                  # Fontes de texto (.ttf, .otf, .woff2)
│   ├── textures/               # Folhas de sprites, backgrounds, ícones
│   └── audio/                  # Sons e trilhas sonoras (.ogg, .wav, .mp3)
│
└── src/                        # Código fonte estruturado
    ├── autoload/               # Singletons globais de controle
    ├── core/                   # Motores de infraestrutura (Rede, Cripto)
    ├── io/                     # Decodificadores e leitores de dados binários
    ├── ui/                     # Telas, menus e interfaces de usuário (HUD)
    └── game/                   # Simulação do mundo e entidades de gameplay
```

---

## 3. Gerenciamento de Estado Global (Autoloads/Singletons)

Use **Autoloads** com moderação apenas para sistemas que exigem persistência ao mudar de cenas ou gerenciar conexões constantes:

* **GlobalNetwork:** Responsável por reter a conexão socket TCP activa com o servidor de jogo e gerenciar timeouts.
* **GameState:** Centraliza o estado lógico global (Ex: dados do personagem local, lista de salas, flags globais).
* **AudioManager:** Centraliza o controle de canais de reprodução de áudio, fade-in/out de músicas e controle de volumes configurados pelo jogador.

**Importante:** Nunca instancie lógica de gameplay local ou interações temporárias de tela dentro de Singletons, para evitar vazamentos de memória e acoplamento.

---

## 4. Convenções de Nomenclatura e Estilo

Siga o guia de estilo padrão da Godot para GDScript:

* **Pastas e Arquivos:** `snake_case` (ex: `network_manager.gd`, `login_screen.tscn`).
* **Nomes de Classes:** `PascalCase` usando `class_name` (ex: `class_name TibiaProtocol`).
* **Variáveis e Funções:** `snake_case` (ex: `var player_name: String`, `func start_network()`).
* **Constantes:** `UPPER_SNAKE_CASE` (ex: `const MAX_CONNECTIONS = 10`).
* **Sinais:** Terminar em verbos no passado indicando o ocorrido (ex: `signal connection_failed`, `signal packet_received(data)`).
* **Variáveis Privadas/Internas:** Prefixe com um caractere underscore (ex: `var _internal_socket: StreamPeerTCP`).
