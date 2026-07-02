<#
MDW Check Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWCheckService {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    return Invoke-MDWPluginCheck -PluginSlug $PluginSlug
}
