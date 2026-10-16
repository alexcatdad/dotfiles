param([Parameter(ValueFromRemainingArguments = $true)][string[]]$ToolArguments)
$ErrorActionPreference = 'Stop'
$dotfilesRepo = Split-Path $PSScriptRoot
$dotfilesBuild = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-tools-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $dotfilesBuild | Out-Null
try {
    Push-Location $dotfilesRepo
    try {
        $dotfilesPreviousToolchain = $env:GOTOOLCHAIN
        $env:GOTOOLCHAIN = 'local'
        go build -o (Join-Path $dotfilesBuild 'dotfiles.exe') ./cmd/dotfiles
        if ($LASTEXITCODE -ne 0) { throw 'Go build failed; install Go 1.23 or later first' }
    } finally { $env:GOTOOLCHAIN = $dotfilesPreviousToolchain; Pop-Location }
    & (Join-Path $dotfilesBuild 'dotfiles.exe') tools --repo $dotfilesRepo @ToolArguments
    if ($LASTEXITCODE -ne 0) { throw 'Tool preparation failed' }
} finally { Remove-Item -LiteralPath $dotfilesBuild -Recurse -Force }
