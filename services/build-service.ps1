<#
MDW Build Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Test-MDWBuildExcludedName {
    [CmdletBinding()]
    param(
        [string] $Name
    )

    $excludedNames = @(
        ".git",
        ".github",
        ".gitignore",
        ".gitattributes",
        ".vscode",
        ".idea",
        "node_modules",
        "vendor",
        "build",
        "dist",
        "releases",
        "logs",
        "tests",
        "docs",
        ".DS_Store",
        "Thumbs.db",
        "Desktop.ini",
        "PROJECT.md",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "ROADMAP.md"
    )

    return $Name -in $excludedNames
}

function Copy-MDWBuildProductionContent {
    [CmdletBinding()]
    param(
        [string] $SourcePath,
        [string] $TargetPath
    )

    Get-ChildItem -LiteralPath $SourcePath -Force | ForEach-Object {
        if (-not (Test-MDWBuildExcludedName -Name $_.Name)) {
            $destinationPath = Join-Path $TargetPath $_.Name

            if ($_.PSIsContainer) {
                New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                Copy-MDWBuildProductionContent -SourcePath $_.FullName -TargetPath $destinationPath
            }
            else {
                Copy-Item -LiteralPath $_.FullName -Destination $destinationPath -Force
            }
        }
    }
}

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
    $buildRoot = Join-Path (Split-Path $toolkitRoot -Parent) "Build"
    $targetPath = Join-Path $buildRoot $PluginSlug
    $legacyTargetPath = Join-Path (Join-Path $toolkitRoot "build") $PluginSlug

    if (Test-Path $targetPath) {
        Remove-Item -Path $targetPath -Recurse -Force
    }

    if (Test-Path $legacyTargetPath) {
        Remove-Item -Path $legacyTargetPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

    Copy-MDWBuildProductionContent -SourcePath $pluginPath -TargetPath $targetPath

    Write-Host "[MDW] Source: $pluginPath"
    Write-Host "[MDW] Build:  $targetPath"
    Write-Host "[MDW] Build completed: $PluginSlug" -ForegroundColor Green
}
