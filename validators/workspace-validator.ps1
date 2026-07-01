<#
MDW Workspace Validator
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWWorkspaceCommandInfo {
    [CmdletBinding()]
    param(
        [string] $CommandName,
        [string[]] $VersionArguments
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue

    if ($null -eq $command) {
        return @{
            Available = $false
            Version   = $null
            Path      = $null
        }
    }

    $version = $null

    if ($VersionArguments -and $VersionArguments.Count -gt 0) {
        try {
            $rawVersion = & $CommandName @VersionArguments 2>&1 | Select-Object -First 1

            if ($null -ne $rawVersion) {
                $version = [string] $rawVersion
            }
        }
        catch {
            $version = $null
        }
    }

    return @{
        Available = $true
        Version   = $version
        Path      = $command.Source
    }
}

function Get-MDWWorkspaceGitInfo {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    $result = @{
        Available = $false
        Branch    = $null
        Status    = "Not a git repository"
        Clean     = $false
    }

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $result
    }

    $gitMetadataPath = Join-Path $Path ".git"

    if (-not (Test-Path -LiteralPath $gitMetadataPath)) {
        return $result
    }

    if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
        $result.Status = "Git is not available"
        return $result
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    try {
        $safeDirectoryArgument = "safe.directory=$Path"
        $insideWorkTree = & git -c $safeDirectoryArgument -C $Path rev-parse --is-inside-work-tree 2>$null

        if ($LASTEXITCODE -ne 0 -or $insideWorkTree -ne "true") {
            return $result
        }

        $branch = & git -c $safeDirectoryArgument -C $Path branch --show-current 2>$null
        $status = & git -c $safeDirectoryArgument -C $Path status --porcelain 2>$null

        $result.Available = $true
        $result.Branch = [string] $branch
        $result.Clean = ($null -eq $status -or $status.Count -eq 0)

        if ($result.Clean) {
            $result.Status = "Working Tree Clean"
        }
        else {
            $result.Status = "Working Tree Has Changes"
        }
    }
    catch {
        $result.Status = "Git status unavailable"
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return $result
}

function Get-MDWWorkspacePluginVersion {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug) -or [string]::IsNullOrWhiteSpace($PluginPath)) {
        return $null
    }

    $pluginFile = Join-Path $PluginPath "$PluginSlug.php"

    if (-not (Test-Path -LiteralPath $pluginFile -PathType Leaf)) {
        return $null
    }

    $content = Get-Content -LiteralPath $pluginFile -Raw -ErrorAction SilentlyContinue

    if ($content -match '(?m)^\s*\*\s*Version:\s*(.+?)\s*$') {
        return $matches[1].Trim()
    }

    if ($content -match '(?m)^Version:\s*(.+?)\s*$') {
        return $matches[1].Trim()
    }

    return $null
}

function Get-MDWWorkspacePluginCheckCliInfo {
    [CmdletBinding()]
    param()

    $cliResult = Invoke-MDWPluginCheckCliValidator

    return @{
        Available = $cliResult.Available
        Message   = if ($cliResult.Available) { "Available" } else { "WordPress Plugin Check CLI is not available." }
        Command   = $cliResult.Command
    }
}

function Invoke-MDWWorkspaceValidator {
    [CmdletBinding()]
    param(
        [string] $WorkspacePath,
        [string] $ToolkitRoot,
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ReleasePath,
        [string] $BackupPath
    )

    $php = Get-MDWWorkspaceCommandInfo -CommandName "php" -VersionArguments @("-v")
    $composer = Get-MDWWorkspaceCommandInfo -CommandName "composer" -VersionArguments @("--version")
    $svn = Get-MDWWorkspaceCommandInfo -CommandName "svn" -VersionArguments @("--version", "--quiet")
    $pluginCheck = Get-MDWWorkspacePluginCheckCliInfo
    $git = Get-MDWWorkspaceGitInfo -Path $PluginPath
    $pluginVersion = Get-MDWWorkspacePluginVersion -PluginSlug $PluginSlug -PluginPath $PluginPath

    $releasePackage = $null
    $lastReleaseDate = $null

    if (-not [string]::IsNullOrWhiteSpace($ReleasePath) -and (Test-Path -LiteralPath $ReleasePath -PathType Container)) {
        $latestZip = Get-ChildItem -LiteralPath $ReleasePath -Filter "*.zip" -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($null -ne $latestZip) {
            $releasePackage = $latestZip.Name
            $lastReleaseDate = $latestZip.LastWriteTime
        }
    }

    $backupCount = 0

    if (-not [string]::IsNullOrWhiteSpace($BackupPath) -and (Test-Path -LiteralPath $BackupPath -PathType Container)) {
        $backupCount = @(Get-ChildItem -LiteralPath $BackupPath -Directory -ErrorAction SilentlyContinue).Count
    }

    return @{
        Workspace = @{
            Path           = $WorkspacePath
            ToolkitRoot    = $ToolkitRoot
            ToolkitVersion = "0.1.0"
        }
        Plugin = @{
            Slug    = $PluginSlug
            Path    = $PluginPath
            Version = $pluginVersion
        }
        Git = $git
        Environment = @{
            PHP         = $php
            Composer    = $composer
            SVN         = $svn
            PluginCheck = $pluginCheck
        }
        Release = @{
            Package         = $releasePackage
            LastReleaseDate = $lastReleaseDate
            BackupCount     = $backupCount
            ReleasePath     = $ReleasePath
            BackupPath      = $BackupPath
        }
    }
}
