param(
    [Parameter(Mandatory = $false)]
    [switch] $Force
)

$ErrorActionPreference = "Stop"

function Write-MdwSetupLog {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string] $Level = "INFO"
    )

    $line = "[$Level] $Message"

    switch ($Level) {
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "WARN" { Write-Host $line -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line -ForegroundColor Cyan }
    }
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path
    )

    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-MdwSetupLog "Directory created: $Path" "SUCCESS"
    }
}

function Write-ToolkitFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Content,

        [Parameter(Mandatory = $false)]
        [switch] $Force
    )

    if ((Test-Path $Path) -and (-not $Force)) {
        Write-MdwSetupLog "Skipped existing file: $Path" "WARN"
        return
    }

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-MdwSetupLog "File written: $Path" "SUCCESS"
}

$toolkitRoot = "C:\Workspace\mdw-toolkit"
$scriptsPath = Join-Path $toolkitRoot "scripts"
$corePath = Join-Path $scriptsPath "core"

Ensure-Directory $toolkitRoot
Ensure-Directory $scriptsPath
Ensure-Directory $corePath

$coreContent = @'
Set-StrictMode -Version 2.0

$script:MdwCoreDirectory = Split-Path -Parent $PSCommandPath
$script:MdwScriptsDirectory = Split-Path -Parent $script:MdwCoreDirectory
$script:MdwToolkitRoot = Split-Path -Parent $script:MdwScriptsDirectory

function Get-MdwRoot {
    $configPath = Join-Path $script:MdwToolkitRoot "mdw.json"

    if (-not (Test-Path $configPath)) {
        throw "MDW root bulunamadı. Beklenen dosya yok: $configPath"
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
        throw "mdw.json okunamadı veya geçersiz JSON: $($_.Exception.Message)"
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

    throw "mdw.json içinde '$Name' tanımlı değil."
}

function Assert-MdwDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    if (-not (Test-Path $Path)) {
        throw "$Name bulunamadı: $Path"
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

    throw "Plugin ana PHP dosyası bulunamadı: $PluginPath"
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

    throw "Plugin Version bilgisi bulunamadı: $mainFile"
}

function Invoke-MdwCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command,

        [Parameter(Mandatory = $true)]
        [string] $WorkingDirectory
    )

    Write-MdwLog -Message "Komut çalıştırılıyor: $Command" -Level "INFO"

    Push-Location $WorkingDirectory

    try {
        cmd.exe /c $Command

        if ($LASTEXITCODE -ne 0) {
            throw "Komut başarısız oldu. Exit code: $LASTEXITCODE"
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
        throw "Boş path silinemez."
    }

    if ($Path.Length -lt 10) {
        throw "Güvensiz silme path'i engellendi: $Path"
    }

    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
    }
}
'@

$cleanContent = @'
param(
    [Parameter(Mandatory = $true)]
    [string] $PluginSlug
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\core\Mdw.Core.ps1"

try {
    $pluginPath = Get-MdwPluginPath -PluginSlug $PluginSlug

    Write-MdwLog -Message "Temizlik başladı: $PluginSlug" -Level "INFO"

    $targets = @(
        ".DS_Store",
        "Thumbs.db",
        "*.log",
        "*.tmp",
        "*.bak",
        "node_modules",
        ".phpunit.result.cache",
        ".wordpress-org",
        ".dist",
        "dist",
        "build"
    )

    foreach ($target in $targets) {
        Get-ChildItem -Path $pluginPath -Recurse -Force -Filter $target -ErrorAction SilentlyContinue |
            ForEach-Object {
                if ($_.PSIsContainer) {
                    Remove-MdwDirectorySafe -Path $_.FullName
                }
                else {
                    Remove-Item -Path $_.FullName -Force
                }
            }
    }

    Write-MdwLog -Message "Temizlik tamamlandı: $PluginSlug" -Level "SUCCESS"
}
catch {
    Write-MdwLog -Message $_.Exception.Message -Level "ERROR"
    exit 1
}
'@

$backupContent = @'
param(
    [Parameter(Mandatory = $true)]
    [string] $PluginSlug
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\core\Mdw.Core.ps1"

try {
    $config = Get-MdwConfig
    $pluginPath = Get-MdwPluginPath -PluginSlug $PluginSlug
    $backupPath = Get-MdwConfigValue -Config $config -Name "backupPath"

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $backupPath $PluginSlug
    $targetPath = Join-Path $backupRoot $timestamp

    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

    Write-MdwLog -Message "Yedekleme başladı: $PluginSlug" -Level "INFO"

    robocopy $pluginPath $targetPath /MIR /XD ".git" "node_modules" "vendor" "dist" "build" /XF "*.log" | Out-Null

    if ($LASTEXITCODE -gt 7) {
        throw "Robocopy başarısız oldu. Exit code: $LASTEXITCODE"
    }

    Write-MdwLog -Message "Yedekleme tamamlandı: $targetPath" -Level "SUCCESS"
}
catch {
    Write-MdwLog -Message $_.Exception.Message -Level "ERROR"
    exit 1
}
'@

$zipContent = @'
param(
    [Parameter(Mandatory = $true)]
    [string] $PluginSlug
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\core\Mdw.Core.ps1"

try {
    $config = Get-MdwConfig
    $pluginPath = Get-MdwPluginPath -PluginSlug $PluginSlug
    $version = Get-MdwPluginVersion -PluginPath $pluginPath
    $releasesPath = Get-MdwConfigValue -Config $config -Name "releasesPath"

    $releaseDir = Join-Path $releasesPath $PluginSlug
    $stageRoot = Join-Path $env:TEMP "mdw-build"
    $stagePath = Join-Path $stageRoot $PluginSlug
    $zipPath = Join-Path $releaseDir "$PluginSlug-$version.zip"

    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
    Remove-MdwDirectorySafe -Path $stagePath
    New-Item -ItemType Directory -Path $stagePath -Force | Out-Null

    Write-MdwLog -Message "ZIP hazırlığı başladı: $PluginSlug v$version" -Level "INFO"

    robocopy $pluginPath $stagePath /MIR /XD ".git" ".github" "node_modules" "tests" "dist" "build" /XF ".gitignore" ".gitattributes" "*.log" "*.tmp" "*.bak" | Out-Null

    if ($LASTEXITCODE -gt 7) {
        throw "Robocopy başarısız oldu. Exit code: $LASTEXITCODE"
    }

    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    Compress-Archive -Path $stagePath -DestinationPath $zipPath -Force

    Write-MdwLog -Message "ZIP oluşturuldu: $zipPath" -Level "SUCCESS"
}
catch {
    Write-MdwLog -Message $_.Exception.Message -Level "ERROR"
    exit 1
}
'@

$pluginCheckContent = @'
param(
    [Parameter(Mandatory = $true)]
    [string] $PluginSlug
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\core\Mdw.Core.ps1"

try {
    $pluginPath = Get-MdwPluginPath -PluginSlug $PluginSlug

    Write-MdwLog -Message "Plugin kontrolü başladı: $PluginSlug" -Level "INFO"

    $requiredFiles = @(
        "readme.txt",
        "uninstall.php"
    )

    foreach ($file in $requiredFiles) {
        $path = Join-Path $pluginPath $file

        if (-not (Test-Path $path)) {
            throw "Eksik zorunlu dosya: $file"
        }
    }

    $mainFile = Get-MdwPluginMainFile -PluginPath $pluginPath
    $version = Get-MdwPluginVersion -PluginPath $pluginPath
    $readmePath = Join-Path $pluginPath "readme.txt"
    $readme = Get-Content $readmePath -Raw -Encoding UTF8

    if ($readme -notmatch "Stable tag:\s*$version") {
        throw "readme.txt Stable tag ile plugin Version eşleşmiyor. Version: $version"
    }

    $forbiddenPatterns = @(
        "var_dump\s*\(",
        "print_r\s*\(",
        "console\.log\s*\(",
        "die\s*\(",
        "exit\s*\("
    )

    $sourceFiles = Get-ChildItem -Path $pluginPath -Recurse -Include "*.php", "*.js" -File |
        Where-Object { $_.FullName -notmatch "\\vendor\\|\\node_modules\\" }

    foreach ($file in $sourceFiles) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8

        foreach ($pattern in $forbiddenPatterns) {
            if ($content -match $pattern) {
                throw "Yasak/debug kalıntısı bulundu: $($file.FullName) Pattern: $pattern"
            }
        }
    }

    Write-MdwLog -Message "Plugin kontrolü başarılı: $PluginSlug" -Level "SUCCESS"
}
catch {
    Write-MdwLog -Message $_.Exception.Message -Level "ERROR"
    exit 1
}
'@

$buildContent = @'
param(
    [Parameter(Mandatory = $true)]
    [string] $PluginSlug
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\core\Mdw.Core.ps1"

try {
    $pluginPath = Get-MdwPluginPath -PluginSlug $PluginSlug

    Write-MdwLog -Message "Build başladı: $PluginSlug" -Level "INFO"

    & "$PSScriptRoot\clean.ps1" -PluginSlug $PluginSlug

    if (Test-Path (Join-Path $pluginPath "composer.json")) {
        Invoke-MdwCommand -Command "composer install --no-dev --optimize-autoloader" -WorkingDirectory $pluginPath
    }

    if (Test-Path (Join-Path $pluginPath "package.json")) {
        Invoke-MdwCommand -Command "npm install" -WorkingDirectory $pluginPath
        Invoke-MdwCommand -Command "npm run build" -WorkingDirectory $pluginPath
    }

    & "$PSScriptRoot\plugin-check.ps1" -PluginSlug $PluginSlug
    & "$PSScriptRoot\zip.ps1" -PluginSlug $PluginSlug

    Write-MdwLog -Message "Build tamamlandı: $PluginSlug" -Level "SUCCESS"
}
catch {
    Write-MdwLog -Message $_.Exception.Message -Level "ERROR"
    exit 1
}
'@

$releaseContent = @'
param(
    [Parameter(Mandatory = $true)]
    [string] $PluginSlug
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\core\Mdw.Core.ps1"

try {
    $pluginPath = Get-MdwPluginPath -PluginSlug $PluginSlug
    $version = Get-MdwPluginVersion -PluginPath $pluginPath

    Write-MdwLog -Message "Release başladı: $PluginSlug v$version" -Level "INFO"

    $status = git -C $pluginPath status --short

    if ($status) {
        throw "Git working tree temiz değil. Önce commit veya stash yap."
    }

    & "$PSScriptRoot\backup.ps1" -PluginSlug $PluginSlug
    & "$PSScriptRoot\build.ps1" -PluginSlug $PluginSlug

    $tagName = "v$version"
    $existingTag = git -C $pluginPath tag --list $tagName

    if (-not $existingTag) {
        Invoke-MdwCommand -Command "git tag $tagName" -WorkingDirectory $pluginPath
        Write-MdwLog -Message "Git tag oluşturuldu: $tagName" -Level "SUCCESS"
    }
    else {
        Write-MdwLog -Message "Git tag zaten var: $tagName" -Level "WARN"
    }

    Write-MdwLog -Message "Release tamamlandı: $PluginSlug v$version" -Level "SUCCESS"
}
catch {
    Write-MdwLog -Message $_.Exception.Message -Level "ERROR"
    exit 1
}
'@

Write-ToolkitFile -Path (Join-Path $corePath "Mdw.Core.ps1") -Content $coreContent -Force:$Force
Write-ToolkitFile -Path (Join-Path $scriptsPath "clean.ps1") -Content $cleanContent -Force:$Force
Write-ToolkitFile -Path (Join-Path $scriptsPath "backup.ps1") -Content $backupContent -Force:$Force
Write-ToolkitFile -Path (Join-Path $scriptsPath "zip.ps1") -Content $zipContent -Force:$Force
Write-ToolkitFile -Path (Join-Path $scriptsPath "plugin-check.ps1") -Content $pluginCheckContent -Force:$Force
Write-ToolkitFile -Path (Join-Path $scriptsPath "build.ps1") -Content $buildContent -Force:$Force
Write-ToolkitFile -Path (Join-Path $scriptsPath "release.ps1") -Content $releaseContent -Force:$Force

Write-MdwSetupLog "MDW command scripts generated successfully." "SUCCESS"