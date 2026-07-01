Set-StrictMode -Version 2.0

$script:MdwCoreDirectory = Split-Path -Parent $PSCommandPath
$script:MdwScriptsDirectory = Split-Path -Parent $script:MdwCoreDirectory
$script:MdwToolkitRoot = Split-Path -Parent $script:MdwScriptsDirectory

function Get-MdwRoot {
    $configPath = Join-Path $script:MdwToolkitRoot "mdw.json"

    if (-not (Test-Path $configPath)) {
        throw "MDW root bulunamadÄ±. Beklenen dosya yok: $configPath"
    }

    return $script:MdwToolkitRoot
}

function Get-MdwConfig {
    $root = Get-MdwRoot
    $configPath = Join-Path $root "mdw.json"

    try {
        return Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        throw "mdw.json okunamadÄ± veya geÃ§ersiz JSON: $($_.Exception.Message)"
    }
}

function Write-MdwLog {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string] $Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"

    switch ($Level) {
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "WARN" { Write-Host $line -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line -ForegroundColor Cyan }
    }

    $root = Get-MdwRoot
    $logDir = Join-Path $root "logs"

    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    Add-Content -Path (Join-Path $logDir "mdw.log") -Value $line -Encoding UTF8
}

function Get-MdwConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [object] $Config,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if ($Config.workspace -and $Config.workspace.$Name) {
        return $Config.workspace.$Name
    }

    if ($Config.$Name) {
        return $Config.$Name
    }

    throw "mdw.json iÃ§inde '$Name' tanÄ±mlÄ± deÄŸil."
}

function Assert-MdwDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if (-not (Test-Path $Path)) {
        throw "$Name bulunamadÄ±: $Path"
    }
}

function Get-MdwPluginPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PluginSlug
    )

    $config = Get-MdwConfig
    $pluginsPath = Get-MdwConfigValue -Config $config -Name "pluginsPath"
    $pluginPath = Join-Path $pluginsPath $PluginSlug

    Assert-MdwDirectory -Path $pluginPath -Name "Plugin dizini"

    return $pluginPath
}

function Get-MdwPluginMainFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PluginPath
    )

    $phpFiles = Get-ChildItem -Path $PluginPath -Filter "*.php" -File

    foreach ($file in $phpFiles) {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        if ($content -match "Plugin Name:") {
            return $file.FullName
        }
    }

    throw "Plugin ana PHP dosyasÄ± bulunamadÄ±: $PluginPath"
}

function Get-MdwPluginVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string] $PluginPath
    )

    $mainFile = Get-MdwPluginMainFile -PluginPath $PluginPath
    $content = Get-Content -Path $mainFile -Raw -Encoding UTF8

    if ($content -match "Version:\s*([0-9]+\.[0-9]+\.[0-9]+)") {
        return $matches[1]
    }

    throw "Plugin Version bilgisi bulunamadÄ±: $mainFile"
}

function Invoke-MdwCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command,

        [Parameter(Mandatory = $true)]
        [string] $WorkingDirectory
    )

    Write-MdwLog -Message "Komut Ã§alÄ±ÅŸtÄ±rÄ±lÄ±yor: $Command" -Level "INFO"

    Push-Location $WorkingDirectory

    try {
        cmd.exe /c $Command

        if ($LASTEXITCODE -ne 0) {
            throw "Komut baÅŸarÄ±sÄ±z oldu. Exit code: $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

function Remove-MdwDirectorySafe {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "BoÅŸ path silinemez."
    }

    if ($Path.Length -lt 10) {
        throw "GÃ¼vensiz silme path'i engellendi: $Path"
    }

    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    }
}
