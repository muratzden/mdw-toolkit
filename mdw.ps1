<#
MDW Toolkit CLI Router
PowerShell 5.1 / 7 compatible
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Arguments
)

Set-StrictMode -Version 2.0

$ErrorActionPreference = "Stop"

try {
    $bootstrapPath = Join-Path $PSScriptRoot "core\bootstrap.ps1"

    if (-not (Test-Path $bootstrapPath)) {
        throw "Bootstrap file not found: $bootstrapPath"
    }

    . $bootstrapPath

    if (-not $Arguments -or $Arguments.Count -eq 0) {
        $commandName = "help"
        $commandArgs = @()
    }
    else {
        $commandName = $Arguments[0].ToLowerInvariant()

        if ($Arguments.Count -gt 1) {
            $commandArgs = $Arguments[1..($Arguments.Count - 1)]
        }
        else {
            $commandArgs = @()
        }
    }

    if ($commandName -eq "--help" -or $commandName -eq "-h") {
        $commandName = "help"
    }

    if ($commandName -eq "--version" -or $commandName -eq "-v") {
        $commandName = "version"
    }

    $registry = Get-MDWCommandRegistry

    foreach ($registeredCommandName in $registry.Keys) {
        $registeredCommand = $registry[$registeredCommandName]
        $registeredScriptPath = Resolve-MDWPath -RelativePath $registeredCommand.Script

        if (Test-Path $registeredScriptPath) {
            . $registeredScriptPath
        }
    }

    $command = Get-MDWCommandDefinition -Name $commandName
    $entryPoint = $command.EntryPoint

    if (-not (Get-Command $entryPoint -ErrorAction SilentlyContinue)) {
        throw "Command entry point not found: $entryPoint"
    }

    & $entryPoint -Arguments $commandArgs

    exit 0
}
catch {
    Write-Host "[MDW ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}