# Error404 // Media Console

Downloader em terminal para **CachyOS e Arch Linux**, criado por **Error404**.

Baixe vídeos individuais ou playlists em MP4 e extraia áudio em MP3. O menu também permite escolher o formato manualmente, abrir a pasta de downloads e voltar ao menu após cada operação.

## Instalação rápida

```bash
curl -fsSL https://raw.githubusercontent.com/stack-Error404/yt-downloader-cli/main/install.sh | bash
```

O instalador verifica `yt-dlp` e `ffmpeg`, instala as dependências ausentes com `pacman`, copia o comando para `~/.local/bin/yt` e abre o menu. Confira o código antes de executar qualquer instalador remoto.

Em um **novo terminal**, execute:

```bash
yt
```

## Instalação a partir de um clone

```bash
git clone https://github.com/stack-Error404/yt-downloader-cli.git
cd yt-downloader-cli
bash install.sh
```

Para executar sem instalar, instale as dependências e rode `bash yt` dentro da pasta clonada.

## Recursos

| Opção | Ação |
| --- | --- |
| 1 | Baixar vídeo em MP4 |
| 2 | Extrair áudio em MP3 |
| 3 | Baixar playlist em MP4 |
| 4 | Baixar playlist em MP3 |
| 5 | Escolher formato de vídeo e áudio |
| 6 | Abrir a pasta de downloads |
| 7 | Atualizar `yt-dlp` e `ffmpeg` pelo `pacman` |
| 8 | Ver informações do projeto |

Os arquivos vão para `~/Downloads/YouTube`. Playlists ficam em subpastas. Para escolher outra pasta em uma execução:

```bash
YT_DOWNLOAD_DIR="$HOME/Videos/YouTube" yt
```

O menu usa fundo preto e texto vermelho e verde neon em terminais com suporte a True Color. Para desativar as cores, execute `NO_COLOR=1 yt`.

## Atualização

Para atualizar o programa, execute novamente o comando de **Instalação rápida**. A opção 7 do menu atualiza somente `yt-dlp` e `ffmpeg`.

## Notas

- A conversão para MP4 pode demorar quando os formatos disponíveis usam outros codecs.
- A disponibilidade de formatos depende do vídeo. Alguns conteúdos exigem autenticação ou têm restrições.
- Baixe apenas conteúdos cujo download você esteja autorizado a fazer.

## Licença

MIT. Veja o arquivo `LICENSE` deste repositório.
