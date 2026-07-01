<#
MDW Toolkit Bootstrap
Loads all required core modules.
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

$MDWRoot = Split-Path -Parent $PSScriptRoot

$MDWCoreFiles = @(
    "logger.ps1",
    "config.ps1",
    "command-registry.ps1",
    "test-runner.ps1"
)

foreach ($file in $MDWCoreFiles) {
    $path = Join-Path $PSScriptRoot $file

    if (-not (Test-Path $path)) {
        throw "Required core file not found: $path"
    }

    . $path
}

function Get-MDWRootPath {
    [CmdletBinding()]
    param()

    return $MDWRoot
}

function Resolve-MDWPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $RelativePath
    )

    return Join-Path (Get-MDWRootPath) $RelativePath
}

$MDWValidatorsPath = Join-Path $MDWRoot "validators"

if (Test-Path $MDWValidatorsPath) {
    Get-ChildItem -Path $MDWValidatorsPath -Filter "*.ps1" -File | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }
}

$MDWServicesPath = Join-Path $MDWRoot "services"

if (Test-Path $MDWServicesPath) {
    Get-ChildItem -Path $MDWServicesPath -Filter "*.ps1" -File | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }
}
