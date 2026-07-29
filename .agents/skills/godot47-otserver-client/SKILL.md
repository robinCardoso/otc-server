---
name: godot47-otserver-client
description: Guia de desenvolvimento e padrões de código para criação de um cliente próprio de Tibia/OTServer na Godot Engine versão 4.7+.
---

# SKILL: Desenvolvimento de Cliente OTServer na Godot 4.7+

Esta skill orienta o desenvolvimento do cliente próprio de OTServer na versão **Godot 4.7+** (usando GDScript), mapeando a leitura binária dos formatos clássicos (`.spr`, `.dat`, `.otbm`) e a comunicação de rede segura.

---

## 1. Leitura e Decodificação do `Tibia.spr` (Sprites)

O arquivo `.spr` armazena todas as imagens de tamanho $32 \times 32$ pixels com compressão **RLE (Run-Length Encoding)**.

### Estrutura do Cabeçalho
- **Assinatura (4 bytes / U32):** Assinatura numérica do cliente (ex: `1277298068` para a assinatura `0x4C212D94` no 8.60).
- **Contagem de Sprites (4 bytes / U32):** Mapeado como U32 em versões estendidas/OTClient (onde ultrapassa 65.535 sprites, ex: 174.013 sprites).
- **Offset Inicial:** Começa exatamente em **8 bytes** (`sprites_offset = 8`).

### Estrutura do Índice
A partir do offset `8`, cada sprite tem um endereço de 32 bits (U32) indicando onde seus dados começam no arquivo:
- `index_offset = 8 + (sprite_id - 1) * 4`

### Estrutura dos Dados da Sprite
Ao pular para o endereço lido do índice:
1. Pular **3 bytes** de cor chave (geralmente Magenta `255, 0, 255` usado para transparências antigas).
2. Ler **2 bytes (U16)**: Tamanho dos dados de pixel compactados (`pixel_data_size`).
3. Descomprimir o RLE:
   - Loop lê blocos de 4 bytes: `transparent_pixels (U16)` e `colored_pixels (U16)`.
   - Avança o cursor de escrita pelo número de pixels transparentes.
   - Lê `3 bytes` (RGB) para cada pixel colorido, gravando na imagem local do Godot.

---

## 2. Leitura e Decodificação do `Tibia.dat` (Metadados dos Itens)

O arquivo `.dat` (Data) contém a definição de todas as propriedades físicas de cada objeto, item, criatura ou efeito visual no jogo, bem como quais IDs de sprites compõem o gráfico deles.

### Estrutura do Cabeçalho
- **Assinatura (4 bytes / U32):** Deve coincidir exatamente com a assinatura do `.spr`.
- **Contagem de Itens / Categorias (2 bytes / U16 por categoria):**
  - Item/Ground/Objects ID: Geralmente o ID 100 é o primeiro item válido.
  - O arquivo especifica a quantidade para cada categoria de `ThingType`:
    1. **Items** (Grounds, Paredes, Itens coletáveis)
    2. **Creatures** (Outfits dos jogadores, monstros)
    3. **Effects** (Efeitos de magia, explosões)
    4. **Missiles** (Efeitos de distância, runas/flechas)

### Estrutura de Propriedades (Flags)
Ao ler um item do `.dat`, lê-se uma lista sequencial de flags (bytes de 8 bits) até encontrar o byte terminador `0xFF`:
- `0x00`: Ground (Chão transitável, possui velocidade de movimentação associada - 2 bytes adicionais).
- `0x01`: Top (Sempre renderizado acima de outras coisas da mesma camada).
- `0x02`: Top2 (Itens como arcos de portas, cortinas que ficam bem acima).
- `0x03`: Container (Itens que abrem como mochilas).
- `0x04`: Stackable (Pode ser empilhado, ex: gold coins).
- `0x08`: Useable (Pode dar "Use" ou abrir).
- `0x0A`: Block Walk (Itens sólidos que trancam a passagem de criaturas).
- `0x0B`: Block Projectile (Bloqueia flechas, magias e visão).
- `0x0C`: Block Pathfind (Ignorado por monstros no cálculo de caminho).
- `0x0F`: Has Light (Emite iluminação - cor e intensidade de 2 bytes adicionais).
- `0x11`: Has Offset (Deslocamento na tela - coordenadas X e Y adicionais).
- `0x12`: Has Elevation (Elevação de altura Z - usado em escadas e rampas).
- `0x19`: Minimap (Mostra cor específica no minimap).
- `0xFF`: Fim das flags de propriedades.

### Estrutura de Sprites Associadas
Após ler o byte de término `0xFF`, lê-se a estrutura das sprites:
- **Tamanho do Item:** Quantidade de largura, altura e profundidade em blocos de $32\times32$ pixels.
- **Animação:** Quantidade de fases de animação (frames) e velocidade.
- **Lista de IDs de Sprites (U16 ou U32):** Array contendo os IDs sequenciais que devem ser carregados do `Tibia.spr` para renderizar o objeto final.

---

## 3. Protocolos de Rede e Handshake

O fluxo de rede do Tibia divide-se entre o **Login Server** (porta cur### 3.1. Handshake do Login Server (Porta 7171)
1. **Estrutura Geral de Pacotes de Rede (TFS 8.60+):**
   Todos os pacotes enviados e recebidos a partir da versão 8.40 utilizam uma estrutura com checksum Adler32:
   - `Tamanho do Pacote` (2 bytes / U16): Contém o tamanho total subsequente (`4 bytes do checksum + tamanho do payload`).
   - `Checksum Adler32` (4 bytes / U32): Calculado sobre o payload bruto (Adler32 padrão, inicializado com `a=1, b=0`, modulo `65521`).
   - `Payload` (Tamanho variável): O conteúdo real do pacote.
   
2. **Login Request Packet (Cliente -> Servidor):**
   - O payload do request de login inicia com:
     - `Opcode` (1 byte): `0x01` (ClientEnterAccount).
     - `OS` (2 bytes): Código do sistema operacional (ex: `2` para Windows).
     - `Versão` (2 bytes): Versão do protocolo (ex: `860` para 8.60).
     - `DatSignature` (4 bytes): Assinatura lida do cabeçalho do `Tibia.dat`.
     - `SprSignature` (4 bytes): Assinatura lida do cabeçalho do `Tibia.spr`.
     - `PicSignature` (4 bytes): Assinatura clássica `1455799783` (0x56C5DDE7).
   - **Bloco RSA Criptografado (128 bytes):**
     - O bloco original possui: `0x00` (1 byte) + `XTEA Key` (16 bytes / 4 inteiros U32 gerados aleatoriamente pelo cliente) + `AccountName` (String c/ prefixo U16) + `Password` (String c/ prefixo U16) + `Padding de zeros` até completar 128 bytes.
     - Este bloco de 128 bytes **deve ser encriptado via Textbook RSA** ($C = M^{65537} \pmod N$) utilizando o Modulus público correspondente ao par de chaves do arquivo `key.pem` do servidor.
     - **Regra de Aritmética do RSA em GDScript:** Para chaves de 1024-bits (32 limbs de 32-bits), os carry-overs de shifts de bits (`_bigint_shl_1`) e somas intermediárias (`_bigint_add`) não podem ser descartados; caso gerem carry, a redução modular correspondente (`_bigint_sub`) deve ser executada imediatamente.

3. **Decodificação do Login Response (Servidor -> Cliente):**
   - O pacote bruto recebido tem a estrutura: `[2 bytes: tamanho][4 bytes: checksum Adler32][payload encriptado XTEA...]`.
   - **IMPORTANTE:** Os 4 bytes do checksum Adler32 devem ser removidos e lidos antes de passar o payload restante para a descriptografia XTEA.
   - O payload descriptografado XTEA inicia com `2 bytes` contendo o tamanho do conteúdo decodificado interno.
   - `Opcodes` de resposta do Login Server:
     - **`0x0A` (LoginServerError):** Seguido por uma String (prefixo U16) contendo o motivo do erro.
     - **`0x14` (LoginServerMotd):** O servidor envia a mensagem do dia (MOTD). Seguido por uma string contendo o MOTD. O mesmo pacote tipicamente continua com o próximo opcode (`0x64`) imediatamente após a string do MOTD.
     - **`0x64` (LoginServerCharacterList):**
       - Contagem de Personagens (1 byte).
       - Loop para cada personagem: `Nome` (String) -> `Mundo` (String) -> `World IP` (4 bytes / U32 em formato de rede, lido e convertido byte a byte) -> `World Port` (2 bytes / U16).
       - Dias Premium (2 bytes / U16).
4. **Fechamento imediato:** Após enviar a resposta, o servidor de login desconecta o socket TCP.

### 3.2. Conexão com o Game Server (Porta 7172)
1. **Estabelecer Conexão:** Ao selecionar um personagem da lista, o cliente se conecta ao IP e porta indicados pela resposta do login (geralmente porta `7172`).
2. **First Game Packet (Cliente -> Servidor):**
   - O primeiro pacote de jogo **não utiliza RSA**, mas sim a criptografia **XTEA** direta da sessão.
   - Contém o `Opcode` `0x0A` (GameServerLoginOrPendingState), a conta, o nome do personagem selecionado e a chave de sessão.
3. **Opcode do Game Server (GameServerOpcodes):**
   - **`100` (GameServerFullMap):** Descreve a visão completa do mapa de andares próximos a posição inicial do jogador.
   - **`109` (GameServerMoveCreature):** Move uma criatura pela grade do cenário.
   - **`170` (GameServerTalk):** Exibe mensagens no Chat e acima das criaturas.

---

## 4. Diretrizes de Código na Godot 4.7+
- Sempre envie e espere pacotes com checksum Adler32 nos primeiros 4 bytes do payload.
- Lembre-se de descartar os 4 bytes do Adler32 do cabeçalho da resposta antes de descriptografar com XTEA.
- Sempre interprete strings da rede lendo o prefixo de 16 bits (U16) em vez da função nativa `get_string` da Godot (que lê em 32 bits).
- Mantenha os scripts de criptografia `Rsa.gd` e `Xtea.gd` otimizados. O RSA bit-a-bit deve conter apenas loops `for` de tamanho constante para evitar travamentos ou detecções de loop infinito pela engine.
- **Validação de Entrada de Login (Regra de E-mail):** O servidor de jogo C++ (TFS) autentica os jogadores estritamente com base no `Account Name` (nome ou número de conta salvo na coluna `name` da tabela `accounts` no banco de dados). O e-mail (que contém o caractere `@`) **não é aceito** pelo protocolo do jogo, mesmo que o site permita login com e-mail. Para evitar regressões e confusão do usuário, a interface de login deve validar o texto inserido no campo de conta e emitir um aviso visual claro de que o caractere `@` não é permitido para acessar o jogo.

