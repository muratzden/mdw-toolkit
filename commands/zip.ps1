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

    $toolkitRoot = Get-MDWRootPath
    $workspaceRoot = Split-Path $toolkitRoot -Parent
    $buildRoot = Join-Path $workspaceRoot "Build"
    $releaseRoot = Join-Path $workspaceRoot "Releases"

    $buildPath = Join-Path $buildRoot $pluginSlug
    $releasePluginRoot = Join-Path $releaseRoot $pluginSlug
    $zipPath = Join-Path $releasePluginRoot "$pluginSlug.zip"

    if (-not (Test-Path $buildPath -PathType Container)) {
        throw "Build directory not found. Run first: mdw build $pluginSlug"
    }

    if (-not (Test-Path $releasePluginRoot)) {
        New-Item -ItemType Directory -Path $releasePluginRoot -Force | Out-Null
    }

    if (Test-Path $zipPath) {
        Remove-Item -Path $zipPath -Force
    }

    Write-Host "[MDW] ZIP started: $pluginSlug" -ForegroundColor Cyan

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

        Compress-Archive `
            -Path $temporaryPluginPath `
            -DestinationPath $zipPath `
            -Force
    }
    finally {
        if (Test-Path $temporaryZipRoot) {
            Remove-Item -Path $temporaryZipRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "[MDW] ZIP: $zipPath"
    Write-Host "[MDW] ZIP completed: $pluginSlug" -ForegroundColor Green
}
