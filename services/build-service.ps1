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
        "ROADMAP.md",
        "new-command.ps1",
        "Mdw.Core.ps1"
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

    $pluginPath = Resolve-MDWPluginPath -PluginSlug $PluginSlug -RequireExisting
    $targetPath = Get-MDWBuildPluginPath -PluginSlug $PluginSlug
    $toolkitRoot = Get-MDWToolkitPath
    $legacyTargetPath = Join-Path (Join-Path $toolkitRoot "build") $PluginSlug

    if (Test-Path -LiteralPath $targetPath) {
        Remove-Item -LiteralPath $targetPath -Recurse -Force
    }

    if (Test-Path -LiteralPath $legacyTargetPath) {
        Remove-Item -LiteralPath $legacyTargetPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

    Copy-MDWBuildProductionContent -SourcePath $pluginPath -TargetPath $targetPath

    return @{
        Passed     = $true
        PluginSlug = $PluginSlug
        SourcePath = $pluginPath
        BuildPath  = $targetPath
    }
}
