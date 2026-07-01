<#
MDW Workspace Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWWorkspaceConfigValue {
    [CmdletBinding()]
    param(
        [object] $Config,
        [string] $PrimaryKey,
        [string] $FallbackKey,
        [object] $DefaultValue
    )

    $value = Get-MDWConfigValue -Config $Config -Key $PrimaryKey -DefaultValue $null

    if ($null -ne $value) {
        return $value
    }

    if (-not [string]::IsNullOrWhiteSpace($FallbackKey)) {
        $value = Get-MDWConfigValue -Config $Config -Key $FallbackKey -DefaultValue $null

        if ($null -ne $value) {
            return $value
        }
    }

    return $DefaultValue
}

function Resolve-MDWWorkspaceCurrentPlugin {
    [CmdletBinding()]
    param(
        [string] $PluginsRoot,
        [string] $ReleasesRoot
    )

    $currentPath = (Get-Location).ProviderPath

    if (-not [string]::IsNullOrWhiteSpace($PluginsRoot) -and
        -not [string]::IsNullOrWhiteSpace($currentPath) -and
        $currentPath.StartsWith($PluginsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return Split-Path $currentPath -Leaf
    }

    if (Test-Path -LiteralPath $ReleasesRoot -PathType Container) {
        $latestRelease = Get-ChildItem -LiteralPath $ReleasesRoot -Directory -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($null -ne $latestRelease) {
            return $latestRelease.Name
        }
    }

    if (Test-Path -LiteralPath $PluginsRoot -PathType Container) {
        $latestPlugin = Get-ChildItem -LiteralPath $PluginsRoot -Directory -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($null -ne $latestPlugin) {
            return $latestPlugin.Name
        }
    }

    return $null
}

function Invoke-MDWWorkspaceService {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    $toolkitRoot = Get-MDWRootPath
    $config = Get-MDWConfig -ToolkitRoot $toolkitRoot

    $workspacePath = Get-MDWWorkspaceConfigValue -Config $config -PrimaryKey "workspace.rootPath" -FallbackKey "Workspace" -DefaultValue "C:\Workspace"
    $pluginsRoot = Get-MDWWorkspaceConfigValue -Config $config -PrimaryKey "workspace.pluginsPath" -FallbackKey "Plugins" -DefaultValue "C:\Workspace\Plugins"
    $buildRoot = Join-Path $workspacePath "Build"
    $releasesRoot = Get-MDWWorkspaceConfigValue -Config $config -PrimaryKey "workspace.releasesPath" -FallbackKey "Releases" -DefaultValue (Join-Path $workspacePath "Releases")
    $backupRoot = Get-MDWWorkspaceConfigValue -Config $config -PrimaryKey "workspace.backupPath" -FallbackKey "Backup" -DefaultValue "D:\Workspace Backup"
    $toolkitVersion = Get-MDWWorkspaceConfigValue -Config $config -PrimaryKey "version" -FallbackKey "" -DefaultValue "0.1.2-alpha"
    $configPath = $config._path

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        $PluginSlug = Resolve-MDWWorkspaceCurrentPlugin -PluginsRoot $pluginsRoot -ReleasesRoot $releasesRoot
    }

    $pluginPath = $null
    $releasePath = $null
    $backupPath = $null

    if (-not [string]::IsNullOrWhiteSpace($PluginSlug)) {
        $pluginPath = Join-Path $pluginsRoot $PluginSlug
        $releasePath = Join-Path $releasesRoot $PluginSlug
        $backupPath = Join-Path $backupRoot $PluginSlug
    }

    $result = Invoke-MDWWorkspaceValidator `
        -WorkspacePath $workspacePath `
        -ToolkitRoot $toolkitRoot `
        -PluginSlug $PluginSlug `
        -PluginPath $pluginPath `
        -ReleasePath $releasePath `
        -BackupPath $backupPath

    $result.Workspace.ToolkitVersion = $toolkitVersion
    $result.Workspace.PluginsPath = $pluginsRoot
    $result.Workspace.BuildPath = $buildRoot
    $result.Workspace.ReleasesPath = $releasesRoot
    $result.Workspace.BackupPath = $backupRoot
    $result.Workspace.ConfigPath = $configPath

    return $result
}
