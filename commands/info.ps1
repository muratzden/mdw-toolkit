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

    Write-MDWHeader -Title "MDW Workspace" -Subtitle "Workspace Intelligence"

    Write-MDWSection -Title "Workspace"
    Write-MDWInfoCard -Label "Toolkit" -Value $result.Workspace.ToolkitRoot
    Write-MDWInfoCard -Label "Workspace" -Value $result.Workspace.Path
    Write-MDWInfoCard -Label "Plugins" -Value $result.Workspace.PluginsPath
    Write-MDWInfoCard -Label "Build" -Value $result.Workspace.BuildPath
    Write-MDWInfoCard -Label "Releases" -Value $result.Workspace.ReleasesPath
    Write-MDWInfoCard -Label "Backup" -Value $result.Workspace.BackupPath
    Write-MDWInfoCard -Label "Config" -Value $result.Workspace.ConfigPath
    Write-MDWInfoCard -Label "Version" -Value $result.Workspace.ToolkitVersion

    Write-MDWSection -Title "Current Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $result.Plugin.Slug
    Write-MDWInfoCard -Label "Version" -Value $result.Plugin.Version
    Write-MDWInfoCard -Label "Path" -Value $result.Plugin.Path

    Write-MDWSection -Title "Git"
    if ($result.Git.Available) {
        Write-MDWStatusLine -Status "OK" -Message $result.Git.Branch
    }
    else {
        Write-MDWStatusLine -Status "WARN" -Message $result.Git.Status
    }
    Write-MDWInfoCard -Label "Status" -Value $result.Git.Status

    Write-MDWSection -Title "Release"
    Write-MDWInfoCard -Label "Last ZIP" -Value $result.Release.Package
    if ($result.Release.LastReleaseDate) {
        Write-MDWInfoCard -Label "Last Release" -Value ([datetime] $result.Release.LastReleaseDate).ToString("yyyy-MM-dd HH:mm")
    }
    else {
        Write-MDWInfoCard -Label "Last Release" -Value $null
    }
    Write-MDWInfoCard -Label "Backups" -Value $result.Release.BackupCount

    Write-MDWSection -Title "Environment"
    Write-MDWStatusLine -Status ($(if ($result.Environment.PHP.Available) { "OK" } else { "WARN" })) -Message ($(if ($result.Environment.PHP.Version) { $result.Environment.PHP.Version } else { "PHP not available" }))
    Write-MDWStatusLine -Status ($(if ($result.Environment.Composer.Available) { "OK" } else { "WARN" })) -Message ($(if ($result.Environment.Composer.Version) { $result.Environment.Composer.Version } else { "Composer not available" }))
    Write-MDWStatusLine -Status ($(if ($result.Environment.PluginCheck.Available) { "OK" } else { "WARN" })) -Message "WordPress Plugin Check"
    Write-MDWStatusLine -Status ($(if ($result.Environment.SVN.Available) { "OK" } else { "WARN" })) -Message ($(if ($result.Environment.SVN.Version) { "SVN $($result.Environment.SVN.Version)" } else { "SVN not available" }))
    Write-Host ""
}
