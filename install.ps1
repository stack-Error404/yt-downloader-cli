param(
    [string]$RepoRef = 'v1.1.0',
    [string]$ExpectedSha256 = ''
)

$ErrorActionPreference = 'Stop'
$Version = '1.1.0'
$RepoRaw = 'https://raw.githubusercontent.com/stack-Error404/yt-downloader-cli'
$InstallDir = Join-Path $env:LOCALAPPDATA 'Programs\Error404MediaConsole'
$Target = Join-Path $InstallDir 'yt.ps1'

function Install-Dependencies {
    $missingYtDlp = -not (Get-Command yt-dlp -ErrorAction SilentlyContinue)
    $missingFfmpeg = -not (Get-Command ffmpeg -ErrorAction SilentlyContinue)
    if (-not $missingYtDlp -and -not $missingFfmpeg) { return }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget não está disponível. Instale yt-dlp e ffmpeg manualmente.'
    }
    if ($missingYtDlp) {
        winget install --id yt-dlp.yt-dlp --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar yt-dlp com winget.' }
    }
    if ($missingFfmpeg) {
        winget install --id Gyan.FFmpeg --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar ffmpeg com winget.' }
    }
}

Install-Dependencies
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$temporary = Join-Path $InstallDir ('.yt.' + [Guid]::NewGuid().ToString('N') + '.ps1')

try {
    $localSource = Join-Path $PSScriptRoot 'yt.ps1'
    if ($PSScriptRoot -and (Test-Path -LiteralPath $localSource)) {
        Copy-Item -LiteralPath $localSource -Destination $temporary
        $checksumFile = Join-Path $PSScriptRoot 'checksums.sha256'
        if (Test-Path -LiteralPath $checksumFile) {
            $match = Select-String -Path $checksumFile -Pattern '^([0-9a-fA-F]{64})\s+\*?yt\.ps1$' | Select-Object -First 1
            if ($match) { $ExpectedSha256 = $match.Matches[0].Groups[1].Value }
        }
    } else {
        $baseUrl = "$RepoRaw/$RepoRef"
        Invoke-WebRequest -Uri "$baseUrl/yt.ps1" -OutFile $temporary
        if (-not $ExpectedSha256) {
            $manifest = (Invoke-WebRequest -Uri "$baseUrl/checksums.sha256").Content
            $match = [regex]::Match($manifest, '(?im)^([0-9a-f]{64})\s+\*?yt\.ps1$')
            if (-not $match.Success) { throw 'Checksum de yt.ps1 não encontrado.' }
            $ExpectedSha256 = $match.Groups[1].Value
        }
    }
    if ($ExpectedSha256) {
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $temporary).Hash
        if ($actual -ne $ExpectedSha256) { throw 'Falha de integridade: SHA-256 inesperado para yt.ps1.' }
    }
    Move-Item -Force -LiteralPath $temporary -Destination $Target
} finally {
    Remove-Item -Force -ErrorAction SilentlyContinue -LiteralPath $temporary
}

$launcher = @'
@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0yt.ps1" %*
'@
Set-Content -LiteralPath (Join-Path $InstallDir 'yt.cmd') -Value $launcher -Encoding Ascii

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathParts = @($userPath -split ';' | Where-Object { $_ })
if ($InstallDir -notin $pathParts) {
    $newPath = (($pathParts + $InstallDir) -join ';')
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
}

Write-Host "`nError404 // Media Console v$Version instalado em: $InstallDir" -ForegroundColor Green
Write-Host 'Abra um novo PowerShell ou Prompt de Comando e execute: yt'
