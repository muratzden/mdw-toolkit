<#
MDW Clean Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWClean {
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

    if (-not $pluginSlug) {
        throw "Plugin slug could not be resolved."
    }

    $toolkitRoot = Get-MDWToolkitPath
    $pluginPath = Resolve-MDWPluginPath -PluginSlug $pluginSlug -RequireExisting
    $buildPath = Get-MDWBuildPluginPath -PluginSlug $pluginSlug
    $releasePath = Get-MDWReleasePluginPath -PluginSlug $pluginSlug
    $legacyBuildPath = Join-Path (Join-Path $toolkitRoot "build") $pluginSlug
    $legacyReleasePath = Join-Path (Join-Path $toolkitRoot "releases") $pluginSlug

    if (-not (Test-Path -LiteralPath $pluginPath -PathType Container)) {
        throw "Plugin directory not found: $pluginPath"
    }

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Clean"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug

    Write-MDWSection -Title "Steps"
    Write-MDWStatus -Status "INFO" -Message "Clean build and release outputs"

    $pathsToClean = @(
        $buildPath,
        $releasePath,
        $legacyBuildPath,
        $legacyReleasePath
    )

    foreach ($path in $pathsToClean) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
            Write-MDWStatus -Status "OK" -Message ("Removed: {0}" -f $path)
        }
    }

    Write-MDWStatus -Status "INFO" -Message "Clean temporary files"

    $temporaryPatterns = @(
        "*.tmp",
        "*.log",
        "*.bak",
        "*.zip"
    )

    $removedTempCount = 0

    foreach ($pattern in $temporaryPatterns) {
        Get-ChildItem -LiteralPath $pluginPath -Filter $pattern -Recurse -Force -ErrorAction SilentlyContinue |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force
                $removedTempCount++
            }
    }

    Write-MDWStatus -Status "OK" -Message ("Temporary files removed: {0}" -f $removedTempCount)

    Write-MDWSection -Title "Output"
    Write-MDWInfoCard -Label "Build" -Value $buildPath
    Write-MDWInfoCard -Label "Release" -Value $releasePath

    Write-MDWResult -Status "OK" -Message "Clean completed."
}
