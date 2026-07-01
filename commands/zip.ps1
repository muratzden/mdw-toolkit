<#
MDW ZIP Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

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

    if (-not $pluginSlug) {
        throw "Plugin slug could not be resolved."
    }

    $buildPath = Get-MDWBuildPluginPath -PluginSlug $pluginSlug
    $releasePluginRoot = Get-MDWReleasePluginPath -PluginSlug $pluginSlug
    $zipPath = Join-Path $releasePluginRoot "$pluginSlug.zip"

    if (-not (Test-Path -LiteralPath $buildPath -PathType Container)) {
        throw "Build directory not found. Run first: mdw build $pluginSlug"
    }

    if (-not (Test-Path -LiteralPath $releasePluginRoot)) {
        New-Item -ItemType Directory -Path $releasePluginRoot -Force | Out-Null
    }

    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }

    Write-MDWHeader -Title "ZIP Package" -Subtitle $pluginSlug
    Write-MDWStep -Name "Collecting build output" -Status "INFO"

    $buildItems = Get-ChildItem -LiteralPath $buildPath -Force

    if ($null -eq $buildItems -or $buildItems.Count -eq 0) {
        throw "Build directory is empty: $buildPath"
    }

    $temporaryZipRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("mdw-zip-" + [System.Guid]::NewGuid().ToString("N"))
    $temporaryPluginPath = Join-Path $temporaryZipRoot $pluginSlug

    try {
        New-Item -ItemType Directory -Path $temporaryPluginPath -Force | Out-Null

        foreach ($item in $buildItems) {
            Copy-Item -LiteralPath $item.FullName -Destination $temporaryPluginPath -Recurse -Force
        }

        Write-MDWStep -Name "Creating archive" -Status "INFO"

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

    $zipSize = 0

    if (Test-Path -LiteralPath $zipPath -PathType Leaf) {
        $zipSize = [math]::Round(((Get-Item -LiteralPath $zipPath).Length / 1MB), 2)
    }

    Write-MDWSection -Title "ZIP Output"
    Write-MDWInfoCard -Label "Source" -Value $buildPath
    Write-MDWInfoCard -Label "Destination" -Value $releasePluginRoot
    Write-MDWInfoCard -Label "ZIP file" -Value $zipPath
    Write-MDWInfoCard -Label "Size" -Value ("{0} MB" -f $zipSize)
    Write-MDWStatusLine -Status "OK" -Message "ZIP package created."
    Write-Host ""
}
