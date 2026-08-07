# Log de sessão (cliente OTCv8)

Módulo `client_sessionlog` — grava o mesmo conteúdo do **Terminal** (Ctrl+T) em arquivo quando o jogador entra e sai do personagem.

## Onde ficam os arquivos

```
<writeDir>/logs/sessions/
```

No Windows, `writeDir` costuma ser algo como:

`C:\Users\<usuario>\AppData\Roaming\OTCv8\`

Cada sessão gera um arquivo:

```
Testerman_2026-05-22_09-45-30.log
```

## Quando salva

| Evento | Ação |
|--------|------|
| Entrar no jogo (`onGameStart`) | Abre buffer da sessão |
| Sair do personagem (`onGameEnd`) | Grava arquivo com motivo `logout` |
| Fechar o cliente | Grava com motivo `client_exit` |

O log geral do cliente (`OTCv8.log` na pasta do exe) continua existindo; este módulo é um **recorte por personagem/sessão** para depurar erros como os do Combat Power.

## Ativar

Já está em `modules/client/client.otmod` → `load-later` → `client_sessionlog`.

Reinicie o `otclient_gl.exe` após atualizar.

## Analisar erros

1. Reproduza o problema (ex.: abrir Combat Power).
2. Deslogue ou feche o cliente.
3. Abra o `.log` mais recente em `logs/sessions/`.
4. Procure por `ERROR:` ou `Lua error`.
