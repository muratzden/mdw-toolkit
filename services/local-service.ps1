<#
MDW Local Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWLocalToolkitRoot {
    [CmdletBinding()]
    param()

    return (Split-Path -Parent $PSScriptRoot)
}

function Get-MDWLocalToolkitConfig {
    [CmdletBinding()]
    param()

    $toolkitRoot = Get-MDWLocalToolkitRoot
    return Get-MDWConfig -ToolkitRoot $toolkitRoot
}

function Get-MDWLocalConfig {
    [CmdletBinding()]
    param()

    $config = Get-MDWLocalToolkitConfig

    if ($null -eq $config.laragon) {
        throw "Laragon configuration not found in mdw.json."
    }

    return $config.laragon
}

function Test-MDWPathExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    return Test-Path -LiteralPath $Path
}

function Get-MDWLocalReport {
    [CmdletBinding()]
    param()

    $local = Get-MDWLocalConfig
    $wpConfigPath = Join-Path $local.sitePath "wp-config.php"

    $checks = @()

    $checks += [pscustomobject]@{
        Name   = "Laragon root"
        Path   = $local.rootPath
        Passed = Test-MDWPathExists -Path $local.rootPath
    }

    $checks += [pscustomobject]@{
        Name   = "Laragon www"
        Path   = $local.wwwPath
        Passed = Test-MDWPathExists -Path $local.wwwPath
    }

    $checks += [pscustomobject]@{
        Name   = "WordPress site"
        Path   = $local.sitePath
        Passed = Test-MDWPathExists -Path $local.sitePath
    }

    $checks += [pscustomobject]@{
        Name   = "wp-config.php"
        Path   = $wpConfigPath
        Passed = Test-MDWPathExists -Path $wpConfigPath
    }

    $checks += [pscustomobject]@{
        Name   = "Plugins directory"
        Path   = $local.pluginsPath
        Passed = Test-MDWPathExists -Path $local.pluginsPath
    }

    $wpCliDetected = $false

    try {
        $wpVersion = & wp --version 2>$null

        if (-not [string]::IsNullOrWhiteSpace($wpVersion)) {
            $wpCliDetected = $true
        }
    }
    catch {
        $wpCliDetected = $false
    }

    $checks += [pscustomobject]@{
        Name   = "WP-CLI"
        Path   = "wp"
        Passed = $wpCliDetected
    }

    return [pscustomobject]@{
        Provider    = "Laragon"
        RootPath    = $local.rootPath
        SitePath    = $local.sitePath
        PluginsPath = $local.pluginsPath
        SiteUrl     = $local.siteUrl
        AdminUrl    = $local.adminUrl
        Checks      = $checks
    }
}

function Get-MDWLocalPluginStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PluginSlug
    )

    $local = Get-MDWLocalConfig
    $targetPath = Join-Path $local.pluginsPath $PluginSlug

    $exists = Test-Path -LiteralPath $targetPath
    $isJunction = $false

    if ($exists) {
        $item = Get-Item -LiteralPath $targetPath -Force
        $isJunction = (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
    }

    $status = "unknown"

    try {
        Push-Location $local.sitePath
        $rawStatus = & wp plugin status $PluginSlug 2>$null
        Pop-Location

        if ($rawStatus -match "Status:\s+Active") {
            $status = "active"
        }
        elseif ($rawStatus -match "Status:\s+Inactive") {
            $status = "inactive"
        }
    }
    catch {
        try {
            Pop-Location
        }
        catch {}

        $status = "unknown"
    }

    return [pscustomobject]@{
        PluginSlug = $PluginSlug
        TargetPath = $targetPath
        Exists     = $exists
        IsJunction = $isJunction
        Status     = $status
    }
}

function New-MDWLocalPluginLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PluginSlug
    )

    $config = Get-MDWLocalToolkitConfig
    $local = Get-MDWLocalConfig

    $sourcePath = Join-Path $config.workspace.pluginsPath $PluginSlug
    $targetPath = Join-Path $local.pluginsPath $PluginSlug

    $errors = @()
    $warnings = @()

    if (-not (Test-Path -LiteralPath $sourcePath)) {
        $errors += "Plugin source not found: $sourcePath"
    }

    if (-not (Test-Path -LiteralPath $local.pluginsPath)) {
        $errors += "Laragon plugins directory not found: $($local.pluginsPath)"
    }

    if ($errors.Count -gt 0) {
        return [pscustomobject]@{
            Passed     = $false
            PluginSlug = $PluginSlug
            SourcePath = $sourcePath
            TargetPath = $targetPath
            Warnings   = $warnings
            Errors     = $errors
        }
    }

    if (Test-Path -LiteralPath $targetPath) {
        $item = Get-Item -LiteralPath $targetPath -Force

        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            $warnings += "Junction already exists."
        }
        else {
            $errors += "Target path already exists and is not a junction: $targetPath"
        }
    }
    else {
        cmd /c mklink /J "$targetPath" "$sourcePath" | Out-Null
    }

    return [pscustomobject]@{
        Passed     = ($errors.Count -eq 0)
        PluginSlug = $PluginSlug
        SourcePath = $sourcePath
        TargetPath = $targetPath
        Warnings   = $warnings
        Errors     = $errors
    }
}