<#
MDW Local Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWLocalCheck {
    [CmdletBinding()]
    param(
        [object] $Report,
        [string] $Name
    )

    foreach ($check in $Report.Checks) {
        if ($check.Name -eq $Name) {
            return $check
        }
    }

    return $null
}

function Write-MDWLocalEnvironment {
    [CmdletBinding()]
    param(
        [object] $Report
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Local"

    Write-MDWSection -Title "Environment"
    Write-MDWInfoCard -Label "Provider" -Value $Report.Provider
    Write-MDWInfoCard -Label "Root" -Value $Report.RootPath
    Write-MDWInfoCard -Label "Site" -Value $Report.SitePath
    Write-MDWInfoCard -Label "Plugins" -Value $Report.PluginsPath
    Write-MDWInfoCard -Label "URL" -Value $Report.SiteUrl
    Write-MDWInfoCard -Label "Admin" -Value $Report.AdminUrl

    Write-MDWSection -Title "Status"

    $hasFailure = $false

    foreach ($check in $Report.Checks) {
        if ($check.Passed) {
            Write-MDWStatus -Status "OK" -Message $check.Name
        }
        else {
            Write-MDWStatus -Status "WARN" -Message $check.Name
            $hasFailure = $true
        }
    }

    if ($hasFailure) {
        Write-MDWResult -Status "WARN" -Message "Local environment has warnings."
        return
    }

    Write-MDWResult -Status "OK" -Message "Local environment ready."
}

function Write-MDWLocalPluginStatus {
    [CmdletBinding()]
    param(
        [object] $Status
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Local Plugin Status"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $Status.PluginSlug
    Write-MDWInfoCard -Label "Target" -Value $Status.TargetPath
    Write-MDWInfoCard -Label "Exists" -Value $Status.Exists
    Write-MDWInfoCard -Label "Junction" -Value $Status.IsJunction
    Write-MDWInfoCard -Label "Status" -Value $Status.Status

    if ($Status.Exists -and $Status.IsJunction) {
        Write-MDWResult -Status "OK" -Message "Plugin is linked to local WordPress."
        return
    }

    if ($Status.Exists -and -not $Status.IsJunction) {
        Write-MDWResult -Status "WARN" -Message "Plugin exists but is not a junction."
        return
    }

    Write-MDWResult -Status "WARN" -Message "Plugin is not linked."
}

function Write-MDWLocalLinkResult {
    [CmdletBinding()]
    param(
        [object] $Result
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Local Link"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $Result.PluginSlug
    Write-MDWInfoCard -Label "Source" -Value $Result.SourcePath
    Write-MDWInfoCard -Label "Target" -Value $Result.TargetPath

    if ($Result.Warnings.Count -gt 0) {
        Write-MDWSection -Title "Warnings"

        foreach ($warning in $Result.Warnings) {
            Write-MDWStatus -Status "WARN" -Message $warning
        }
    }

    if ($Result.Errors.Count -gt 0) {
        Write-MDWSection -Title "Errors"

        foreach ($errorItem in $Result.Errors) {
            Write-MDWStatus -Status "FAIL" -Message $errorItem
        }
    }

    if ($Result.Passed) {
        Write-MDWResult -Status "OK" -Message "Plugin linked to local WordPress."
        return
    }

    Write-MDWResult -Status "FAIL" -Message "Plugin link failed."
}

function Get-MDWLocalPluginSlugFromArguments {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    if ($Arguments.Count -gt 1 -and -not [string]::IsNullOrWhiteSpace($Arguments[1])) {
        return $Arguments[1]
    }

    $currentPath = Get-Location
    return Split-Path $currentPath -Leaf
}

function Invoke-MDWLocal {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $subCommand = "info"

    if ($Arguments -and $Arguments.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($Arguments[0])) {
        $subCommand = $Arguments[0].ToLowerInvariant()
    }

    if ($subCommand -eq "info" -or $subCommand -eq "doctor" -or $subCommand -eq "status") {
        $report = Get-MDWLocalReport
        Write-MDWLocalEnvironment -Report $report
        return
    }

    if ($subCommand -eq "link") {
        $pluginSlug = Get-MDWLocalPluginSlugFromArguments -Arguments $Arguments
        $result = New-MDWLocalPluginLink -PluginSlug $pluginSlug
        Write-MDWLocalLinkResult -Result $result
        return
    }

    if ($subCommand -eq "plugin-status") {
        $pluginSlug = Get-MDWLocalPluginSlugFromArguments -Arguments $Arguments
        $status = Get-MDWLocalPluginStatus -PluginSlug $pluginSlug
        Write-MDWLocalPluginStatus -Status $status
        return
    }

    if ($subCommand -eq "open") {
        $config = Get-MDWLocalConfig
        Start-Process $config.siteUrl
        return
    }

    if ($subCommand -eq "admin") {
        $config = Get-MDWLocalConfig
        Start-Process $config.adminUrl
        return
    }

    throw "Unknown local subcommand: $subCommand. Usage: mdw local [info|doctor|status|link <plugin-slug>|plugin-status <plugin-slug>|open|admin]"
}