<#
MDW Workspace Path Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWPathConfig {
    [CmdletBinding()]
    param()

    return Get-MDWConfig -ToolkitRoot (Get-MDWRootPath)
}

function Get-MDWRequiredPathConfigValue {
    [CmdletBinding()]
    param(
        [object] $Config,
        [string[]] $Keys,
        [string] $Name
    )

    foreach ($key in $Keys) {
        $value = Get-MDWConfigValue -Config $Config -Key $key -DefaultValue $null

        if (-not [string]::IsNullOrWhiteSpace([string] $value)) {
            return [string] $value
        }
    }

    throw "MDW config missing required path: $Name"
}

function Get-MDWToolkitPath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    $toolkitPath = Get-MDWConfigValue -Config $config -Key "toolkitPath" -DefaultValue $null

    if ([string]::IsNullOrWhiteSpace([string] $toolkitPath)) {
        $toolkitPath = Get-MDWRootPath
    }

    if (Test-Path -LiteralPath $toolkitPath -PathType Container) {
        return (Resolve-Path -LiteralPath $toolkitPath).ProviderPath
    }

    return [string] $toolkitPath
}

function Get-MDWWorkspacePath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    $workspacePath = Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.workspaceRoot", "workspace.rootPath", "Workspace") -Name "workspace root"

    if (Test-Path -LiteralPath $workspacePath -PathType Container) {
        return (Resolve-Path -LiteralPath $workspacePath).ProviderPath
    }

    return $workspacePath
}

function Get-MDWPluginsPath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    return Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.pluginsPath", "Plugins") -Name "plugins path"
}

function Get-MDWBuildPath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    return Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.buildPath", "Build") -Name "build path"
}

function Get-MDWReleasePath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    return Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.releasePath", "workspace.releasesPath", "Releases") -Name "release path"
}

function Get-MDWBackupPath {
    [CmdletBinding()]
    param()

    $config = Get-MDWPathConfig
    return Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.backupPath", "Backup") -Name "backup path"
}

function Test-MDWSvnPluginSlug {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        return $true
    }

    $trimmedSlug = $PluginSlug.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmedSlug)) {
        return $true
    }

    if ($trimmedSlug -eq ".." -or $trimmedSlug.Contains("..")) {
        return $false
    }

    if ($trimmedSlug.Contains("/") -or $trimmedSlug.Contains("\")) {
        return $false
    }

    if ($trimmedSlug -match "^[A-Za-z]:") {
        return $false
    }

    if ([System.IO.Path]::IsPathRooted($trimmedSlug)) {
        return $false
    }

    return $true
}

function Get-MDWSvnPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    $config = Get-MDWPathConfig
    $svnPath = Get-MDWRequiredPathConfigValue -Config $config -Keys @("workspace.svnPath", "SVN") -Name "SVN root path"

    if (-not [System.IO.Path]::IsPathRooted($svnPath)) {
        throw "MDW config path must be absolute: SVN root path"
    }

    $normalizedSvnPath = [System.IO.Path]::GetFullPath($svnPath).TrimEnd([char[]] @("\", "/"))

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        return $normalizedSvnPath
    }

    $trimmedSlug = $PluginSlug.Trim()

    if (-not (Test-MDWSvnPluginSlug -PluginSlug $trimmedSlug)) {
        throw "Invalid plugin slug for SVN path: $PluginSlug"
    }

    if ([string]::IsNullOrWhiteSpace($trimmedSlug)) {
        return $normalizedSvnPath
    }

    $pluginSvnPath = Join-Path $normalizedSvnPath $trimmedSlug
    $normalizedPluginSvnPath = [System.IO.Path]::GetFullPath($pluginSvnPath).TrimEnd([char[]] @("\", "/"))
    $svnRootPrefix = $normalizedSvnPath + [System.IO.Path]::DirectorySeparatorChar

    if (-not $normalizedPluginSvnPath.StartsWith($svnRootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Invalid plugin slug for SVN path: $PluginSlug"
    }

    return $normalizedPluginSvnPath
}

function Get-MDWPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    return Join-Path (Get-MDWPluginsPath) $PluginSlug
}

function Get-MDWBuildPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    return Join-Path (Get-MDWBuildPath) $PluginSlug
}

function Get-MDWReleasePluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    return Join-Path (Get-MDWReleasePath) $PluginSlug
}

function Get-MDWBackupPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    return Join-Path (Get-MDWBackupPath) $PluginSlug
}

function Get-MDWPluginsRootPath {
    [CmdletBinding()]
    param()

    return Get-MDWPluginsPath
}

function Test-MDWPluginPathHasMainFile {
    [CmdletBinding()]
    param(
        [string] $PluginPath
    )

    if ([string]::IsNullOrWhiteSpace($PluginPath) -or -not (Test-Path -LiteralPath $PluginPath -PathType Container)) {
        return $false
    }

    $phpFiles = @(Get-ChildItem -LiteralPath $PluginPath -Filter "*.php" -File -ErrorAction SilentlyContinue)

    foreach ($phpFile in $phpFiles) {
        $content = Get-Content -LiteralPath $phpFile.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -match "(?mi)^\s*(?:\*\s*)?Plugin Name\s*:") {
            return $true
        }
    }

    return $false
}

function Resolve-MDWNestPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    if (Test-MDWPluginPathHasMainFile -PluginPath $PluginPath) {
        return $PluginPath
    }

    $preferredNestedPath = Join-Path $PluginPath $PluginSlug

    if (Test-MDWPluginPathHasMainFile -PluginPath $preferredNestedPath) {
        return $preferredNestedPath
    }

    $nestedCandidates = @(
        Get-ChildItem -LiteralPath $PluginPath -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-MDWPluginPathHasMainFile -PluginPath $_.FullName }
    )

    if ($nestedCandidates.Count -eq 1) {
        return $nestedCandidates[0].FullName
    }

    return $PluginPath
}

function Resolve-MDWPluginPath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [switch] $RequireExisting
    )

    $pluginPath = Get-MDWPluginPath -PluginSlug $PluginSlug

    if ($RequireExisting -and -not (Test-Path -LiteralPath $pluginPath -PathType Container)) {
        throw "Plugin directory not found: $pluginPath"
    }

    if (Test-Path -LiteralPath $pluginPath -PathType Container) {
        return Resolve-MDWNestPluginPath -PluginSlug $PluginSlug -PluginPath $pluginPath
    }

    return $pluginPath
}
