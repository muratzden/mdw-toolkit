<#
MDW Release Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWRelease {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $pluginSlug = $null

    if ($Arguments -and $Arguments.Count -gt 0) {
        $pluginSlug = $Arguments[0]
    }

    if (-not $pluginSlug) {
        $currentPath = Get-Location
        $pluginSlug = Split-Path $currentPath -Leaf
    }

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Release Pipeline"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug

    if ([string]::IsNullOrWhiteSpace($pluginSlug)) {
        Write-MDWResult -Status "FAIL" -Message "Plugin slug could not be resolved."
        return
    }

    $pluginPath = Get-MDWPluginPath -PluginSlug $pluginSlug
    $releasePath = Get-MDWReleasePluginPath -PluginSlug $pluginSlug
    $zipPath = Join-Path $releasePath "$pluginSlug.zip"

    if (-not (Test-Path -LiteralPath $pluginPath -PathType Container)) {
        Write-MDWResult -Status "FAIL" -Message "Plugin not found."
        return
    }

    Write-MDWSection -Title "Pipeline"
    Write-MDWStatus -Status "INFO" -Message "Backup"
    Write-MDWStatus -Status "INFO" -Message "Build"
    Write-MDWStatus -Status "INFO" -Message "Validate"
    Write-MDWStatus -Status "INFO" -Message "ZIP"
    Write-MDWStatus -Status "INFO" -Message "Release Complete"

    try {
        Write-MDWBlank
        Write-MDWStatus -Status "INFO" -Message "Run backup"
        Invoke-MDWBackup -Arguments @($pluginSlug)

        Write-MDWBlank
        Write-MDWStatus -Status "INFO" -Message "Run build"
        Invoke-MDWBuild -Arguments @($pluginSlug)

        $buildPath = Get-MDWBuildPluginPath -PluginSlug $pluginSlug
        if (-not (Test-Path -LiteralPath $buildPath -PathType Container)) {
            Write-MDWResult -Status "FAIL" -Message "Build output was not created."
            return
        }

        Write-MDWBlank
        Write-MDWStatus -Status "INFO" -Message "Run validate"
        $validateResult = Invoke-MDWValidateService -ToolkitRoot (Get-MDWToolkitPath) -PluginSlug $pluginSlug

        if (-not $validateResult.Passed) {
            Write-MDWSection -Title "Validate"
            foreach ($errorItem in $validateResult.Errors) {
                Write-MDWStatus -Status "FAIL" -Message $errorItem
            }
            Write-MDWResult -Status "FAIL" -Message "Release stopped because validation failed."
            return
        }

        Write-MDWStatus -Status "OK" -Message "Validate passed"

        Write-MDWBlank
        Write-MDWStatus -Status "INFO" -Message "Run ZIP"
        Invoke-MDWZip -Arguments @($pluginSlug)

        if (-not (Test-Path -LiteralPath $zipPath -PathType Leaf)) {
            Write-MDWResult -Status "FAIL" -Message "Release package could not be created."
            return
        }

        Write-MDWSection -Title "Output"
        Write-MDWInfoCard -Label "Release ZIP" -Value $zipPath

        Write-MDWResult -Status "OK" -Message "Release completed successfully."
    }
    catch {
        Write-MDWResult -Status "FAIL" -Message $_.Exception.Message
    }
}
