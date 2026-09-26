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
if ($LASTEXITCODE -ne 0 -or ($version -join '').Trim() -ne 'yt 1.1.0') { throw 'Falha em --version' }

& $PowerShell -NoLogo -NoProfile -File $ScriptPath --nao-existe 2>$null
if ($LASTEXITCODE -ne 2) { throw 'Argumento desconhecido deveria retornar 2' }

Write-Host 'Todos os testes PowerShell passaram.' -ForegroundColor Green
exit 0
