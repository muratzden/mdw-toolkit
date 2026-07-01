<#
MDW Test Runner Entry
PowerShell 5.1 / 7 compatible
#>

[CmdletBinding()]
param()

Set-StrictMode -Version 2.0

$toolkitRoot = Split-Path -Parent $PSScriptRoot
$mdwPath = Join-Path $toolkitRoot "mdw.ps1"

if (-not (Test-Path -LiteralPath $mdwPath -PathType Leaf)) {
    throw "MDW router not found: $mdwPath"
}

& $mdwPath test
exit $LASTEXITCODE
