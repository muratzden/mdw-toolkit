# MDW Toolkit - Config Core
# PowerShell 5.1 / 7 compatible

Set-StrictMode -Version 2.0

function Get-MDWConfigPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ToolkitRoot
    )

    $primaryPath = Join-Path $ToolkitRoot "mdw.json"
    $secondaryPath = Join-Path (Join-Path $ToolkitRoot "config") "mdw.json"

    if (Test-Path -LiteralPath $primaryPath) {
        return $primaryPath
    }

    if (Test-Path -LiteralPath $secondaryPath) {
        return $secondaryPath
    }

    throw "MDW config file not found. Expected: $primaryPath or $secondaryPath"
}

function Get-MDWConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ToolkitRoot
    )

    $configPath = Get-MDWConfigPath -ToolkitRoot $ToolkitRoot
    $rawJson = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8

    if ([string]::IsNullOrWhiteSpace($rawJson)) {
        throw "MDW config file is empty: $configPath"
    }

    try {
        $config = $rawJson | ConvertFrom-Json
    }
    catch {
        throw "Invalid MDW config JSON: $configPath. $($_.Exception.Message)"
    }

    Add-Member -InputObject $config -MemberType NoteProperty -Name "_path" -Value $configPath -Force

    return $config
}

function Get-MDWConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $Key,

        [object] $DefaultValue = $null
    )

    if ($null -eq $Config) {
        return $DefaultValue
    }

    $parts = $Key.Split(".")
    $current = $Config

    foreach ($part in $parts) {
        if ($null -eq $current) {
            return $DefaultValue
        }

        $property = $current.PSObject.Properties[$part]

        if ($null -eq $property) {
            return $DefaultValue
        }

        $current = $property.Value
    }

    return $current
}

function Test-MDWConfig {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config
    )

    if ($null -eq $Config) {
        throw "MDW config is null."
    }

    $name = Get-MDWConfigValue -Config $Config -Key "name"
    $version = Get-MDWConfigValue -Config $Config -Key "version"
    $rootPath = Get-MDWConfigValue -Config $Config -Key "workspace.rootPath"
    $pluginsPath = Get-MDWConfigValue -Config $Config -Key "workspace.pluginsPath"
    $backupPath = Get-MDWConfigValue -Config $Config -Key "workspace.backupPath"
    $releasesPath = Get-MDWConfigValue -Config $Config -Key "workspace.releasesPath"

    if ([string]::IsNullOrWhiteSpace([string] $name)) {
        throw "MDW config missing required key: name"
    }

    if ([string]::IsNullOrWhiteSpace([string] $version)) {
        throw "MDW config missing required key: version"
    }

    if ([string]::IsNullOrWhiteSpace([string] $rootPath)) {
        throw "MDW config missing required key: workspace.rootPath"
    }

    if ([string]::IsNullOrWhiteSpace([string] $pluginsPath)) {
        throw "MDW config missing required key: workspace.pluginsPath"
    }

    if ([string]::IsNullOrWhiteSpace([string] $backupPath)) {
        throw "MDW config missing required key: workspace.backupPath"
    }

    if ([string]::IsNullOrWhiteSpace([string] $releasesPath)) {
        throw "MDW config missing required key: workspace.releasesPath"
    }

    return $true
}