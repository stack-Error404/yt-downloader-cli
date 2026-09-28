# Error404 // Media Console

Downloader interativo para **Linux, Windows e Android/Termux**, criado por **Error404**.

**Página oficial:** <https://stack-error404.github.io/yt-downloader-cli/>

Baixe vídeos e playlists do YouTube em MP4 ou MP3, escolha formatos manualmente e salve vídeos individuais do TikTok, Instagram, Facebook e X/Twitter. O projeto usa `yt-dlp` e `ffmpeg` como dependências.

## Plataformas

| Plataforma | Suporte | Instalador |
| --- | --- | --- |
| CachyOS / Arch Linux | Completo | `install.sh` + `pacman` |
| Outras distribuições Linux | CLI completo; dependências manuais | `install.sh` |
| Windows 10/11 | Completo em PowerShell | `install.ps1` + `winget` |
| Android | Completo no Termux | `install.sh` + `pkg` |
| iPhone/iPad | Não disponível | Exigiria um serviço remoto separado |

Não há servidor web de downloads: todo processamento acontece no próprio dispositivo. A página oficial é somente a apresentação do projeto.

## Instalação no Linux

Confira o instalador antes de executar código remoto. Em CachyOS ou Arch Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/stack-Error404/yt-downloader-cli/main/install.sh | bash
```

O instalador adiciona `~/.local/bin` ao PATH de Bash, Zsh ou Fish. Em outro shell, ele mostra o caminho que deve ser configurado manualmente. Abra um novo terminal e execute:

```bash
yt
```

Em distribuições sem `pacman`, instale `yt-dlp` e `ffmpeg` pelo gerenciador do sistema antes de executar o instalador.

## Instalação no Windows

Abra o PowerShell sem privilégios de administrador e execute:

```powershell
irm https://raw.githubusercontent.com/stack-Error404/yt-downloader-cli/main/install.ps1 | iex
```

O instalador usa os pacotes oficiais do catálogo WinGet `yt-dlp.yt-dlp` e `Gyan.FFmpeg`, instala o programa em `%LOCALAPPDATA%\Programs\Error404MediaConsole` e adiciona o comando `yt` ao PATH do usuário. Abra um novo PowerShell ou Prompt de Comando e execute `yt`.

Se a política da máquina bloquear scripts, baixe o repositório, confira `install.ps1` e execute:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## Instalação no Android com Termux

Use o Termux distribuído pelo F-Droid ou GitHub. Para permitir downloads na pasta compartilhada do aparelho:

```bash
termux-setup-storage
```

Depois instale:

```bash
pkg update
pkg install curl
curl -fsSL https://raw.githubusercontent.com/stack-Error404/yt-downloader-cli/main/install.sh | bash
```

O instalador usa `python-yt-dlp` e `ffmpeg` dos repositórios do Termux. Quando `~/storage/downloads` existe, os arquivos são salvos em `~/storage/downloads/Error404`.

## Instalação a partir de um clone

Linux ou Termux:

```bash
git clone https://github.com/stack-Error404/yt-downloader-cli.git
cd yt-downloader-cli
bash install.sh
```

Windows:

```powershell
git clone https://github.com/stack-Error404/yt-downloader-cli.git
cd yt-downloader-cli
.\install.ps1
```

Os instaladores baixam o programa da tag fixa `v1.2.0` e validam o SHA-256 contra `checksums.sha256`. Isso evita mudanças silenciosas do arquivo instalado e detecta corrupção; não substitui a confiança no repositório ou uma assinatura criptográfica da release.

## Atualização pelo próprio programa

O menu tem a opção **11 — Verificar atualização do yt**, que consulta as tags de versão do repositório no GitHub (a mesma fonte usada pelos instaladores) e mostra a versão instalada e a mais recente disponível antes de pedir confirmação explícita. Nada é baixado ou executado sem essa confirmação.

Ao confirmar, o programa baixa o script da tag escolhida, valida o SHA-256 contra `checksums.sha256` daquela tag e checa a sintaxe antes de substituir o arquivo instalado (o mesmo fluxo de verificação do instalador). Depois disso o programa se encerra para garantir que a versão antiga, já carregada na memória do processo atual, não continue em uso — é necessário executar `yt` novamente para usar a versão nova.

Toda atualização confirmada grava a versão mínima aceita em um arquivo local (`~/.local/share/error404-media-console/min-version` no Linux/Termux, `%LOCALAPPDATA%\Error404MediaConsole\min-version.txt` no Windows). Qualquer cópia do script mais antiga que essa versão mínima se recusa a rodar, mesmo que tenha sido instalada por outro caminho ou fique parada em outra pasta — isso impede que uma versão revogada continue em uso após a atualização. Essa checagem é local e não depende de rede, então uma falha temporária de internet nunca bloqueia o uso da versão atual; ela só impede rodar uma versão já substituída por uma atualização que o usuário confirmou.

Se o GitHub estiver inacessível no momento da verificação, o programa avisa e mantém a versão atual funcionando normalmente — não há bloqueio nem tentativa de instalar algo sem confirmação.

## O menu

O menu usa o visual do console ERROR-404: moldura, banner com o smiley em pontos Braille, o "404" em blocos e uma barra verde na opção selecionada. Funciona igual no Linux, no Termux e no Windows.

| Tecla | Ação |
| --- | --- |
| `↑` `↓` (ou `k` `j`) | Move a seleção |
| `Home` / `End` | Vai para a primeira / última opção |
| `1`, `01`, `10`… | Seleciona a opção pelo número; confirme com `Enter` |
| `Enter` | Executa a opção selecionada |
| `q` | Sai |

O tamanho do banner acompanha a janela: com 34 linhas ou mais aparece o smiley completo, com 29 a 33 linhas o banner compacto e, abaixo disso, só o menu. Se a janela for pequena demais, o terminal não tiver cores 24 bits/UTF-8 ou a entrada não for interativa, o programa usa o menu numerado simples, em que se digita o número e `Enter`. Para forçá-lo:

```bash
YT_MENU=simple yt
```

`NO_COLOR=1` também desativa o visual. Para conferir o quadro sem abrir o menu: `YT_PREVIEW=100x40 yt` (no PowerShell, `$env:YT_PREVIEW = '100x40'`). A arte do smiley foi gerada por `tools/gen-banner.py` a partir de `docs/assets/error404-red-john-dots.png`.

## Recursos

| Opção | Ação |
| --- | --- |
| 1 | Baixar vídeo em MP4 |
| 2 | Extrair áudio em MP3 |
| 3 | Baixar playlist em MP4 |
| 4 | Baixar playlist em MP3 |
| 5 | Escolher formato de vídeo e áudio |
| 6 | Baixar vídeo individual do TikTok |
| 7 | Abrir a pasta de downloads |
| 8 | Atualizar somente `yt-dlp` e `ffmpeg` |
| 9 | Ver informações do projeto |
| 10 | Usar cookies do navegador |
| 11 | Verificar atualização do yt |
| 0 | Sair |

Links de YouTube, TikTok, Instagram, Facebook e X/Twitter são identificados automaticamente para exibição no fluxo de download. A aceitação não depende de uma lista fixa: qualquer URL que o `yt-dlp` reconheça segue pelo caminho genérico, inclusive plataformas adicionadas futuramente ao `yt-dlp`. O suporte pode variar quando cada site altera sua estrutura.

Para conteúdo que exige login, passe o navegador cujo perfil contém os cookies:

Também é possível selecionar isso pelo menu, na opção **10 — Usar cookies do navegador**. Escolha Firefox, Chrome, Edge ou Brave; o programa explica quando essa opção é útil, por exemplo após um erro de login ou ao acessar conteúdo privado.

```bash
yt --cookies-from-browser firefox
yt --cookies-from-browser 'chrome:Default'
```

No PowerShell, use a mesma opção:

```powershell
yt --cookies-from-browser firefox
```

Isso é especialmente útil para Instagram, Facebook e X. O `yt-dlp` acessa o perfil local do navegador; mantenha o navegador fechado quando ele exigir acesso ao banco de cookies. Conteúdo privado ainda depende das permissões da conta e das limitações do extrator.

## Opções de linha de comando

```text
yt --help
yt --version
yt --download-dir PASTA
```

Também é possível definir a pasta por variável de ambiente:

Linux/Termux:

```bash
YT_DOWNLOAD_DIR="$HOME/Videos/YouTube" yt
```

PowerShell:

```powershell
$env:YT_DOWNLOAD_DIR = "$HOME\Videos\YouTube"
yt
```

As opções `--cookies-from-browser BROWSER[:PROFILE]` e `--download-dir` podem ser combinadas.

O programa rejeita argumentos desconhecidos em vez de ignorá-los silenciosamente.

## Formatos e desempenho

Para MP4, o programa prefere vídeo MP4 e áudio M4A. Quando necessário, o `ffmpeg` remuxa o contêiner sem recodificar o vídeo, evitando perda de qualidade e trabalho desnecessário. A disponibilidade dos formatos depende do site e do conteúdo.

## Atualização

Execute novamente o instalador da sua plataforma para atualizar o programa. A opção 8 do menu atualiza somente `yt-dlp` e `ffmpeg`; ela não dispara uma atualização completa do sistema.

## Desenvolvimento e testes

No Linux:

```bash
bash tests/test.sh
shellcheck yt install.sh tests/test.sh
```

No Windows:

```powershell
.\tests\test-windows.ps1
```

O GitHub Actions executa testes Bash no Ubuntu e valida a sintaxe e os argumentos PowerShell no Windows.

## Uso responsável

Baixe apenas conteúdo que você tem autorização para salvar. Alguns conteúdos exigem autenticação, possuem restrições regionais ou não permitem download.

## Licença

[MIT](LICENSE).
