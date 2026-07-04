<#
MDW WordPress Compliance Validator
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function New-MDWComplianceFinding {
    [CmdletBinding()]
    param(
        [string] $Rule,
        [ValidateSet("Info", "Warning", "Error")]
        [string] $Severity,
        [ValidateSet("OK", "WARN", "FAIL", "INFO")]
        [string] $Status,
        [string] $Message,
        [string] $File
    )

    return @{
        Rule     = $Rule
        Severity = $Severity
        Status   = $Status
        Message  = $Message
        File     = $File
    }
}

function Get-MDWComplianceMainPluginFile {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $expectedMainFile = Join-Path $PluginPath ("{0}.php" -f $PluginSlug)

    if (Test-Path -LiteralPath $expectedMainFile -PathType Leaf) {
        return $expectedMainFile
    }

    $phpFiles = @(Get-ChildItem -LiteralPath $PluginPath -Filter "*.php" -File -ErrorAction SilentlyContinue)

    foreach ($file in $phpFiles) {
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -match "(?mi)^\s*(?:\*\s*)?Plugin Name\s*:") {
            return $file.FullName
        }
    }

    return $null
}

function Test-MDWComplianceTextMatch {
    [CmdletBinding()]
    param(
        [string] $Content,
        [string] $Pattern
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $false
    }

    return ($Content -match $Pattern)
}

function Invoke-MDWComplianceValidator {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $findings = New-Object System.Collections.Generic.List[object]

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        $findings.Add((New-MDWComplianceFinding -Rule "Plugin.Slug" -Severity "Error" -Status "FAIL" -Message "Plugin slug could not be resolved." -File $null))
        return @{ Findings = @($findings.ToArray()) }
    }

    if ([string]::IsNullOrWhiteSpace($PluginPath) -or -not (Test-Path -LiteralPath $PluginPath -PathType Container)) {
        $findings.Add((New-MDWComplianceFinding -Rule "Plugin.Path" -Severity "Error" -Status "FAIL" -Message "Plugin directory not found." -File $PluginPath))
        return @{ Findings = @($findings.ToArray()) }
    }

    $findings.Add((New-MDWComplianceFinding -Rule "Plugin.Path" -Severity "Info" -Status "OK" -Message "Plugin directory found." -File $PluginPath))

    $mainFile = Get-MDWComplianceMainPluginFile -PluginSlug $PluginSlug -PluginPath $PluginPath

    if ([string]::IsNullOrWhiteSpace($mainFile)) {
        $findings.Add((New-MDWComplianceFinding -Rule "Plugin.Header" -Severity "Error" -Status "FAIL" -Message "Main plugin file with Plugin Name header was not found." -File $PluginPath))
    }
    else {
        $findings.Add((New-MDWComplianceFinding -Rule "Plugin.Header" -Severity "Info" -Status "OK" -Message "Main plugin file found." -File $mainFile))
        $mainContent = Get-Content -LiteralPath $mainFile -Raw -ErrorAction SilentlyContinue

        foreach ($header in @("Plugin Name", "Description", "Version", "Author", "Text Domain", "Requires at least", "Requires PHP", "License")) {
            $pattern = ("(?mi)^\s*(?:\*\s*)?{0}\s*:" -f [regex]::Escape($header))

            if (Test-MDWComplianceTextMatch -Content $mainContent -Pattern $pattern) {
                $findings.Add((New-MDWComplianceFinding -Rule "Plugin.Header.$header" -Severity "Info" -Status "OK" -Message ("Header exists: {0}" -f $header) -File $mainFile))
            }
            else {
                $findings.Add((New-MDWComplianceFinding -Rule "Plugin.Header.$header" -Severity "Error" -Status "FAIL" -Message ("Missing plugin header: {0}" -f $header) -File $mainFile))
            }
        }

        $textDomainPattern = "(?mi)^\s*(?:\*\s*)?Text Domain\s*:\s*" + [regex]::Escape($PluginSlug) + "\s*$"

        if (Test-MDWComplianceTextMatch -Content $mainContent -Pattern $textDomainPattern) {
            $findings.Add((New-MDWComplianceFinding -Rule "Plugin.TextDomain" -Severity "Info" -Status "OK" -Message "Text Domain matches plugin slug." -File $mainFile))
        }
        else {
            $findings.Add((New-MDWComplianceFinding -Rule "Plugin.TextDomain" -Severity "Warning" -Status "WARN" -Message "Text Domain should match the plugin slug." -File $mainFile))
        }
    }

    $readmePath = Join-Path $PluginPath "readme.txt"

    if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
        $findings.Add((New-MDWComplianceFinding -Rule "Readme.File" -Severity "Warning" -Status "WARN" -Message "readme.txt was not found." -File $readmePath))
    }
    else {
        $findings.Add((New-MDWComplianceFinding -Rule "Readme.File" -Severity "Info" -Status "OK" -Message "readme.txt found." -File $readmePath))
        $readmeContent = Get-Content -LiteralPath $readmePath -Raw -ErrorAction SilentlyContinue

        foreach ($field in @("Stable tag", "Requires at least", "Tested up to", "Requires PHP", "License")) {
            $pattern = ("(?mi)^\s*{0}\s*:" -f [regex]::Escape($field))

            if (Test-MDWComplianceTextMatch -Content $readmeContent -Pattern $pattern) {
                $findings.Add((New-MDWComplianceFinding -Rule "Readme.$field" -Severity "Info" -Status "OK" -Message ("Readme field exists: {0}" -f $field) -File $readmePath))
            }
            else {
                $findings.Add((New-MDWComplianceFinding -Rule "Readme.$field" -Severity "Warning" -Status "WARN" -Message ("Missing readme field: {0}" -f $field) -File $readmePath))
            }
        }
    }

    $forbiddenNames = @(".git", ".github", ".vscode", ".idea", "node_modules", "tests", "composer.lock", "phpunit.xml")

    foreach ($name in $forbiddenNames) {
        $candidate = Join-Path $PluginPath $name

        if (Test-Path -LiteralPath $candidate) {
            $findings.Add((New-MDWComplianceFinding -Rule "Production.ForbiddenFile" -Severity "Warning" -Status "WARN" -Message ("Development artifact found: {0}" -f $name) -File $candidate))
        }
    }

    $zipFiles = @(Get-ChildItem -LiteralPath $PluginPath -Filter "*.zip" -File -Recurse -ErrorAction SilentlyContinue)

    foreach ($zipFile in $zipFiles) {
        $findings.Add((New-MDWComplianceFinding -Rule "Production.ForbiddenZip" -Severity "Warning" -Status "WARN" -Message ("ZIP file should not be inside plugin source: {0}" -f $zipFile.Name) -File $zipFile.FullName))
    }

    return @{ Findings = @($findings.ToArray()) }
}
