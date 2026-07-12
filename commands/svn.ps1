<#
MDW SVN Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Test-MDWSvnCommandFlag {
    [CmdletBinding()]
    param(
        [string[]] $Arguments,
        [string] $Name
    )

    if (-not $Arguments) {
        return $false
    }

    foreach ($argument in $Arguments) {
        if ($argument -eq $Name) {
            return $true
        }
    }

    return $false
}

function Get-MDWSvnCommandArgumentValue {
    [CmdletBinding()]
    param(
        [string[]] $Arguments,
        [string] $Name
    )

    if (-not $Arguments) {
        return $null
    }

    for ($index = 0; $index -lt $Arguments.Count; $index++) {
        if ($Arguments[$index] -eq $Name -and ($index + 1) -lt $Arguments.Count) {
            return $Arguments[$index + 1]
        }
    }

    return $null
}

function Write-MDWSvnStatusReport {
    [CmdletBinding()]
    param(
        [object] $Status
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "WordPress.org SVN"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $Status.WordPressOrg.Name
    Write-MDWInfoCard -Label "Slug" -Value $Status.WordPressOrg.Slug
    Write-MDWInfoCard -Label "SVN URL" -Value $Status.WordPressOrg.SvnUrl
    Write-MDWInfoCard -Label "Working Copy" -Value $Status.WordPressOrg.WorkingCopyPath

    Write-MDWSection -Title "Checks"
    Write-MDWStatus -Status $(if ($Status.SvnInstalled) { "OK" } else { "FAIL" }) -Message "SVN installed"
    Write-MDWStatus -Status $(if ($Status.WordPressOrg.Enabled) { "OK" } else { "WARN" }) -Message "WordPress.org enabled"
    Write-MDWStatus -Status $(if (-not [string]::IsNullOrWhiteSpace($Status.WordPressOrg.SvnUrl)) { "OK" } else { "FAIL" }) -Message "SVN URL configured"
    Write-MDWStatus -Status $(if ($Status.WorkingCopyExists) { "OK" } else { "WARN" }) -Message "Working copy exists"
    Write-MDWStatus -Status $(if ($Status.WorkingCopyValid) { "OK" } else { "WARN" }) -Message "Working copy valid"
    Write-MDWStatus -Status $(if ($Status.TrunkExists) { "OK" } else { "WARN" }) -Message "Trunk exists"
    Write-MDWStatus -Status $(if ($Status.AssetsExists) { "OK" } else { "WARN" }) -Message "Assets exists"
    Write-MDWStatus -Status $(if (-not [string]::IsNullOrWhiteSpace($Status.Metadata.Version)) { "OK" } else { "FAIL" }) -Message ("Current plugin version: {0}" -f $Status.Metadata.Version)
    Write-MDWStatus -Status $(if ($Status.ExpectedTagExists) { "WARN" } else { "OK" }) -Message "Expected tag exists"

    Write-MDWSection -Title "SVN"
    Write-MDWInfoCard -Label "Version" -Value $Status.SvnVersion
    Write-MDWInfoCard -Label "Revision" -Value $Status.Revision
    Write-MDWInfoCard -Label "Local Changes" -Value $Status.LocalChanges.Count

    if ($Status.Passed) {
        Write-MDWResult -Status "OK" -Message "SVN status loaded."
    }
    else {
        Write-MDWResult -Status "WARN" -Message "SVN status loaded with warnings."
    }
}

function Write-MDWSvnPublishReport {
    [CmdletBinding()]
    param(
        [object] $Result
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle $(if ($Result.DryRun) { "WordPress.org Publish Dry Run" } else { "WordPress.org Publish" })

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Plugin" -Value $Result.WordPressOrg.Name
    Write-MDWInfoCard -Label "Slug" -Value $Result.WordPressOrg.Slug
    Write-MDWInfoCard -Label "Version" -Value $Result.Metadata.Version
    Write-MDWInfoCard -Label "SVN URL" -Value $Result.WordPressOrg.SvnUrl
    Write-MDWInfoCard -Label "Working Copy" -Value $Result.WordPressOrg.WorkingCopyPath
    Write-MDWInfoCard -Label "ZIP" -Value $Result.ZipPath

    Write-MDWSection -Title "Pipeline"
    Write-MDWStatus -Status $(if ($null -ne $Result.Build) { "OK" } else { "WARN" }) -Message "Build"
    Write-MDWStatus -Status $(if ($null -ne $Result.Validation -and $Result.Validation.Passed) { "OK" } else { "WARN" }) -Message "Validation"
    Write-MDWStatus -Status $(if (Test-Path -LiteralPath $Result.ZipPath -PathType Leaf) { "OK" } else { "WARN" }) -Message "ZIP"
    Write-MDWStatus -Status $(if ($Result.WorkingCopyValid) { "OK" } else { "WARN" }) -Message "SVN working copy"
    Write-MDWStatus -Status $(if ($null -ne $Result.Trunk -and $Result.Trunk.Passed) { "OK" } else { "WARN" }) -Message "Trunk changes"
    Write-MDWStatus -Status $(if ($null -ne $Result.Assets -and $Result.Assets.Passed) { "OK" } else { "WARN" }) -Message "Assets changes"
    Write-MDWStatus -Status $(if ($null -ne $Result.Tag -and $Result.Tag.Passed) { "OK" } else { "WARN" }) -Message ("Expected tag: {0}" -f $Result.Metadata.StableTag)
    Write-MDWStatus -Status $(if ($Result.DryRun) { "INFO" } elseif ($null -ne $Result.Commit -and $Result.Commit.Passed) { "OK" } else { "WARN" }) -Message "Commit readiness"

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
        Write-MDWResult -Status $(if ($Result.DryRun) { "INFO" } else { "OK" }) -Message $(if ($Result.DryRun) { "Publish dry run completed. No SVN commit was made." } else { "WordPress.org publish completed." })
    }
    else {
        Write-MDWResult -Status "FAIL" -Message "WordPress.org publish is not ready."
    }
}

function Invoke-MDWSvnCommand {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $subCommand = "status"

    if ($Arguments -and $Arguments.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($Arguments[0])) {
        $subCommand = $Arguments[0].ToLowerInvariant()
    }

    $pluginSlug = Get-MDWSvnCommandArgumentValue -Arguments $Arguments -Name "--plugin"
    $dryRun = Test-MDWSvnCommandFlag -Arguments $Arguments -Name "--dry-run"
    $message = Get-MDWSvnCommandArgumentValue -Arguments $Arguments -Name "--message"

    if ($subCommand -eq "status") {
        Write-MDWSvnStatusReport -Status (Get-MDWSvnStatus -PluginSlug $pluginSlug)
        return
    }

    if ($subCommand -eq "checkout") {
        $result = Initialize-MDWSvnWorkingCopy -PluginSlug $pluginSlug
        Write-MDWSvnStatusReport -Status (Get-MDWSvnStatus -PluginSlug $result.WordPressOrg.Slug)
        return
    }

    if ($subCommand -eq "sync") {
        $result = Sync-MDWSvnTrunk -PluginSlug $pluginSlug -DryRun:$dryRun
        Write-MDWHeader -Title "MDW Toolkit" -Subtitle "SVN Trunk Sync"
        Write-MDWInfoCard -Label "Source" -Value $result.Source
        Write-MDWInfoCard -Label "Target" -Value $result.Target

        if ($dryRun) {
            Write-MDWSection -Title "Preview"
            Write-MDWInfoCard -Label "Added" -Value $result.Added.Count
            Write-MDWInfoCard -Label "Updated" -Value $result.Updated.Count
            Write-MDWInfoCard -Label "Deleted" -Value $result.Deleted.Count

            foreach ($path in @($result.Added | Select-Object -First 20)) {
                Write-MDWStatus -Status "INFO" -Message ("Add {0}" -f $path)
            }

            foreach ($path in @($result.Updated | Select-Object -First 20)) {
                Write-MDWStatus -Status "INFO" -Message ("Update {0}" -f $path)
            }

            foreach ($path in @($result.Deleted | Select-Object -First 20)) {
                Write-MDWStatus -Status "INFO" -Message ("Delete {0}" -f $path)
            }
        }

        Write-MDWResult -Status $(if ($result.Passed) { "OK" } else { "FAIL" }) -Message $(if ($dryRun) { "Dry run complete." } else { "Trunk sync complete." })
        return
    }

    if ($subCommand -eq "tag") {
        $result = New-MDWSvnTag -PluginSlug $pluginSlug -DryRun:$dryRun
        Write-MDWHeader -Title "MDW Toolkit" -Subtitle "SVN Tag"
        Write-MDWInfoCard -Label "Version" -Value $result.Version
        Write-MDWInfoCard -Label "Tag" -Value $result.TagPath
        Write-MDWResult -Status $(if ($result.Passed) { "OK" } else { "FAIL" }) -Message $result.Message
        return
    }

    if ($subCommand -eq "publish") {
        Write-MDWSvnPublishReport -Result (Invoke-MDWSvnPublish -PluginSlug $pluginSlug -DryRun:$dryRun -Message $message)
        return
    }

    throw "Unknown svn subcommand: $subCommand. Usage: mdw svn [status|checkout|sync|tag|publish]"
}
