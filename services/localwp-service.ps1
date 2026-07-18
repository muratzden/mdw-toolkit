<#
MDW LocalWP Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWLocalWPConfig {
    [CmdletBinding()]
    param()

    $config = Get-MDWConfig -ToolkitRoot (Get-MDWToolkitPath)
    $defaultRoot = Join-Path $env:USERPROFILE "Local Sites"

    $enabled = Get-MDWConfigValue -Config $config -Key "localwp.enabled" -DefaultValue $true
    $rootPath = Get-MDWConfigValue -Config $config -Key "localwp.rootPath" -DefaultValue $defaultRoot
    $defaultSite = Get-MDWConfigValue -Config $config -Key "localwp.defaultSite" -DefaultValue "template-test"
    $pluginsRelativePath = Get-MDWConfigValue -Config $config -Key "localwp.pluginsRelativePath" -DefaultValue (Join-Path (Join-Path (Join-Path "app" "public") "wp-content") "plugins")

    return @{
        Enabled             = [bool] $enabled
        RootPath            = [string] $rootPath
        DefaultSite         = [string] $defaultSite
        PluginsRelativePath = [string] $pluginsRelativePath
    }
}

function Resolve-MDWLocalWPExistingPath {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    if (-not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -LiteralPath $Path)) {
        return (Resolve-Path -LiteralPath $Path).ProviderPath
    }

    return $Path
}

function Get-MDWLocalWPRootPath {
    [CmdletBinding()]
    param()

    $localConfig = Get-MDWLocalWPConfig
    return Resolve-MDWLocalWPExistingPath -Path $localConfig.RootPath
}

function Get-MDWLocalWPSitesPath {
    [CmdletBinding()]
    param()

    return Get-MDWLocalWPRootPath
}

function Get-MDWLocalWPSitePath {
    [CmdletBinding()]
    param(
        [string] $SiteName
    )

    $localConfig = Get-MDWLocalWPConfig

    if ([string]::IsNullOrWhiteSpace($SiteName)) {
        $SiteName = $localConfig.DefaultSite
    }

    if ([string]::IsNullOrWhiteSpace($SiteName)) {
        return $null
    }

    return Resolve-MDWLocalWPExistingPath -Path (Join-Path (Get-MDWLocalWPSitesPath) $SiteName)
}

function Get-MDWLocalWPPluginsPath {
    [CmdletBinding()]
    param(
        [string] $SiteName
    )

    $localConfig = Get-MDWLocalWPConfig
    $sitePath = Get-MDWLocalWPSitePath -SiteName $SiteName

    if ([string]::IsNullOrWhiteSpace($sitePath)) {
        return $null
    }

    return Resolve-MDWLocalWPExistingPath -Path (Join-Path $sitePath $localConfig.PluginsRelativePath)
}

function Test-MDWLocalWPAvailable {
    [CmdletBinding()]
    param()

    $rootPath = Get-MDWLocalWPRootPath
    return (-not [string]::IsNullOrWhiteSpace($rootPath) -and (Test-Path -LiteralPath $rootPath -PathType Container))
}

function Test-MDWLocalWPSiteExists {
    [CmdletBinding()]
    param(
        [string] $SiteName
    )

    $sitePath = Get-MDWLocalWPSitePath -SiteName $SiteName
    return (-not [string]::IsNullOrWhiteSpace($sitePath) -and (Test-Path -LiteralPath $sitePath -PathType Container))
}

function Test-MDWLocalWPExcludedName {
    [CmdletBinding()]
    param(
        [string] $Name
    )

    $excludedNames = @(
        ".git",
        ".github",
        "node_modules",
        "tests",
        ".env",
        ".env.local",
        ".DS_Store",
        "Thumbs.db"
    )

    if ($Name -in $excludedNames) {
        return $true
    }

    if ($Name -like "*.log" -or $Name -like "*.tmp") {
        return $true
    }

    return $false
}

function Copy-MDWLocalWPPluginContent {
    [CmdletBinding()]
    param(
        [string] $SourcePath,
        [string] $TargetPath
    )

    Get-ChildItem -LiteralPath $SourcePath -Force | ForEach-Object {
        if (-not (Test-MDWLocalWPExcludedName -Name $_.Name)) {
            $destinationPath = Join-Path $TargetPath $_.Name

            if ($_.PSIsContainer) {
                New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                Copy-MDWLocalWPPluginContent -SourcePath $_.FullName -TargetPath $destinationPath
            }
            else {
                Copy-Item -LiteralPath $_.FullName -Destination $destinationPath -Force
            }
        }
    }
}

function Test-MDWLocalWPDeploymentTargetSafe {
    [CmdletBinding()]
    param(
        [string] $PluginsPath,
        [string] $TargetPath
    )

    if ([string]::IsNullOrWhiteSpace($PluginsPath) -or [string]::IsNullOrWhiteSpace($TargetPath)) {
        return $false
    }

    if (-not (Test-Path -LiteralPath $PluginsPath -PathType Container)) {
        return $false
    }

    $resolvedPluginsPath = (Resolve-Path -LiteralPath $PluginsPath).ProviderPath.TrimEnd([char[]] @("\", "/"))
    $targetParent = Split-Path $TargetPath -Parent

    if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
        return $false
    }

    $resolvedTargetParent = (Resolve-Path -LiteralPath $targetParent).ProviderPath.TrimEnd([char[]] @("\", "/"))

    return $resolvedTargetParent.Equals($resolvedPluginsPath, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-MDWLocalWPReport {
    [CmdletBinding()]
    param(
        [string] $SiteName
    )

    $localConfig = Get-MDWLocalWPConfig
    $rootPath = Get-MDWLocalWPRootPath
    $sitePath = Get-MDWLocalWPSitePath -SiteName $SiteName
    $pluginsPath = Get-MDWLocalWPPluginsPath -SiteName $SiteName
    $checks = New-Object System.Collections.Generic.List[object]

    if (Test-Path -LiteralPath $rootPath -PathType Container) {
        $checks.Add(@{ Name = "LocalWP root"; Passed = $true; Status = "OK"; Message = "LocalWP root found" })
    }
    else {
        $checks.Add(@{ Name = "LocalWP root"; Passed = $false; Status = "WARN"; Message = "LocalWP root not found" })
    }

    if (Test-Path -LiteralPath $sitePath -PathType Container) {
        $checks.Add(@{ Name = "Default site"; Passed = $true; Status = "OK"; Message = "Default site found" })
    }
    else {
        $checks.Add(@{ Name = "Default site"; Passed = $false; Status = "WARN"; Message = "Default site not found" })
    }

    if (Test-Path -LiteralPath $pluginsPath -PathType Container) {
        $checks.Add(@{ Name = "Plugins directory"; Passed = $true; Status = "OK"; Message = "Plugins directory found" })
    }
    else {
        $checks.Add(@{ Name = "Plugins directory"; Passed = $false; Status = "WARN"; Message = "Plugins directory not found" })
    }

    $ready = $true

    foreach ($check in $checks) {
        if (-not $check.Passed) {
            $ready = $false
        }
    }

    return @{
        Enabled             = $localConfig.Enabled
        RootPath            = $rootPath
        SitesPath           = Get-MDWLocalWPSitesPath
        DefaultSite         = $localConfig.DefaultSite
        SitePath            = $sitePath
        PluginsPath         = $pluginsPath
        PluginsRelativePath = $localConfig.PluginsRelativePath
        Ready               = $ready
        Status              = if ($ready) { "Ready" } else { "Not ready" }
        Checks              = @($checks.ToArray())
    }
}

function Deploy-MDWPluginToLocalWP {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $SiteName
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        $errors.Add("Plugin slug could not be resolved.")
    }

    $sourcePath = $null

    if ($errors.Count -eq 0) {
        $sourcePath = Resolve-MDWPluginPath -PluginSlug $PluginSlug -RequireExisting

        if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
            $errors.Add("Source plugin directory not found: $sourcePath")
        }
    }

    $report = Get-MDWLocalWPReport -SiteName $SiteName

    if (-not $report.Enabled) {
        $warnings.Add("LocalWP integration is disabled in mdw.json.")
    }

    if (-not (Test-Path -LiteralPath $report.SitePath -PathType Container)) {
        $errors.Add("LocalWP site not found: $($report.SitePath)")
    }

    if (-not (Test-Path -LiteralPath $report.PluginsPath -PathType Container)) {
        $errors.Add("LocalWP plugins directory not found: $($report.PluginsPath)")
    }

    $targetPath = $null

    if ($errors.Count -eq 0) {
        $targetPath = Join-Path $report.PluginsPath $PluginSlug

        if (-not (Test-MDWLocalWPDeploymentTargetSafe -PluginsPath $report.PluginsPath -TargetPath $targetPath)) {
            $errors.Add("Unsafe LocalWP deployment target: $targetPath")
        }
    }

    if ($errors.Count -eq 0) {
        try {
            if (Test-Path -LiteralPath $targetPath -PathType Container) {
                Remove-Item -LiteralPath $targetPath -Recurse -Force
            }

            New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
            Copy-MDWLocalWPPluginContent -SourcePath $sourcePath -TargetPath $targetPath
        }
        catch {
            $errors.Add("LocalWP deploy failed. $($_.Exception.Message)")
        }
    }

    return @{
        Passed     = ($errors.Count -eq 0)
        Errors     = @($errors.ToArray())
        Warnings   = @($warnings.ToArray())
        PluginSlug = $PluginSlug
        SourcePath = $sourcePath
        TargetPath = $targetPath
        LocalWP    = $report
    }
}
