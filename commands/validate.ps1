<#
MDW Validate Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWValidate {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $pluginSlug = $null

    if ($Arguments -and $Arguments.Count -gt 0) {
        $pluginSlug = $Arguments[0]
    }

    $toolkitRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $servicePath = Join-Path $toolkitRoot "services\validate-service.ps1"

    if (-not (Test-Path $servicePath)) {
        Write-Host "[ERROR] Validate service not found: $servicePath" -ForegroundColor Red
        return 1
    }

    . $servicePath

    return Invoke-MDWValidateService -ToolkitRoot $toolkitRoot -PluginSlug $pluginSlug
}