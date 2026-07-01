# MDW Toolkit - Config Core
# PowerShell 5.1 / 7 compatible

Set-StrictMode -Version 2.0

function Get-MDWConfigPath {
    param(
        [string] $ToolkitRoot
    )

    if ([string]::IsNullOrWhiteSpace($ToolkitRoot)) {
        if (Get-Command Get-MDWRootPath -ErrorAction SilentlyContinue) {
            $ToolkitRoot = Get-MDWRootPath
        }
        else {
            $ToolkitRoot = Split-Path -Parent $PSScriptRoot
        }
    }

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

function Get-MDWToolkitMetadata {
    [CmdletBinding()]
    param(
        [object] $Config
    )

    if ($null -eq $Config) {
        $toolkitRoot = $null

        if (Get-Command Get-MDWRootPath -ErrorAction SilentlyContinue) {
            $toolkitRoot = Get-MDWRootPath
        }

        if (-not [string]::IsNullOrWhiteSpace($toolkitRoot)) {
            try {
                $Config = Get-MDWConfig -ToolkitRoot $toolkitRoot
            }
            catch {
                $Config = $null
            }
        }
    }

    $name = Get-MDWConfigValue -Config $Config -Key "toolkit.name" -DefaultValue (Get-MDWConfigValue -Config $Config -Key "name" -DefaultValue "MDW Toolkit")
    $version = Get-MDWConfigValue -Config $Config -Key "toolkit.version" -DefaultValue (Get-MDWConfigValue -Config $Config -Key "version" -DefaultValue "0.1.3-alpha")
    $channel = Get-MDWConfigValue -Config $Config -Key "toolkit.channel" -DefaultValue "Alpha"
    $slogan = Get-MDWConfigValue -Config $Config -Key "toolkit.slogan" -DefaultValue "Build | Validate | Test | Release WordPress Plugins"
    $githubUrl = Get-MDWConfigValue -Config $Config -Key "toolkit.githubUrl" -DefaultValue "https://github.com/muratzden/mdw-toolkit"

    return @{
        Name      = [string] $name
        Version   = [string] $version
        Channel   = [string] $channel
        Slogan    = [string] $slogan
        GitHubUrl = [string] $githubUrl
    }
}

function Get-MDWToolkitVersion {
    [CmdletBinding()]
    param(
        [object] $Config
    )

    return (Get-MDWToolkitMetadata -Config $Config).Version
}

function Get-MDWToolkitName {
    [CmdletBinding()]
    param(
        [object] $Config
    )

    return (Get-MDWToolkitMetadata -Config $Config).Name
}

function Get-MDWToolkitChannel {
    [CmdletBinding()]
    param(
        [object] $Config
    )

    return (Get-MDWToolkitMetadata -Config $Config).Channel
}

function Get-MDWToolkitSlogan {
    [CmdletBinding()]
    param(
        [object] $Config
    )

    return (Get-MDWToolkitMetadata -Config $Config).Slogan
}

function Get-MDWToolkitGitHubUrl {
    [CmdletBinding()]
    param(
        [object] $Config
    )

    return (Get-MDWToolkitMetadata -Config $Config).GitHubUrl
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
    $buildPath = Get-MDWConfigValue -Config $Config -Key "workspace.buildPath"
    $backupPath = Get-MDWConfigValue -Config $Config -Key "workspace.backupPath"
    $releasesPath = Get-MDWConfigValue -Config $Config -Key "workspace.releasePath" -DefaultValue (Get-MDWConfigValue -Config $Config -Key "workspace.releasesPath")

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

    if ([string]::IsNullOrWhiteSpace([string] $buildPath)) {
        throw "MDW config missing required key: workspace.buildPath"
    }

    if ([string]::IsNullOrWhiteSpace([string] $backupPath)) {
        throw "MDW config missing required key: workspace.backupPath"
    }

    if ([string]::IsNullOrWhiteSpace([string] $releasesPath)) {
        throw "MDW config missing required key: workspace.releasesPath"
    }

    return $true
}
