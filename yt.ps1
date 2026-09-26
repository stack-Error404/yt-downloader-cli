param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$ErrorActionPreference = 'Stop'
$Version = '1.1.0'
$ProjectUrl = 'https://github.com/stack-Error404/yt-downloader-cli'
$DownloadDir = if ($env:YT_DOWNLOAD_DIR) { $env:YT_DOWNLOAD_DIR } else { Join-Path $HOME 'Downloads\YouTube' }

function Show-Usage {
    @"
Error404 // Media Console v$Version

Uso: yt [opções]

Opções:
  -h, --help                 Mostra esta ajuda
  -v, --version              Mostra a versão
  -d, --download-dir PASTA   Usa outra pasta nesta execução

Sem opções, abre o menu interativo.
"@
}

for ($i = 0; $i -lt $CliArgs.Count; $i++) {
    switch ($CliArgs[$i]) {
        { $_ -in '-h', '--help' } { Show-Usage; exit 0 }
        { $_ -in '-v', '--version' } { "yt $Version"; exit 0 }
        { $_ -in '-d', '--download-dir' } {
            if ($i + 1 -ge $CliArgs.Count -or [string]::IsNullOrWhiteSpace($CliArgs[$i + 1])) {
                [Console]::Error.WriteLine("Erro: $($CliArgs[$i]) exige uma pasta.")
                exit 2
            }
            $i++
            $DownloadDir = $CliArgs[$i]
        }
        { $_ -like '--download-dir=*' } {
            $DownloadDir = $_.Substring('--download-dir='.Length)
            if ([string]::IsNullOrWhiteSpace($DownloadDir)) {
                [Console]::Error.WriteLine('Erro: --download-dir exige uma pasta.')
                exit 2
            }
        }
        default {
            [Console]::Error.WriteLine("Erro: argumento desconhecido: $($CliArgs[$i])")
            [Console]::Error.WriteLine((Show-Usage))
            exit 2
        }
    }
}

$OutputDir = $DownloadDir.Replace('%', '%%')
$script:Url = ''

function Assert-Dependencies {
    $missing = @()
    if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) { $missing += 'yt-dlp' }
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) { $missing += 'ffmpeg' }
    if ($missing.Count) {
        throw "Dependências ausentes: $($missing -join ', '). Execute novamente install.ps1 ou use winget."
    }
    New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null
}

function Clear-Menu {
    if (-not $env:NO_COLOR) { Clear-Host }
}

function Read-Url {
    $script:Url = Read-Host 'Cole o link'
    if ([string]::IsNullOrWhiteSpace($script:Url)) {
        Write-Host 'Link vazio.' -ForegroundColor Red
        return $false
    }
    return $true
}

function Pause-Menu {
    [void](Read-Host 'Pressione ENTER para voltar ao menu')
}

function Open-DownloadFolder {
    Start-Process explorer.exe -ArgumentList $DownloadDir
}

function Complete-Download([int]$Status) {
    if ($Status -eq 0) {
        Write-Host "`nDownload concluído. Arquivos em: $DownloadDir" -ForegroundColor Green
    } else {
        Write-Host "`nO download não foi concluído (código $Status)." -ForegroundColor Red
    }
    while ($true) {
        $choice = Read-Host "`n[1] Abrir pasta  [2] Voltar ao menu  [0] Sair"
        switch ($choice) {
            '1' { Open-DownloadFolder }
            { $_ -in '2', '' } { return }
            '0' { exit 0 }
            default { Write-Host 'Opção inválida.' -ForegroundColor Red }
        }
    }
}

function Start-Download([string]$Mode, [bool]$Playlist) {
    Clear-Menu
    Write-Host $Mode -ForegroundColor Green
    if (-not (Read-Url)) { Pause-Menu; return }
    $arguments = @('--ignore-config', '--embed-metadata')
    if ($Playlist) {
        $arguments += @('--yes-playlist', '-o', "$OutputDir/%(playlist_title,playlist_id|Playlist)s/%(playlist_index|0)02d - %(title)s [%(id)s].%(ext)s")
    } else {
        $arguments += @('--no-playlist', '-o', "$OutputDir/%(title)s [%(id)s].%(ext)s")
    }
    if ($Mode -eq 'MP3') {
        $arguments += @('-x', '--audio-format', 'mp3', '--audio-quality', '0', '--embed-thumbnail')
    } else {
        $arguments += @('-f', 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b', '--merge-output-format', 'mp4', '--remux-video', 'mp4')
    }
    & yt-dlp @arguments '--' $script:Url
    Complete-Download $LASTEXITCODE
}

function Start-TikTokDownload {
    Clear-Menu
    Write-Host 'TikTok (vídeo individual)' -ForegroundColor Green
    if (-not (Read-Url)) { Pause-Menu; return }
    $arguments = @(
        '--ignore-config', '--no-playlist', '--embed-metadata',
        '-f', 'bv*+ba/b', '--merge-output-format', 'mp4', '--remux-video', 'mp4',
        '-o', "$OutputDir/TikTok/%(uploader,channel|TikTok)s - %(title)s [%(id)s].%(ext)s"
    )
    & yt-dlp @arguments '--' $script:Url
    Complete-Download $LASTEXITCODE
}

function Select-Quality {
    Clear-Menu
    Write-Host 'Escolher qualidade (vídeo individual MP4)' -ForegroundColor Green
    if (-not (Read-Url)) { Pause-Menu; return }
    & yt-dlp '--ignore-config' '--no-playlist' '-F' '--' $script:Url
    if ($LASTEXITCODE -ne 0) { Write-Host 'Falha ao buscar formatos.' -ForegroundColor Red; Pause-Menu; return }
    $video = Read-Host 'Código do formato de vídeo'
    if ($video -notmatch '^[A-Za-z0-9_.-]+$') { Write-Host 'Código de vídeo inválido.' -ForegroundColor Red; Pause-Menu; return }
    $audio = Read-Host 'Código do formato de áudio (ENTER = automático)'
    if ($audio -and $audio -notmatch '^[A-Za-z0-9_.-]+$') { Write-Host 'Código de áudio inválido.' -ForegroundColor Red; Pause-Menu; return }
    $selector = if ($audio) { "$video+$audio" } else { "$video+bestaudio/$video" }
    $arguments = @(
        '--ignore-config', '--no-playlist', '-f', $selector,
        '--merge-output-format', 'mp4', '--remux-video', 'mp4', '--embed-metadata',
        '-o', "$OutputDir/%(title)s [%(id)s].%(ext)s"
    )
    & yt-dlp @arguments '--' $script:Url
    Complete-Download $LASTEXITCODE
}

function Update-Dependencies {
    Clear-Menu
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host 'winget não está disponível. Atualize yt-dlp e ffmpeg manualmente.' -ForegroundColor Red
        Pause-Menu
        return
    }
    winget upgrade --id yt-dlp.yt-dlp --exact --accept-package-agreements --accept-source-agreements
    winget upgrade --id Gyan.FFmpeg --exact --accept-package-agreements --accept-source-agreements
    Pause-Menu
}

function Show-About {
    Clear-Menu
    Write-Host "ERROR404 // MEDIA CONSOLE v$Version" -ForegroundColor Green
    Write-Host "`nCriado por Error404"
    Write-Host "Projeto: $ProjectUrl"
    Write-Host 'YouTube e TikTok em MP4 ou MP3 no Linux, Android/Termux e Windows.'
    Write-Host "Downloads: $DownloadDir"
    Write-Host 'Use apenas conteúdo que você tem direito de baixar.'
    Pause-Menu
}

Assert-Dependencies
while ($true) {
    Clear-Menu
    Write-Host @"
ERROR404 // MEDIA CONSOLE  [ v$Version ]

1  Vídeo MP4
2  Áudio MP3
3  Playlist MP4
4  Playlist MP3
5  Escolher qualidade
6  TikTok
7  Abrir pasta de downloads
8  Atualizar yt-dlp e ffmpeg
9  Sobre
0  Sair
"@ -ForegroundColor Green
    Write-Host "Downloads: $DownloadDir`n"
    $choice = Read-Host 'Escolha'
    switch ($choice) {
        '1' { Start-Download 'MP4' $false }
        '2' { Start-Download 'MP3' $false }
        '3' { Start-Download 'MP4' $true }
        '4' { Start-Download 'MP3' $true }
        '5' { Select-Quality }
        '6' { Start-TikTokDownload }
        '7' { Open-DownloadFolder }
        '8' { Update-Dependencies }
        '9' { Show-About }
        '0' { exit 0 }
        default { Write-Host 'Opção inválida.' -ForegroundColor Red; Pause-Menu }
    }
}
