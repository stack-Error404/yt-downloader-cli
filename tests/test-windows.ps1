$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $PSScriptRoot
$ScriptPath = Join-Path $ProjectDir 'yt.ps1'
$InstallPath = Join-Path $ProjectDir 'install.ps1'

$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw "Erros de sintaxe em yt.ps1: $parseErrors" }
[void][System.Management.Automation.Language.Parser]::ParseFile($InstallPath, [ref]$null, [ref]$parseErrors)
if ($parseErrors.Count) { throw "Erros de sintaxe em install.ps1: $parseErrors" }

$PowerShell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell.exe' }

$help = & $PowerShell -NoLogo -NoProfile -File $ScriptPath --help
if ($LASTEXITCODE -ne 0 -or ($help -join "`n") -notmatch 'Uso: yt') { throw 'Falha em --help' }

$version = & $PowerShell -NoLogo -NoProfile -File $ScriptPath --version
if ($LASTEXITCODE -ne 0 -or ($version -join '').Trim() -ne 'yt 1.1.0') { throw 'Falha em --version' }

& $PowerShell -NoLogo -NoProfile -File $ScriptPath --nao-existe 2>$null
if ($LASTEXITCODE -ne 2) { throw 'Argumento desconhecido deveria retornar 2' }

Write-Host 'Todos os testes PowerShell passaram.' -ForegroundColor Green
