<#
MDW Info Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWInfo {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $pluginSlug = $null

    if ($Arguments -and $Arguments.Count -gt 0) {
        $pluginSlug = $Arguments[0]
    }

    $result = Invoke-MDWWorkspaceService -PluginSlug $pluginSlug

    Write-MDWHeader -Title (Get-MDWToolkitName) -Subtitle "Workspace Intelligence"

    Write-MDWSection -Title "Workspace"
    Write-MDWInfoCard -Label "Workspace" -Value $result.Workspace.Path
    Write-MDWInfoCard -Label "Toolkit" -Value $result.Workspace.ToolkitRoot
    Write-MDWInfoCard -Label "Config" -Value $result.Workspace.ConfigPath

    Write-MDWSection -Title "Directories"
    Write-MDWInfoCard -Label "Plugins" -Value $result.Workspace.PluginsPath
    Write-MDWInfoCard -Label "Build" -Value $result.Workspace.BuildPath
    Write-MDWInfoCard -Label "Releases" -Value $result.Workspace.ReleasesPath
    Write-MDWInfoCard -Label "Backups" -Value $result.Workspace.BackupPath

    if ($result.Plugin -and $result.Plugin.Slug) {
        Write-MDWSection -Title "Current Plugin"
        Write-MDWInfoCard -Label "Plugin" -Value $result.Plugin.Slug
        Write-MDWInfoCard -Label "Version" -Value $result.Plugin.Version
        Write-MDWInfoCard -Label "Path" -Value $result.Plugin.Path
    }

    Write-MDWResult -Status "OK" -Message "Workspace configuration loaded."
}