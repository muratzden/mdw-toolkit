<#
MDW LocalWP Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWLocalWPDisplayUrl {
    [CmdletBinding()]
    param(
        [object] $Report
    )

    if ($null -eq $Report -or [string]::IsNullOrWhiteSpace([string] $Report.DefaultSite)) {
        return "Not configured"
    }

    return "https://$($Report.DefaultSite).local"
}

function Get-MDWLocalWPCheck {
    [CmdletBinding()]
    param(
        [object] $Report,
        [string] $Name
    )

    if ($null -eq $Report -or $null -eq $Report.Checks) {
        return $null
    }

    foreach ($check in $Report.Checks) {
        if ($check.Name -eq $Name) {
            return $check
        }
    }

    return $null
}

function Write-MDWLocalWPEnvironment {
    [CmdletBinding()]
    param(
        [object] $Report
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "LocalWP"

    Write-MDWSection -Title "Environment"
    Write-MDWInfoCard -Label "Root" -Value $Report.RootPath
    Write-MDWInfoCard -Label "Site" -Value $Report.DefaultSite
    Write-MDWInfoCard -Label "URL" -Value (Get-MDWLocalWPDisplayUrl -Report $Report)

    Write-MDWSection -Title "Status"

    $rootCheck = Get-MDWLocalWPCheck -Report $Report -Name "LocalWP root"
    $siteCheck = Get-MDWLocalWPCheck -Report $Report -Name "Default site"
    $pluginsCheck = Get-MDWLocalWPCheck -Report $Report -Name "Plugins directory"

    if ($null -ne $rootCheck -and $rootCheck.Passed) {
        Write-MDWStatus -Status "OK" -Message "LocalWP detected"
    }
    else {
        Write-MDWStatus -Status "WARN" -Message "LocalWP installation not found"
    }

    if ($null -ne $siteCheck -and $siteCheck.Passed) {
        Write-MDWStatus -Status "OK" -Message "Site found"
    }
    else {
        Write-MDWStatus -Status "WARN" -Message "No LocalWP site found"
    }

    if ($null -ne $pluginsCheck -and $pluginsCheck.Passed) {
        Write-MDWStatus -Status "OK" -Message "WordPress detected"
    }
    else {
        Write-MDWStatus -Status "WARN" -Message "WordPress installation not detected"
    }

    if ($null -ne $rootCheck -and -not $rootCheck.Passed) {
        Write-MDWResult -Status "FAIL" -Message "LocalWP installation not found."
        return
    }

    if ($null -ne $siteCheck -and -not $siteCheck.Passed) {
        Write-MDWResult -Status "WARN" -Message "No LocalWP site found."
        return
    }

    if ($null -ne $pluginsCheck -and -not $pluginsCheck.Passed) {
        Write-MDWResult -Status "WARN" -Message "WordPress installation not detected."
        return
    }

    Write-MDWResult -Status "OK" -Message "Local development environment ready."
}

function Write-MDWLocalWPDeployResult {
    [CmdletBinding()]
    param(
        [object] $Result
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "LocalWP Deploy"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $Result.PluginSlug

    Write-MDWSection -Title "Source"
    Write-MDWInfoCard -Label "Path" -Value $Result.SourcePath

    Write-MDWSection -Title "Target"
    Write-MDWInfoCard -Label "Path" -Value $Result.TargetPath

    if ($Result.Passed) {
        Write-MDWResult -Status "OK" -Message "Plugin deployed to LocalWP."
        return
    }

    Write-MDWSection -Title "Status"

    foreach ($warning in $Result.Warnings) {
        Write-MDWStatus -Status "WARN" -Message $warning
    }

    foreach ($errorItem in $Result.Errors) {
        Write-MDWStatus -Status "FAIL" -Message $errorItem
    }

    Write-MDWResult -Status "FAIL" -Message "Plugin was not deployed to LocalWP."
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

    if ($subCommand -eq "info" -or $subCommand -eq "site") {
        $report = Get-MDWLocalWPReport
        Write-MDWLocalWPEnvironment -Report $report
        return
    }

    if ($subCommand -eq "deploy") {
        $pluginSlug = $null

        if ($Arguments.Count -gt 1) {
            $pluginSlug = $Arguments[1]
        }

        if ([string]::IsNullOrWhiteSpace($pluginSlug)) {
            $currentPath = Get-Location
            $pluginSlug = Split-Path $currentPath -Leaf
        }

        $result = Deploy-MDWPluginToLocalWP -PluginSlug $pluginSlug
        Write-MDWLocalWPDeployResult -Result $result
        return
    }

    throw "Unknown local subcommand: $subCommand. Usage: mdw local [info|site|deploy <plugin-slug>]"
}
