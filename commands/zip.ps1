<#
MDW ZIP Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWZipDisplaySize {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return "0 KB"
    }

    $length = (Get-Item -LiteralPath $Path).Length

    if ($length -lt 1MB) {
        return ("{0:N0} KB" -f [math]::Max(1, [math]::Ceiling($length / 1KB)))
    }

    return ("{0:N2} MB" -f ($length / 1MB))
}

function Invoke-MDWZip {
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

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "ZIP Package"

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug

    if ([string]::IsNullOrWhiteSpace($pluginSlug)) {
        Write-MDWResult -Status "FAIL" -Message "Plugin slug could not be resolved."
        return
    }

    $buildPath = Get-MDWBuildPluginPath -PluginSlug $pluginSlug
    $releasePluginRoot = Get-MDWReleasePluginPath -PluginSlug $pluginSlug
    $zipPath = Join-Path $releasePluginRoot "$pluginSlug.zip"

    Write-MDWSection -Title "Steps"
    Write-MDWStatus -Status "INFO" -Message "Validate build directory"

    if (-not (Test-Path -LiteralPath $buildPath -PathType Container)) {
        Write-MDWResult -Status "FAIL" -Message "Build directory not found. Run first: mdw build $pluginSlug"
        return
    }

    $buildItems = @(Get-ChildItem -LiteralPath $buildPath -Force)

    if ($buildItems.Count -eq 0) {
        Write-MDWResult -Status "FAIL" -Message "Build directory is empty: $buildPath"
        return
    }

    Write-MDWStatus -Status "INFO" -Message "Create ZIP package"

    try {
        if (-not (Test-Path -LiteralPath $releasePluginRoot -PathType Container)) {
            New-Item -ItemType Directory -Path $releasePluginRoot -Force | Out-Null
        }

        if (Test-Path -LiteralPath $zipPath -PathType Leaf) {
            Remove-Item -LiteralPath $zipPath -Force
        }

        $temporaryZipRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("mdw-zip-" + [System.Guid]::NewGuid().ToString("N"))
        $temporaryPluginPath = Join-Path $temporaryZipRoot $pluginSlug

        try {
            New-Item -ItemType Directory -Path $temporaryPluginPath -Force | Out-Null

            foreach ($item in $buildItems) {
                Copy-Item -LiteralPath $item.FullName -Destination $temporaryPluginPath -Recurse -Force
            }

            Compress-Archive `
                -Path $temporaryPluginPath `
                -DestinationPath $zipPath `
                -Force
        }
        finally {
            if (Test-Path -LiteralPath $temporaryZipRoot) {
                Remove-Item -LiteralPath $temporaryZipRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Write-MDWStatus -Status "OK" -Message "ZIP package created"

        Write-MDWSection -Title "Output"
        Write-MDWInfoCard -Label "ZIP" -Value $zipPath
        Write-MDWInfoCard -Label "Size" -Value (Get-MDWZipDisplaySize -Path $zipPath)

        Write-MDWResult -Status "OK" -Message "ZIP package created."
    }
    catch {
        Write-MDWResult -Status "FAIL" -Message $_.Exception.Message
    }
}
