# Proposta de Arquitetura de Pastas: Godot Client OTServer

Para que o projeto cresça de forma escalável, organizada e profissional, o design deve seguir uma **Arquitetura Baseada em Recursos (Feature-Based)** associada a **Camadas de Responsabilidade** (Rede, UI, Game Loop, Parsers). 

Na Godot, é uma boa prática agrupar scripts (`.gd`) e cenas (`.tscn`) na mesma pasta de sua funcionalidade para facilitar o encapsulamento e reaproveitamento.

---

## 📂 Estrutura de Pastas Proposta

Abaixo está a árvore de diretórios sugerida para o crescimento sustentável do projeto:

```text
godot-client/
├── assets/                       # Recursos estáticos do jogo
│   ├── client/                   # Arquivos originais do Tibia (dat, spr, pic)
│   ├── fonts/                    # Fontes personalizadas (Inter, Outfit, etc)
│   ├── sfx/                      # Efeitos sonoros (passos, hits, magias)
│   ├── music/                    # Músicas de fundo
│   └── textures/                 # UI Icons, backgrounds e imagens customizadas
│
├── src/                          # Todo o código fonte e cenas do jogo
│   ├── autoload/                 # Scripts globais (Singletons do Godot)
│   │   ├── GlobalNetwork.gd      # Conexão persistente (Game Server)
│   │   ├── GameState.gd          # Estado atual do jogador e mundo
│   │   └── AudioManager.gd       # Sistema global de som
│   │
│   ├── core/                     # Lógica fundamental de rede e criptografia
│   │   ├── cryptography/         # Criptografia do protocolo
│   │   │   ├── Rsa.gd
│   │   │   └── Xtea.gd
│   │   └── network/              # Gerenciador de conexões TCP e pacotes
│   │       ├── NetworkManager.gd
│   │       └── Protocol.gd
│   │
│   ├── io/                       # Parsers de arquivos binários do cliente
│   │   ├── DatReader.gd          # Leitor do Tibia.dat
│   │   ├── SpriteReader.gd       # Leitor de Tibia.spr
│   │   └── OtbmReader.gd         # Futuro leitor do mapa .otbm do servidor
│   │
│   ├── ui/                       # Telas e Elementos de Interface do Usuário (HUD)
│   │   ├── components/           # Componentes genéricos reutilizáveis
│   │   │   ├── CustomButton.tscn
│   │   │   └── ModalDialog.tscn
│   │   ├── login/                # Painel de Login e validações
│   │   │   ├── LoginScreen.tscn
│   │   │   └── LoginScreen.gd
│   │   ├── char_list/            # Seleção de personagens
│   │   │   ├── CharListDialog.tscn
│   │   │   └── CharListDialog.gd
│   │   └── game_hud/             # Interface ativa do jogo (Inventário, Chat, HP)
│   │       ├── GameHUD.tscn
│   │       ├── GameHUD.gd
│   │       ├── InventorySlot.tscn
│   │       └── ChatBox.gd
│   │
│   └── game/                     # Lógica ativa da simulação do jogo
│       ├── map/                  # Renderização e lógica da grade do mapa
│       │   ├── TileMap.gd        # Gerenciamento de andares (Z-axis 0..15)
│       │   └── Tile.gd           # Comportamento de cada quadrado
│       ├── creatures/            # Entidades móveis (Players, NPCs, Monstros)
│       │   ├── Creature.gd       # Classe base de criaturas
│       │   ├── Player.gd         # Lógica específica do jogador local
│       │   └── CreatureOutfit.gd # Montagem do outfit usando as sprites
│       └── effects/              # Efeitos visuais e de projéteis na tela
│           ├── Effect.gd
│           └── Missile.gd
│
├── project.godot                 # Configurações globais do projeto Godot
└── README.md                     # Documentação de introdução
```

---

## 🛠️ Explicação das Camadas e Padrões de Design

### 1. `src/autoload/` (Singletons)
A Godot permite registrar scripts de execução em background.
* **`GameState.gd`** guardará o status da sessão (Ex: *Conectado ao Login Server*, *No Mundo de Jogo*, *Personagem Selecionado*).
* **`GlobalNetwork.gd`** manterá o socket TCP ativo transitando entre mapas e telas.

### 2. `src/core/cryptography/` & `src/core/network/`
Isola completamente a matemática e a segurança do jogo. Nenhuma tela de UI deve gerenciar Sockets diretamente; elas apenas chamam métodos do `Protocol.gd` e escutam os sinais emitidos por ele (como `login_failed` ou `character_list_received`).

### 3. `src/io/` (Input/Output)
Classes utilitárias focadas em traduzir bytes brutos das mídias locais em formatos que a Godot entende (ex: criar `ImageTexture` a partir do RLE do `.spr`, ou dicionários a partir do `.dat`).

### 4. `src/ui/` vs `src/game/`
Isso divide **Interface Gráfica** (HUD 2D estática, botões, barras de vida) de **Simulação do Mundo** (personagem andando no grid, monstros atacando, magias voando). Evita o acoplamento de código visual com lógica de gameplay.

---

## 🚀 Como fazer a transição no projeto atual

Podemos estruturar as pastas aos poucos para não quebrar referências da Godot:
1. Criar o diretório `src/core/network/` e mover `NetworkManager.gd` e `Protocol.gd` para lá.
2. Criar `src/core/cryptography/` e mover `Rsa.gd` e `Xtea.gd`.
3. Criar `src/io/` e mover `DatReader.gd` e `SpriteReader.gd`.
4. Criar `src/ui/login/` e mover `main.gd` e `main.tscn` (que hoje agem como o controlador da tela de login).
