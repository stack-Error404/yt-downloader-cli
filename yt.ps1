param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$ErrorActionPreference = 'Stop'
$Version = '1.1.3'
$ProjectUrl = 'https://github.com/stack-Error404/yt-downloader-cli'
$DownloadDir = if ($env:YT_DOWNLOAD_DIR) { $env:YT_DOWNLOAD_DIR } else { Join-Path (Join-Path $HOME 'Downloads') 'YouTube' }
$CookiesFromBrowser = ''

function Show-Usage {
    @"
Error404 // Media Console v$Version

Uso: yt [opções]

Opções:
  -h, --help                 Mostra esta ajuda
  -v, --version              Mostra a versão
  -d, --download-dir PASTA   Usa outra pasta nesta execução
  --cookies-from-browser B   Lê cookies do navegador B (ex.: firefox)

Sem opções, abre o menu interativo.
"@
}

for ($i = 0; $i -lt $CliArgs.Count; $i++) {
    switch ($CliArgs[$i]) {
        { $_ -in '-h', '--help' } { Show-Usage; exit 0 }
        { $_ -in '-v', '--version' } { "yt $Version"; exit 0 }
        { $_ -in '-d', '--download-dir' } {
            if ($i + 1 -ge $CliArgs.Count -or [string]::IsNullOrWhiteSpace($CliArgs[$i + 1]) -or $CliArgs[$i + 1].StartsWith('-')) {
                [Console]::Error.WriteLine("Erro: $($CliArgs[$i]) exige uma pasta.")
                exit 2
            }
            $i++
            $DownloadDir = $CliArgs[$i]
        }
        { $_ -like '--download-dir=*' } {
            $DownloadDir = $_.Substring('--download-dir='.Length)
            if ([string]::IsNullOrWhiteSpace($DownloadDir) -or $DownloadDir.StartsWith('-')) {
                [Console]::Error.WriteLine('Erro: --download-dir exige uma pasta válida.')
                exit 2
            }
        }
        '--cookies-from-browser' {
            if ($i + 1 -ge $CliArgs.Count -or [string]::IsNullOrWhiteSpace($CliArgs[$i + 1]) -or $CliArgs[$i + 1].StartsWith('-')) {
                [Console]::Error.WriteLine('Erro: --cookies-from-browser exige um navegador.')
                exit 2
            }
            $i++
            $CookiesFromBrowser = $CliArgs[$i]
        }
        { $_ -like '--cookies-from-browser=*' } {
            $CookiesFromBrowser = $_.Substring('--cookies-from-browser='.Length)
            if ([string]::IsNullOrWhiteSpace($CookiesFromBrowser) -or $CookiesFromBrowser.StartsWith('-')) {
                [Console]::Error.WriteLine('Erro: --cookies-from-browser exige um navegador válido.')
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

function Get-PlatformLabel([string]$Url) {
    if ($Url -notmatch '^[a-z][a-z0-9+.-]*://') { $Url = "https://$Url" }
    try { $urlHost = ([Uri]$Url).Host.ToLowerInvariant() } catch { return 'yt-dlp (detecção automática)' }
    switch ($urlHost) {
        { $_ -in 'youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be' } { return 'YouTube' }
        { $_ -in 'tiktok.com', 'www.tiktok.com', 'vm.tiktok.com' } { return 'TikTok' }
        { $_ -in 'instagram.com', 'www.instagram.com' } { return 'Instagram' }
        { $_ -in 'facebook.com', 'www.facebook.com', 'm.facebook.com', 'fb.watch', 'www.facebook.watch' } { return 'Facebook' }
        { $_ -in 'twitter.com', 'www.twitter.com', 'x.com', 'www.x.com' } { return 'X/Twitter' }
    }
    return 'yt-dlp (detecção automática)'
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
        Write-Host 'Se o site exigir login ou o conteúdo for privado, escolha a opção 10 no menu para usar os cookies do navegador.' -ForegroundColor Cyan
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

function Configure-BrowserCookies {
    Clear-Menu
    Write-Host 'Usar cookies do navegador' -ForegroundColor Red
    Write-Host "`nUse esta opção se o site pedir login ou indicar que o conteúdo é privado."
    Write-Host 'Feche o navegador escolhido antes de continuar.'
    $choice = Read-Host "`n[1] Firefox  [2] Chrome  [3] Edge  [4] Brave  [0] Cancelar`nEscolha"
    $browser = switch ($choice) {
        '1' { 'firefox' }
        '2' { 'chrome' }
        '3' { 'edge' }
        '4' { 'brave' }
        '0' { return }
        '' { return }
        default { Write-Host 'Opção inválida.' -ForegroundColor Red; Pause-Menu; return }
    }
    $script:CookiesFromBrowser = $browser
    Write-Host "`nCookies configurados para: $browser"
    Write-Host 'Os próximos downloads desta sessão usarão essa conta.'
    Pause-Menu
}

function Start-Download([string]$Mode, [bool]$Playlist) {
    Clear-Menu
    Write-Host $Mode -ForegroundColor Red
    if (-not (Read-Url)) { Pause-Menu; return }
    $platform = Get-PlatformLabel $script:Url
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
    if ($CookiesFromBrowser) { $arguments += @('--cookies-from-browser', $CookiesFromBrowser) }
    Write-Host "`n$platform — iniciando...`n"
    & yt-dlp @arguments '--' $script:Url
    Complete-Download $LASTEXITCODE
}

function Start-TikTokDownload {
    Clear-Menu
    Write-Host 'TikTok (vídeo individual)' -ForegroundColor Red
    if (-not (Read-Url)) { Pause-Menu; return }
    $arguments = @(
        '--ignore-config', '--no-playlist', '--embed-metadata',
        '-f', 'bv*+ba/b', '--merge-output-format', 'mp4', '--remux-video', 'mp4',
        '-o', "$OutputDir/TikTok/%(uploader,channel|TikTok)s - %(title)s [%(id)s].%(ext)s"
    )
    if ($CookiesFromBrowser) { $arguments += @('--cookies-from-browser', $CookiesFromBrowser) }
    & yt-dlp @arguments '--' $script:Url
    Complete-Download $LASTEXITCODE
}

function Select-Quality {
    Clear-Menu
    Write-Host 'Escolher qualidade (vídeo individual MP4)' -ForegroundColor Red
    if (-not (Read-Url)) { Pause-Menu; return }
    $formatArguments = @('--ignore-config', '--no-playlist')
    if ($CookiesFromBrowser) { $formatArguments += @('--cookies-from-browser', $CookiesFromBrowser) }
    $formatArguments += @('-F', '--', $script:Url)
    & yt-dlp @formatArguments
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
    if ($CookiesFromBrowser) { $arguments += @('--cookies-from-browser', $CookiesFromBrowser) }
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
    Write-Host "ERROR404 // MEDIA CONSOLE v$Version" -ForegroundColor Red
    Write-Host "`nCriado por Error404"
    Write-Host "Projeto: $ProjectUrl"
    Write-Host 'YouTube, TikTok e outras plataformas reconhecidas pelo yt-dlp.'
    Write-Host "Downloads: $DownloadDir"
    Write-Host 'Use apenas conteúdo que você tem direito de baixar.'
    Pause-Menu
}

# ---------------------------------------------------------------------------
# Interface do menu (visual ERROR-404): moldura, banner, barra de seleção.
# Precisa de terminal com cores 24 bits (Windows Terminal, PowerShell 7 ou
# Windows 10+); caso contrário, o menu numerado simples é usado (também com
# NO_COLOR=1, sem console interativo ou YT_MENU=simple).
# ---------------------------------------------------------------------------
$Esc = [string][char]27
$FReset = "${Esc}[0m${Esc}[48;2;0;0;0m"
$FBold = "${Esc}[1m"
$CBorder = "${Esc}[38;2;29;74;36m"
$CLine = "${Esc}[38;2;58;74;64m"
$CDivider = "${Esc}[38;2;76;32;38m"
$CDim = "${Esc}[38;2;132;148;137m"
$CRed = "${Esc}[38;2;255;45;70m"
$CPink = "${Esc}[38;2;255;51;85m"
$CGreen = "${Esc}[38;2;93;255;56m"
$CCyan = "${Esc}[38;2;94;231;255m"
$CWhite = "${Esc}[38;2;228;238;229m"
$CSelected = "${Esc}[48;2;93;255;56m${Esc}[38;2;0;0;0m"

$MenuLabels = @(
    'Vídeo MP4', 'Áudio MP3', 'Playlist MP4', 'Playlist MP3', 'Escolher qualidade',
    'TikTok', 'Abrir pasta de downloads', 'Atualizar dependências', 'Sobre',
    'Usar cookies do navegador', 'Sair'
)
$MenuCodes = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 0)

# Smiley em 14 colunas x 11 linhas de pontos Braille (gerado por tools/gen-banner.py).
# Cada célula tem 3 dígitos hexadecimais: máscara Braille (2) e intensidade do vermelho (1).
$SmileyRows = @(
    '000 000 000 36a f6a ffa f6a e4a c49 408 000 000 000 000'
    '000 000 000 000 c0b c4d 000 099 19b 3ba a6c 40d 000 000'
    '000 808 f4b 1ec 0ba 097 000 000 000 000 000 39b c6c 000'
    '80b 7ec 019 000 c08 409 000 80a e4c e4b 409 000 39a 46c'
    'feb 078 000 bea 1ba 0bb 000 08a 017 b9a 03b 000 000 ff9'
    'b9a c79 000 b8a 80a 000 000 000 80a f8a 000 000 a0c 07c'
    '000 3bc e6b 788 b89 1fc 76b 3fa 0bc 017 80b f4a 0fb 000'
    '000 000 08b 3bb f6a e4b e7b e4b 34b 7eb 0bc 000 000 000'
    '000 000 000 000 189 000 000 000 000 47a 000 000 000 000'
    '000 000 000 000 000 000 000 000 000 479 000 000 000 000'
    '000 000 000 000 000 000 000 000 000 078 000 000 000 000'
)
$Art404 = @(
    '██  ██  ████  ██  ██',
    '██  ██ ██  ██ ██  ██',
    '██████ ██  ██ ██████',
    '    ██ ██  ██     ██',
    '    ██  ████      ██'
)
$script:SmileyLines = $null

function Get-VisibleLength([string]$Text) {
    return ($Text -replace "$([char]27)\[[0-9;]*m", '').Length
}

function Format-Pad([string]$Text, [int]$Width) {
    $missing = $Width - (Get-VisibleLength $Text)
    if ($missing -gt 0) { return $Text + (' ' * $missing) }
    return $Text
}

function Format-Center([string]$Text, [int]$Width) {
    $left = [int][Math]::Floor(($Width - (Get-VisibleLength $Text)) / 2)
    if ($left -lt 0) { $left = 0 }
    return (' ' * $left) + $Text
}

# Converte o smiley em linhas ANSI: um caractere Braille por célula, cor pela intensidade.
function Get-SmileyLines {
    if ($script:SmileyLines) { return $script:SmileyLines }
    $levelFg = foreach ($level in 0..15) {
        $green = [int][Math]::Floor($level * $level * 40 / 225)
        $blue = [int][Math]::Floor($level * $level * 62 / 225)
        "${Esc}[38;2;$([int]($level * 255 / 15));$green;$($blue)m"
    }
    $result = foreach ($row in $SmileyRows) {
        $line = New-Object System.Text.StringBuilder
        foreach ($cell in $row.Split(' ')) {
            $mask = [Convert]::ToInt32($cell.Substring(0, 2), 16)
            if ($mask -eq 0) {
                [void]$line.Append(' ')
            } else {
                $level = [Convert]::ToInt32($cell.Substring(2, 1), 16)
                [void]$line.Append($levelFg[$level]).Append([char](0x2800 + $mask))
            }
        }
        $line.ToString() + $FReset
    }
    $script:SmileyLines = @($result)
    return $script:SmileyLines
}

# Monta as linhas do quadro para um terminal $Cols x $Rows com o item $Selected marcado.
# Devolve $null quando a janela é pequena demais para a moldura.
function New-Frame([int]$Selected, [int]$Cols, [int]$Rows) {
    $w = [Math]::Min(76, $Cols - 2)
    if ($w -lt 44) { return $null }
    $header = 0
    if ($w -ge 66 -and $Rows -ge 34) { $header = 11 }
    elseif ($w -ge 66 -and $Rows -ge 29) { $header = 6 }
    if ($Rows -lt 23 + $header) { return $null }

    $pad = ' ' * [int][Math]::Floor(($Cols - $w - 2) / 2)
    $lines = New-Object 'System.Collections.Generic.List[string]'
    $line = { param([string]$Inner) $lines.Add($pad + $CBorder + '│' + $FReset + (Format-Pad $Inner $w) + $CBorder + '│' + $FReset) }

    $lines.Add($pad + $CBorder + '┌' + ('─' * $w) + '┐' + $FReset)
    $dots = " ${CRed}●${FReset} ${CGreen}●${FReset} ${CGreen}●${FReset}"
    & $line ((Format-Pad $dots ($w - 14)) + "${CDim}/dev/tty — yt ${FReset}")

    if ($header -eq 11) {
        $smiley = Get-SmileyLines
        for ($i = 0; $i -lt 11; $i++) {
            $right = switch ($i) {
                { $_ -ge 1 -and $_ -le 5 } { "   ${CPink}${FBold}$($Art404[$_ - 1])${FReset}" }
                7 { "   ${CWhite}${FBold}ERROR-404${FReset}" }
                8 { "   ${CDim}O sinal foi perdido no caminho.${FReset}" }
                9 { "   ${CDim}Console online.${FReset}" }
                default { '' }
            }
            & $line ((Format-Pad ((' ' * 8) + $smiley[$i]) 30) + "${CDivider}│${FReset}" + $right)
        }
    } elseif ($header -eq 6) {
        for ($i = 0; $i -lt 6; $i++) {
            $right = switch ($i) {
                2 { "   ${CWhite}${FBold}ERROR-404${FReset}" }
                3 { "   ${CDim}O sinal foi perdido no caminho.${FReset}" }
                4 { "   ${CDim}Console online.${FReset}" }
                default { '' }
            }
            $left = ''
            if ($i -ge 1) { $left = "   ${CPink}${FBold}$($Art404[$i - 1])${FReset}" }
            & $line ((Format-Pad $left 26) + "${CDivider}│${FReset}" + $right)
        }
    }

    & $line ''
    & $line (Format-Center "${CRed}${FBold}ERROR404 // MEDIA CONSOLE${FReset}" $w)
    & $line (Format-Center "${CRed}[ v${Version} ]${FReset}" $w)
    $rule = '  ' + $CLine + ('─' * ($w - 4)) + $FReset
    & $line $rule
    & $line "  ${CCyan}status: online // select an option${FReset}"
    & $line ''
    for ($i = 0; $i -lt $MenuCodes.Count; $i++) {
        $num = '{0:00}' -f $MenuCodes[$i]
        if ($i -eq $Selected) {
            & $line ('  ' + $CSelected + (Format-Pad " $num  $($MenuLabels[$i])" ($w - 4)) + $FReset)
        } else {
            & $line "   ${CRed}${num}${CGreen}  $($MenuLabels[$i])${FReset}"
        }
    }
    & $line ''
    & $line $rule
    $short = $DownloadDir
    if ($HOME -and $short.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) { $short = '~' + $short.Substring($HOME.Length) }
    $max = $w - 4 - 11 - 3
    if ($short.Length -gt $max) { $short = '…' + $short.Substring($short.Length - ($max - 1)) }
    & $line "  ${CDim}downloads: ${short}_ ${Esc}[5m${CWhite}█${FReset}"
    $lines.Add($pad + $CBorder + '└' + ('─' * $w) + '┘' + $FReset)
    return $lines.ToArray()
}

function Write-Frame([string[]]$Lines, [bool]$Clear) {
    $out = New-Object System.Text.StringBuilder
    [void]$out.Append($FReset).Append("${Esc}[H")
    if ($Clear) { [void]$out.Append("${Esc}[2J") }
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        [void]$out.Append($Lines[$i]).Append("${Esc}[K")
        if ($i -lt $Lines.Count - 1) { [void]$out.Append("`r`n") }
    }
    [void]$out.Append("${Esc}[J")
    [Console]::Out.Write($out.ToString())
}

function Enable-VirtualTerminal {
    try {
        Add-Type -Namespace Yt -Name Native -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int handle);
[DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr handle, out int mode);
[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr handle, int mode);
'@
        $handle = [Yt.Native]::GetStdHandle(-11)
        $mode = 0
        if (-not [Yt.Native]::GetConsoleMode($handle, [ref]$mode)) { return $false }
        return [Yt.Native]::SetConsoleMode($handle, ($mode -bor 4))
    } catch {
        return $false
    }
}

function Initialize-Ui {
    if ($env:NO_COLOR -or $env:YT_MENU -eq 'simple') { return $false }
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { return $false }
    try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
    if ($PSVersionTable.PSEdition -eq 'Desktop' -and -not $env:WT_SESSION) {
        if (-not (Enable-VirtualTerminal)) { return $false }
    }
    return $true
}

# Menu com setas, j/k, Home/End, Enter e digitação do número (ex.: 1, 01, 10).
# Devolve o código clássico da opção, ou $null se a janela não comporta o visual.
function Show-InteractiveMenu {
    $selected = 0
    $count = $MenuCodes.Count
    $numBuf = ''
    $dirty = $true
    $clear = $true
    $size = ''
    [Console]::Out.Write("${Esc}[?25l")
    try {
        while ($true) {
            if ($dirty) {
                $size = "$([Console]::WindowWidth)x$([Console]::WindowHeight)"
                $frame = New-Frame $selected ([Console]::WindowWidth) ([Console]::WindowHeight)
                if (-not $frame) { return $null }
                Write-Frame $frame $clear
                $dirty = $false
                $clear = $false
            }
            while (-not [Console]::KeyAvailable) {
                Start-Sleep -Milliseconds 50
                if ("$([Console]::WindowWidth)x$([Console]::WindowHeight)" -ne $size) { $dirty = $true; $clear = $true; break }
            }
            if ($dirty) { continue }

            $key = [Console]::ReadKey($true)
            $char = [string]$key.KeyChar
            if ($char -notmatch '^[0-9]$') { $numBuf = '' }
            switch ($key.Key) {
                'UpArrow' { $selected = ($selected + $count - 1) % $count; $dirty = $true }
                'DownArrow' { $selected = ($selected + 1) % $count; $dirty = $true }
                'Home' { $selected = 0; $dirty = $true }
                'End' { $selected = $count - 1; $dirty = $true }
                'Enter' { return $MenuCodes[$selected] }
            }
            switch -Regex ($char) {
                '^[kK]$' { $selected = ($selected + $count - 1) % $count; $dirty = $true }
                '^[jJ]$' { $selected = ($selected + 1) % $count; $dirty = $true }
                '^[qQ]$' { return 0 }
                '^[0-9]$' {
                    $numBuf += $char
                    if ($numBuf.Length -gt 2) { $numBuf = $char }
                    for ($attempt = 0; $attempt -lt 2; $attempt++) {
                        $match = [Array]::IndexOf($MenuCodes, [int]$numBuf)
                        if ($match -ge 0) { $selected = $match; $dirty = $true; break }
                        $numBuf = $char
                    }
                }
            }
        }
    } finally {
        [Console]::Out.Write("${Esc}[0m${Esc}[?25h")
    }
}

function Show-SimpleMenu {
    Clear-Menu
    Write-Host "ERROR404 // MEDIA CONSOLE  [ v$Version ]" -ForegroundColor Red
    Write-Host "`nstatus: online // select an option`n" -ForegroundColor Cyan
    for ($i = 0; $i -lt $MenuCodes.Count; $i++) {
        Write-Host ('{0:00}' -f $MenuCodes[$i]) -ForegroundColor Red -NoNewline
        Write-Host "  $($MenuLabels[$i])" -ForegroundColor Green
    }
    Write-Host "`nDownloads: $DownloadDir`n"
}

function Invoke-MenuChoice([string]$Choice) {
    if ($Choice -match '^0\d$') { $Choice = $Choice.Substring(1) }
    switch ($Choice) {
        '1' { Start-Download 'MP4' $false }
        '2' { Start-Download 'MP3' $false }
        '3' { Start-Download 'MP4' $true }
        '4' { Start-Download 'MP3' $true }
        '5' { Select-Quality }
        '6' { Start-TikTokDownload }
        '7' { Open-DownloadFolder }
        '8' { Update-Dependencies }
        '9' { Show-About }
        '10' { Configure-BrowserCookies }
        '0' { exit 0 }
        default { Write-Host 'Opção inválida.' -ForegroundColor Red; Pause-Menu }
    }
}

# Prévia de um quadro (usada em testes e para conferir o visual): $env:YT_PREVIEW = '100x40'
if ($env:YT_PREVIEW) {
    $previewCols = 100
    $previewRows = 40
    if ($env:YT_PREVIEW -match '^(\d+)x(\d+)$') { $previewCols = [int]$Matches[1]; $previewRows = [int]$Matches[2] }
    $previewSelected = 0
    if ($env:YT_PREVIEW_SEL) { $previewSelected = [int]$env:YT_PREVIEW_SEL }
    try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
    $previewFrame = New-Frame $previewSelected $previewCols $previewRows
    if (-not $previewFrame) {
        [Console]::Error.WriteLine('Janela pequena demais para a prévia.')
        exit 1
    }
    [Console]::Out.Write((($previewFrame -join "`n") + "`n"))
    exit 0
}

Assert-Dependencies
$UseUi = Initialize-Ui
while ($true) {
    $choice = $null
    if ($UseUi) {
        $code = Show-InteractiveMenu
        if ($null -ne $code) { $choice = [string]$code }
    }
    if ($null -eq $choice) {
        Show-SimpleMenu
        $choice = Read-Host 'Escolha'
    }
    Invoke-MenuChoice $choice
}
