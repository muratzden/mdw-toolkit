<#
MDW Workspace Path Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWPathConfig {
    [CmdletBinding()]
    param()

    return Get-MDWConfig -ToolkitRoot (Get-MDWRootPath)
}

function Get-MDWRequiredPathConfigValue {
    [CmdletBinding()]
    param(
        [object] $Config,
        [string[]] $Keys,
        [string] $Name
    )

    foreach ($key in $Keys) {
        $value = Get-MDWConfigValue -Config $Config -Key $key -DefaultValue $null

        if (-not [string]::IsNullOrWhiteSpace([string] $value)) {
            return [string] $value
        }
    }

    throw "MDW config missing required path: $Name"
}

function Get-MDWToolkitPath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    $toolkitPath = Get-MDWConfigValue -Config $config -Key "toolkitPath" -DefaultValue $null

    if ([string]::IsNullOrWhiteSpace([string] $toolkitPath)) {
        $toolkitPath = Get-MDWRootPath
    }

    if (Test-Path -LiteralPath $toolkitPath -PathType Container) {
        return (Resolve-Path -LiteralPath $toolkitPath).ProviderPath
    }

    return [string] $toolkitPath
}

function Get-MDWWorkspacePath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    $workspacePath = Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.workspaceRoot", "workspace.rootPath", "Workspace") -Name "workspace root"

    if (Test-Path -LiteralPath $workspacePath -PathType Container) {
        return (Resolve-Path -LiteralPath $workspacePath).ProviderPath
    }

    return $workspacePath
}

function Get-MDWPluginsPath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    return Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.pluginsPath", "Plugins") -Name "plugins path"
}

function Get-MDWBuildPath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    return Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.buildPath", "Build") -Name "build path"
}

function Get-MDWReleasePath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    return Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.releasePath", "workspace.releasesPath", "Releases") -Name "release path"
}

function Get-MDWBackupPath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    return Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.backupPath", "Backup") -Name "backup path"
}

function Get-MDWPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    return Join-Path (Get-MDWPluginsPath) $PluginSlug
}

function Get-MDWBuildPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    return Join-Path (Get-MDWBuildPath) $PluginSlug
}

function Get-MDWReleasePluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    return Join-Path (Get-MDWReleasePath) $PluginSlug
}

function Get-MDWBackupPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    return Join-Path (Get-MDWBackupPath) $PluginSlug
}

function Get-MDWPluginsRootPath {
    [CmdletBinding()]
    param()

    return Get-MDWPluginsPath
}

function Resolve-MDWPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [switch] $RequireExisting
    )

    $pluginPath = Get-MDWPluginPath -PluginSlug $PluginSlug

    if ($RequireExisting -and -not (Test-Path -LiteralPath $pluginPath -PathType Container)) {
        throw "Plugin directory not found: $pluginPath"
    }

    return $pluginPath
}
