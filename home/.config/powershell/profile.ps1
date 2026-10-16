# PowerShell 7+, including native Windows. No package or profile installation.
if (-not $env:DOTFILES_CONFIG_HOME) {
    $env:DOTFILES_CONFIG_HOME = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
}
if (-not $env:DOTFILES_DATA_HOME) {
    $env:DOTFILES_DATA_HOME = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $HOME '.local/share' }
}
$dotfilesCargoHome = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $HOME '.cargo' }
$dotfilesGoBin = if ($env:GOBIN) { $env:GOBIN } elseif ($env:GOPATH) { Join-Path $env:GOPATH 'bin' } else { Join-Path $HOME 'go/bin' }
$dotfilesPnpmHome = if ($env:PNPM_HOME) { $env:PNPM_HOME } else { Join-Path $env:DOTFILES_DATA_HOME 'pnpm' }
$dotfilesPaths = @((Join-Path $HOME '.local/bin'), (Join-Path $HOME 'bin'), (Join-Path $dotfilesCargoHome 'bin'), $dotfilesGoBin, $dotfilesPnpmHome)
if (($env:DOTFILES_RUNTIMES -split ',') -contains 'bun') {
    $dotfilesPaths += if ($env:BUN_INSTALL) { Join-Path $env:BUN_INSTALL 'bin' } else { Join-Path $HOME '.bun/bin' }
}
for ($dotfilesPathIndex = $dotfilesPaths.Count - 1; $dotfilesPathIndex -ge 0; $dotfilesPathIndex--) {
    $dotfilesPath = $dotfilesPaths[$dotfilesPathIndex]
    if ((Test-Path -LiteralPath $dotfilesPath -PathType Container) -and ($env:PATH -split [IO.Path]::PathSeparator) -notcontains $dotfilesPath) {
        $env:PATH = $dotfilesPath + [IO.Path]::PathSeparator + $env:PATH
    }
}
$env:LESS = '-R'
$env:LESSHISTFILE = '-'
if (Test-Path -LiteralPath (Join-Path $env:DOTFILES_CONFIG_HOME 'ripgrep/config')) { $env:RIPGREP_CONFIG_PATH = Join-Path $env:DOTFILES_CONFIG_HOME 'ripgrep/config' }
if (-not $env:STARSHIP_CONFIG -and (Test-Path -LiteralPath (Join-Path $env:DOTFILES_CONFIG_HOME 'starship.toml') -PathType Leaf)) { $env:STARSHIP_CONFIG = Join-Path $env:DOTFILES_CONFIG_HOME 'starship.toml' }
if (-not $env:ATUIN_CONFIG_DIR -and (Test-Path -LiteralPath (Join-Path $env:DOTFILES_CONFIG_HOME 'atuin/config.toml') -PathType Leaf)) { $env:ATUIN_CONFIG_DIR = Join-Path $env:DOTFILES_CONFIG_HOME 'atuin' }
if (Get-Variable -Name DotfilesProfileLoaded -Scope Global -ValueOnly -ErrorAction SilentlyContinue) { return }
$global:DotfilesProfileLoaded = $true
$dotfilesInteractive = [Environment]::GetCommandLineArgs() -notcontains '-NonInteractive' -and -not [Console]::IsInputRedirected
function Test-DotfilesCommand([string]$Name) { return [bool](Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue) }
function global:dotfiles_open([string]$Path) { Invoke-Item -LiteralPath $Path }
function global:dotfiles_copy { $input | Set-Clipboard }
function global:dotfiles_paste { Get-Clipboard -Raw }
function global:Show-DotfilesAliasTip([string]$CommandLine) {
    foreach ($dotfilesAlias in Get-Alias) {
        $dotfilesExpansion = $dotfilesAlias.Definition
        if ($dotfilesExpansion.Length -gt $dotfilesAlias.Name.Length -and ($CommandLine -eq $dotfilesExpansion -or $CommandLine.StartsWith($dotfilesExpansion + ' ', [StringComparison]::Ordinal))) {
            Write-Host ('Alias tip: ' + $dotfilesAlias.Name)
            return
        }
    }
}
function global:duf([string]$Path = '.') {
    # Native PowerShell fallback avoids assuming GNU du exists on Windows.
    Get-ChildItem -LiteralPath $Path | ForEach-Object {
        $item = $_
        $size = if ($item.PSIsContainer) {
            (Get-ChildItem -LiteralPath $item.FullName -File -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        } else { $item.Length }
        [pscustomobject]@{ Bytes = [long]$size; Name = $item.Name }
    } | Sort-Object Bytes -Descending | Select-Object -First 20
}
function global:suggest-aliases([int]$MinCount = 5, [int]$MinLength = 20) {
    if (-not (Test-DotfilesCommand atuin)) { Write-Error 'Requires atuin'; return }
    atuin history list --cmd-only | Group-Object | Where-Object { $_.Count -ge $MinCount -and $_.Name.Length -ge $MinLength } | Sort-Object Count -Descending | Select-Object Count, Name
}
if ($dotfilesInteractive -and (Test-DotfilesCommand eza)) {
    $global:DotfilesEzaOptions = if ((Test-Path Env:NO_COLOR) -or $env:DOTFILES_ICONS -eq '0' -or $env:TERM -eq 'dumb') { @('--icons=never', '--color=never') } else { @('--icons') }
    # Preserve PowerShell's object-producing ls/dir aliases; enhanced views are explicit.
    function global:ll { eza -lag @global:DotfilesEzaOptions --group-directories-first --git @args }
    function global:la { eza -a @global:DotfilesEzaOptions --group-directories-first @args }
    function global:lt { eza -T @global:DotfilesEzaOptions --level=2 @args }
}
if ($dotfilesInteractive) {
    foreach ($dotfilesPair in @(@('woodpecker', 'woodpecker-cli'), @('scaleway', 'scw'), @('proton-pass', 'pass-cli'), @('opentofu', 'tofu'))) {
        if (-not (Test-DotfilesCommand $dotfilesPair[0]) -and (Test-DotfilesCommand $dotfilesPair[1])) { Set-Alias -Scope Global -Name $dotfilesPair[0] -Value $dotfilesPair[1] }
    }
}
# Interactive integrations only. Pipelines and -NonInteractive stay usable.
if ($dotfilesInteractive -and -not [Console]::IsInputRedirected -and $env:DOTFILES_PROFILE -notin @('minimal', 'container')) {
    if (($env:DOTFILES_RUNTIMES -split ',') -contains 'fnm' -and (Test-DotfilesCommand fnm)) { $dotfilesCode = fnm env --use-on-cd --shell powershell 2>$null | Out-String; if ($LASTEXITCODE -eq 0 -and $dotfilesCode.Trim()) { Invoke-Expression $dotfilesCode } }
    if (Test-DotfilesCommand zoxide) { $dotfilesCode = zoxide init powershell --cmd cd 2>$null | Out-String; if ($LASTEXITCODE -eq 0 -and $dotfilesCode.Trim()) { Invoke-Expression $dotfilesCode } }
    if (Test-DotfilesCommand direnv) { $dotfilesCode = direnv hook pwsh 2>$null | Out-String; if ($LASTEXITCODE -eq 0 -and $dotfilesCode.Trim()) { Invoke-Expression $dotfilesCode } }
    if (Get-Module -ListAvailable PSReadLine) {
        Import-Module PSReadLine
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -HistorySaveStyle SaveIncrementally
        if (Test-DotfilesCommand atuin) {
            $dotfilesCode = atuin init powershell --disable-up-arrow --disable-ai 2>$null | Out-String; if ($LASTEXITCODE -eq 0 -and $dotfilesCode.Trim()) { Invoke-Expression $dotfilesCode }
        }
    }
    # Invoke-DotfilesDirenv below also supports explicit environment refresh.
}
# Prompt selection applies to every profile, including minimal/container.
if ($dotfilesInteractive -and (Test-DotfilesCommand starship) -and -not (Test-Path Env:NO_COLOR) -and $env:TERM -ne 'dumb') {
    $dotfilesCode = starship init powershell 2>$null | Out-String
    if ($LASTEXITCODE -eq 0 -and $dotfilesCode.Trim()) { Invoke-Expression $dotfilesCode }
}
function global:Invoke-DotfilesDirenv {
    if (-not (Test-DotfilesCommand direnv)) { throw 'Requires direnv' }
    $dotfilesEnvironment = direnv export json | ConvertFrom-Json -AsHashtable
    foreach ($dotfilesKey in $dotfilesEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($dotfilesKey, $dotfilesEnvironment[$dotfilesKey], 'Process')
    }
}
$dotfilesLocal = Join-Path $env:DOTFILES_CONFIG_HOME 'powershell/local.ps1'
if (Test-Path -LiteralPath $dotfilesLocal -PathType Leaf) { . $dotfilesLocal }
Remove-Variable dotfilesCargoHome, dotfilesGoBin, dotfilesPnpmHome, dotfilesPaths, dotfilesPath, dotfilesPathIndex, dotfilesPair, dotfilesInteractive, dotfilesLocal -ErrorAction SilentlyContinue
