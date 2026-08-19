[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string] $ScriptPath,

    [Parameter(Position = 1)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._/:@-]*$')]
    [string] $Image = "sl-universal-image:latest"
)

$ErrorActionPreference = "Stop"

function ConvertTo-BashSingleQuotedLiteral {
    param([Parameter(Mandatory)][string] $Value)

    return "'" + $Value.Replace("'", "'`"'`"'") + "'"
}

if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
    throw "Cannot find the extractor script: $ScriptPath"
}
$resolvedScriptPath = (Resolve-Path -LiteralPath $ScriptPath).Path

& wsl.exe --status *> $null
if ($LASTEXITCODE -ne 0) {
    throw "WSL is unavailable (wsl.exe --status exited with $LASTEXITCODE)."
}

$distributions = @(& wsl.exe -l -q 2> $null | Where-Object { $_.Trim() })
if ($LASTEXITCODE -ne 0 -or $distributions.Count -eq 0) {
    throw "WSL has no available Linux distribution."
}

$wslScriptPath = (& wsl.exe --exec wslpath -a -u $resolvedScriptPath).Trim()
if ($LASTEXITCODE -ne 0 -or -not $wslScriptPath) {
    throw "Could not convert the extractor path to a WSL path."
}

# bash -i loads ~/.bashrc, where tools used by the extractor (such as npx)
# may have been added to PATH.
$quotedScriptPath = ConvertTo-BashSingleQuotedLiteral $wslScriptPath
$quotedImage = ConvertTo-BashSingleQuotedLiteral $Image
$bashCommand = "python3 $quotedScriptPath $quotedImage"
& wsl.exe -- bash -ic $bashCommand

if ($LASTEXITCODE -ne 0) {
    throw "The WSL extractor failed with exit code $LASTEXITCODE."
}
