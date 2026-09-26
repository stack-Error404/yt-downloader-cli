# Error404 // Media Console

Downloader interativo para **Linux, Windows e Android/Termux**, criado por **Error404**.

**Página oficial:** <https://stack-error404.github.io/yt-downloader-cli/>

Baixe vídeos e playlists do YouTube em MP4 ou MP3, escolha formatos manualmente e salve vídeos individuais do TikTok. O projeto usa `yt-dlp` e `ffmpeg` como dependências.

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

Os instaladores baixam o programa da tag fixa `v1.1.0` e validam o SHA-256 contra `checksums.sha256`. Isso evita mudanças silenciosas do arquivo instalado e detecta corrupção; não substitui a confiança no repositório ou uma assinatura criptográfica da release.

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

Links normais e links curtos do TikTok são entregues ao extrator do `yt-dlp`. O suporte pode variar quando o TikTok altera o site. Carrosséis, perfis completos, mídia privada e extração dedicada de áudio não fazem parte desta versão.

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
