<#
MDW Info Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Write-MDWInfoStatus {
    [CmdletBinding()]
    param(
        [bool] $Passed,
        [string] $Text
    )

    if ($Passed) {
        Write-Host ("[OK] {0}" -f $Text) -ForegroundColor Green
    }
    else {
        Write-Host ("[WARN] {0}" -f $Text) -ForegroundColor Yellow
    }
}

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

    Write-Host ""
    Write-Host "MDW Workspace" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Workspace" -ForegroundColor Yellow
    Write-MDWInfoStatus -Passed (Test-Path -LiteralPath $result.Workspace.Path -PathType Container) -Text $result.Workspace.Path
    Write-Host ("Toolkit Version: {0}" -f $result.Workspace.ToolkitVersion)
    Write-Host ""

    Write-Host "Current Plugin" -ForegroundColor Yellow

    if ($result.Plugin.Slug) {
        Write-Host $result.Plugin.Slug
    }
    else {
        Write-Host "(none)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Plugin Version" -ForegroundColor Yellow
    Write-Host ($(if ($result.Plugin.Version) { $result.Plugin.Version } else { "(unknown)" }))
    Write-Host ""

    Write-Host "Plugin Path" -ForegroundColor Yellow
    Write-Host ($(if ($result.Plugin.Path) { $result.Plugin.Path } else { "(none)" }))
    Write-Host ""

    Write-Host "Git" -ForegroundColor Yellow
    Write-MDWInfoStatus -Passed $result.Git.Available -Text ($(if ($result.Git.Branch) { $result.Git.Branch } else { $result.Git.Status }))
    Write-Host $result.Git.Status
    Write-Host ""

    Write-Host "Build" -ForegroundColor Yellow
    Write-Host "Last ZIP"
    Write-Host ($(if ($result.Release.Package) { $result.Release.Package } else { "(none)" }))
    Write-Host ""

    Write-Host "Release" -ForegroundColor Yellow
    Write-Host "Last Release"

    if ($result.Release.LastReleaseDate) {
        Write-Host ([datetime] $result.Release.LastReleaseDate).ToString("yyyy-MM-dd HH:mm")
    }
    else {
        Write-Host "(none)"
    }

    Write-Host ""
    Write-Host "Backups" -ForegroundColor Yellow
    Write-Host $result.Release.BackupCount
    Write-Host ""

    Write-Host "Environment" -ForegroundColor Yellow
    Write-MDWInfoStatus -Passed $result.Environment.PHP.Available -Text ($(if ($result.Environment.PHP.Version) { $result.Environment.PHP.Version } else { "PHP" }))
    Write-MDWInfoStatus -Passed $result.Environment.Composer.Available -Text ($(if ($result.Environment.Composer.Version) { $result.Environment.Composer.Version } else { "Composer" }))
    Write-MDWInfoStatus -Passed $result.Environment.PluginCheck.Available -Text "Plugin Check"
    Write-MDWInfoStatus -Passed $result.Environment.SVN.Available -Text ($(if ($result.Environment.SVN.Version) { "SVN $($result.Environment.SVN.Version)" } else { "SVN" }))
    Write-Host ""
}
