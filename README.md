# Error404 // Media Console

Downloader para **CachyOS / Arch Linux**, criado por **Error404**. Versão 1.0.0.

Menu no terminal com fundo preto e texto em verde e vermelho neon (RGB real), vídeo ou playlist em MP4, áudio MP3, escolha manual de formato, abertura da pasta e retorno ao menu após cada download. Salva por padrão em `~/Downloads/YouTube`. As cores dependem do suporte do terminal a True Color; `NO_COLOR=1 yt` desativa as cores.

## Instalar pelo GitHub (após publicar o repositório)

```bash
curl -fsSL https://raw.githubusercontent.com/stack-Error404/yt-downloader-cli/main/install.sh | bash
```

O instalador baixa `yt`, instala as dependências necessárias e abre o menu. Confira os arquivos e o endereço antes de executar um instalador remoto.

## Instalar pela pasta do projeto

Copie esta pasta para `/home/calunga/Projetos/yt-downloader-cli`. No terminal:

```bash
cd ~/Projetos/yt-downloader-cli
bash install.sh
```

O instalador usa `pacman` para instalar `yt-dlp` e `ffmpeg` se faltarem, instala `yt` em `~/.local/bin` e abre o menu. Para usar depois, abra um **novo terminal** e digite `yt`. Para rodar sem instalar: `sudo pacman -S --needed yt-dlp ffmpeg` e `bash yt`.

## Publicar no GitHub

Crie o repositório público **`yt-downloader-cli`** na conta **`stack-Error404`** e envie os arquivos **`yt`**, **`install.sh`** e **`README.md`** para a **raiz** da branch `main`. Endereço esperado: <https://github.com/stack-Error404/yt-downloader-cli>.

O comando remoto acima só funcionará **depois que esses arquivos estiverem publicados** nesse endereço. Caso escolha outro nome de repositório ou branch, atualize os endereços em `README.md`, `install.sh` e `yt` antes de publicar.

## Personalizar e atualizar

Use `YT_DOWNLOAD_DIR="$HOME/Videos/YouTube" yt` para mudar a pasta numa execução. A opção 7 atualiza as dependências pelos repositórios do sistema. Para atualizar **o script**, copie os arquivos novos para esta pasta e execute `bash install.sh` novamente, ou repita o comando remoto depois de publicar a nova versão.

O MP4 pode exigir conversão por `ffmpeg` quando o vídeo disponível usa outro codec; isso demora mais e pode aumentar o uso de CPU. A disponibilidade dos formatos depende do vídeo. Alguns vídeos podem exigir autenticação ou ter restrições de download. Use conteúdo cujo download você esteja autorizado a fazer.
