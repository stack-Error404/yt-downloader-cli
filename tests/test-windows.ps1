$ErrorActionPreference = 'Stop'
$ProjectDir = Split-Path -Parent $PSScriptRoot
$ScriptPath = Join-Path $ProjectDir 'yt.ps1'
$InstallPath = Join-Path $ProjectDir 'install.ps1'

$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw "Erros de sintaxe em yt.ps1: $parseErrors" }
$installAst = [System.Management.Automation.Language.Parser]::ParseFile($InstallPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw "Erros de sintaxe em install.ps1: $parseErrors" }
if (-not $installAst.ParamBlock) { throw 'install.ps1 precisa começar com um único bloco param(...) para funcionar via irm | iex.' }
$installBytes = [IO.File]::ReadAllBytes($InstallPath)
if ($installBytes.Length -ge 3 -and $installBytes[0] -eq 0xef -and $installBytes[1] -eq 0xbb -and $installBytes[2] -eq 0xbf) {
    throw 'install.ps1 não pode conter BOM UTF-8: irm | iex entrega o BOM como caractere do script.'
}

$rootJoins = $installAst.FindAll({
    param($node)
    $node -is [System.Management.Automation.Language.CommandAst] -and
        $node.GetCommandName() -eq 'Join-Path' -and
        $node.Extent.Text -match '\$PSScriptRoot'
}, $true)
foreach ($rootJoin in $rootJoins) {
    $ancestor = $rootJoin.Parent
    $isGuarded = $false
    while ($ancestor) {
        if ($ancestor -is [System.Management.Automation.Language.IfStatementAst]) {
            $guard = $ancestor.Clauses | Where-Object { $_.Item1.Extent.Text -match '\$(PSScriptRoot|localSource)' } | Select-Object -First 1
            if ($guard) {
                $isGuarded = $true
                break
            }
        }
        $ancestor = $ancestor.Parent
    }
    if (-not $isGuarded) {
        throw 'Join-Path não pode receber $PSScriptRoot antes de validar que ele existe (irm | iex).'
    }
}

$PowerShell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell.exe' }

$help = & $PowerShell -NoLogo -NoProfile -File $ScriptPath --help
if ($LASTEXITCODE -ne 0 -or ($help -join "`n") -notmatch 'Uso: yt') { throw 'Falha em --help' }

$version = & $PowerShell -NoLogo -NoProfile -File $ScriptPath --version
if ($LASTEXITCODE -ne 0 -or ($version -join '').Trim() -ne 'yt 1.2.0') { throw 'Falha em --version' }

& $PowerShell -NoLogo -NoProfile -File $ScriptPath --nao-existe 2>$null
if ($LASTEXITCODE -ne 2) { throw 'Argumento desconhecido deveria retornar 2' }

$scriptBytes = [IO.File]::ReadAllBytes($ScriptPath)
if ($scriptBytes.Length -lt 3 -or $scriptBytes[0] -ne 0xef -or $scriptBytes[1] -ne 0xbb -or $scriptBytes[2] -ne 0xbf) {
    throw 'yt.ps1 precisa de BOM UTF-8: o Windows PowerShell 5.1 lê o arquivo como ANSI sem ele e quebra o visual do menu.'
}

$env:YT_PREVIEW = '100x40'
$env:YT_PREVIEW_SEL = '4'
$preview = & $PowerShell -NoLogo -NoProfile -File $ScriptPath
$previewText = $preview -join "`n"
foreach ($expected in 'ERROR404 // MEDIA CONSOLE', 'status: online // select an option', 'downloads: ') {
    if (-not $previewText.Contains($expected)) { throw "Visual do menu sem: $expected" }
}
if ($preview.Count -ne 35) { throw "Quadro completo deveria ter 35 linhas (veio $($preview.Count))" }
$selectedLines = @($preview | Where-Object { $_.Contains([string][char]27 + '[48;2;93;255;56m') })
if ($selectedLines.Count -ne 1) { throw 'Deve haver exatamente uma linha selecionada' }
$env:YT_PREVIEW = '80x30'
if (@(& $PowerShell -NoLogo -NoProfile -File $ScriptPath).Count -ne 30) { throw 'Quadro compacto deveria ter 30 linhas' }
$env:YT_PREVIEW = '40x10'
& $PowerShell -NoLogo -NoProfile -File $ScriptPath 2>$null | Out-Null
if ($LASTEXITCODE -ne 1) { throw 'Janela pequena deveria ser recusada' }
Remove-Item Env:YT_PREVIEW, Env:YT_PREVIEW_SEL

$updateHome = Join-Path ([IO.Path]::GetTempPath()) ('yt-update-lock-' + [Guid]::NewGuid().ToString('N'))
$stateDir = Join-Path $updateHome 'Error404MediaConsole'
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
Set-Content -LiteralPath (Join-Path $stateDir 'min-version.txt') -Value '9.9.9' -NoNewline
$originalLocalAppData = $env:LOCALAPPDATA
$env:LOCALAPPDATA = $updateHome
try {
    & $PowerShell -NoLogo -NoProfile -File $ScriptPath --version 2>$null | Out-Null
    if ($LASTEXITCODE -ne 1) { throw 'Cópia substituída por atualização confirmada deveria ser bloqueada' }
    Set-Content -LiteralPath (Join-Path $stateDir 'min-version.txt') -Value '0.0.1' -NoNewline
    $unlocked = & $PowerShell -NoLogo -NoProfile -File $ScriptPath --version
    if ($LASTEXITCODE -ne 0 -or ($unlocked -join '').Trim() -ne 'yt 1.2.0') { throw 'min-version anterior à instalada não deveria bloquear' }
} finally {
    $env:LOCALAPPDATA = $originalLocalAppData
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -LiteralPath $updateHome
}
Write-Host 'Bloqueio local de versão substituída (min-version) OK' -ForegroundColor Green

Write-Host 'Todos os testes PowerShell passaram.' -ForegroundColor Green
exit 0
