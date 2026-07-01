<#
MDW Plugin Path Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWPluginsRootPath {
    [CmdletBinding()]
    param()

    return "C:\Workspace\Plugins"
}

function Resolve-MDWPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [switch] $RequireExisting
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    $pluginsRoot = Get-MDWPluginsRootPath
    $pluginPath = Join-Path $pluginsRoot $PluginSlug

    if ($RequireExisting -and -not (Test-Path $pluginPath -PathType Container)) {
        throw "Plugin directory not found: $pluginPath"
    }

    return $pluginPath
}
