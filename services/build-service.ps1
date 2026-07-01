<#
MDW Build Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWBuildService {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    Write-Host "[MDW] Build started: $PluginSlug" -ForegroundColor Cyan

    $pluginPath = Resolve-MDWPluginPath -PluginSlug $PluginSlug -RequireExisting

    $toolkitRoot = Get-MDWRootPath
    $buildRoot = Join-Path $toolkitRoot "build"
    $targetPath = Join-Path $buildRoot $PluginSlug

    if (Test-Path $targetPath) {
        Remove-Item -Path $targetPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

    Get-ChildItem -Path $pluginPath -Force | Where-Object {
        $_.Name -notin @(
            ".git",
            ".github",
            "node_modules",
            "vendor",
            "build",
            "dist",
            ".DS_Store"
        )
    } | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $targetPath -Recurse -Force
    }

    Write-Host "[MDW] Source: $pluginPath"
    Write-Host "[MDW] Build:  $targetPath"
    Write-Host "[MDW] Build completed: $PluginSlug" -ForegroundColor Green
}
