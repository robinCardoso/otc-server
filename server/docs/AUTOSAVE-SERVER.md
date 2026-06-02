# Plano de Implementação: Otimização do Server Save (Evitar Travamentos)

Este plano descreve como o sistema de salvamento do servidor (server save) funciona, identifica a causa dos travamentos (freezes/lag) e propõe uma estratégia para realizar o salvamento de forma assíncrona, eliminando os travamentos na thread principal do jogo.

---

## 1. Funcionamento Atual do Server Save

O fluxo de execução do server save ocorre da seguinte forma:

1. **Agendamento (Lua/GlobalEvents):** 
   - No arquivo [globalevents.xml](file:///c:/8.6/otserv_860/otc-server/server/data/globalevents/globalevents.xml#L67), o evento `AutoSave` é executado a cada 1 hora.
   - Ele chama o script [autosave.lua](file:///c:/8.6/otserv_860/otc-server/server/data/globalevents/scripts/autosave.lua), que executa a função global `saveServer()`.

2. **Chamada de C++ (Game):**
   - A função `saveServer()` está vinculada a [Game::saveGameState()](file:///c:/8.6/otserv_860/otc-server/server/src/game.cpp#L161).
   - `Game::saveGameState()` altera o estado do jogo para `GAME_STATE_MAINTAIN`, congela temporariamente novas ações de jogadores e inicia o salvamento:
     - Itera sobre todos os jogadores online e chama `IOLoginData::savePlayer(player)`.
     - Chama `Map::save()`, que por sua vez chama `IOMapSerialize::saveHouseInfo()` e `IOMapSerialize::saveHouseItems()`.
   - Restaura o estado do jogo para `GAME_STATE_NORMAL`.

3. **Causa dos Travamentos (I/O Síncrono):**
   - Em [iologindata.cpp](file:///c:/8.6/otserv_860/otc-server/server/src/iologindata.cpp#L647) e [iomapserialize.cpp](file:///c:/8.6/otserv_860/otc-server/server/src/iomapserialize.cpp#L67), as consultas SQL (incluindo transações `BEGIN`, `DELETE`, `INSERT`, `UPDATE` e `COMMIT`) são executadas usando `Database::getInstance().executeQuery()` e `storeQuery()`.
   - Estas chamadas executam diretamente na **thread principal do jogo** (main game loop). O jogo inteiramente para de responder enquanto aguarda a resposta do MySQL/SQLite e a escrita física dos dados no disco. Em servidores com muitos jogadores e muitos itens (especialmente depots e estoques), isso gera um congelamento perceptível de 1 a 5 segundos.

---

## 2. Proposta de Melhoria: Salvamento Assíncrono

Para evitar que o servidor trave, as consultas SQL de escrita no banco de dados devem ser transferidas para a thread de tarefas de banco de dados (`g_databaseTasks`). 

> [!NOTE]
> Ler ou modificar os objetos `Player` e `Item` diretamente em uma thread paralela geraria condições de corrida (Race Conditions) e possíveis crashes/clones de itens. 
> Portanto, a melhor estratégia é **serializar os dados para strings SQL na thread principal (o que leva menos de 1ms) e enviar as queries prontas para serem executadas na thread secundária de banco de dados.**

### Etapas da Solução

#### A. Evitar Queries de Leitura Síncrona durante o Save
- Atualmente, `IOLoginData::savePlayer` faz um `SELECT save FROM players WHERE id = ...` para verificar se o personagem deve ser salvo.
- **Melhoria:** Carregar o valor da coluna `save` do banco de dados no momento em que o jogador faz login ([IOLoginData::loadPlayer](file:///c:/8.6/otserv_860/otc-server/server/src/iologindata.cpp#L207)) e armazená-lo como um atributo booleano (ex: `bool saveCharacter`) na classe `Player`. Com isso, eliminamos essa consulta de leitura síncrona no save.

#### B. Serializar Queries em Lote (Batch/Transactions)
- Criar uma nova função ou sobrecarga de `IOLoginData::savePlayer` e `IOMapSerialize::saveHouseItems` que em vez de chamar `db.executeQuery(...)` diretamente, adicione as strings SQL formatadas em um vetor ou lista de strings (`std::vector<std::string>& queries`).
- Toda a lógica de montagem dos `INSERTs` e `UPDATEs` de itens, storage, VIP, e magias continuará rodando na thread principal de forma ultra-rápida (apenas concatenação de strings em memória).

#### C. Enviar o Lote de Queries para `g_databaseTasks`
- Uma vez geradas todas as consultas em memória na thread principal, nós criamos uma tarefa assíncrona enviando esse lote de queries para a thread de banco de dados.
- O executador de tarefas assíncronas abrirá uma transação (`BEGIN`), executará todas as queries daquele jogador/mapa sequencialmente em background, e fará o `COMMIT`.
- Desta forma, o main game thread é liberado instantaneamente e o processamento de rede e ticks do jogo continua sem qualquer lag para os jogadores.

---

## 3. Arquivos a Serem Modificados

### [Component: Server Core & Database]

#### [MODIFY] [player.h](file:///c:/8.6/otserv_860/otc-server/server/src/player.h)
- Adicionar o membro `bool saveCharacter = true;` à classe `Player`.
- Adicionar getters/setters `bool shouldSave() const` e `void setShouldSave(bool save)`.

#### [MODIFY] [iologindata.h](file:///c:/8.6/otserv_860/otc-server/server/src/iologindata.h) e [iologindata.cpp](file:///c:/8.6/otserv_860/otc-server/server/src/iologindata.cpp)
- Alterar `IOLoginData::loadPlayer` para incluir a coluna `save` na query `SELECT` e preencher `player->saveCharacter`.
- Criar métodos que acumulam as queries em um vetor em vez de executá-las imediatamente:
  - `static bool playerToQueries(Player* player, std::vector<std::string>& queries);`
  - `static bool saveItemsToQueries(const Player* player, const ItemBlockList& itemList, const std::string& tableName, std::vector<std::string>& queries);`

#### [MODIFY] [iomapserialize.h](file:///c:/8.6/otserv_860/otc-server/server/src/iomapserialize.h) e [iomapserialize.cpp](file:///c:/8.6/otserv_860/otc-server/server/src/iomapserialize.cpp)
- Criar métodos para exportar as queries de casas e itens de casas para o vetor:
  - `static bool saveHouseInfoToQueries(std::vector<std::string>& queries);`
  - `static bool saveHouseItemsToQueries(std::vector<std::string>& queries);`

#### [MODIFY] [game.cpp](file:///c:/8.6/otserv_860/otc-server/server/src/game.cpp)
- Adaptar `Game::saveGameState()` para:
  1. Gerar o vetor `queries` contendo as queries de todos os players online e das casas.
  2. Submeter o lote de queries como uma única transação assíncrona para `g_databaseTasks`.
  3. Evitar travar o loop de tick do servidor.

---

## 4. Plano de Verificação

### Testes Manuais
1. Iniciar o servidor localmente com vários jogadores conectados.
2. Usar o comando `/save` no jogo ou aguardar o autosave de 1 hora.
3. Verificar o console para logs de sucesso do save.
4. Confirmar no banco de dados se os itens do inventário, storage, e itens das casas foram salvos corretamente.
5. Monitorar o ping/resposta do cliente durante o save para certificar-se de que não há perda de pacotes ou congelamento de tela (freeze).
