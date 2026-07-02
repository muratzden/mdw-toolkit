<#
MDW Internal Plugin Check Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function New-MDWPluginCheckItem {
    [CmdletBinding()]
    param(
        [string] $Name,
        [string] $Status,
        [string] $Message
    )

    return @{
        Name    = $Name
        Status  = $Status
        Message = $Message
    }
}

function New-MDWPluginCheckSection {
    [CmdletBinding()]
    param(
        [string] $Name,
        [object[]] $Items
    )

    return @{
        Name  = $Name
        Items = @($Items)
    }
}

function Get-MDWPluginMainFilePath {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    return Join-Path $PluginPath "$PluginSlug.php"
}

function Get-MDWPluginFileHeaderValue {
    [CmdletBinding()]
    param(
        [string] $Content,
        [string] $Header
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $null
    }

    $escapedHeader = [regex]::Escape($Header)

    if ($Content -match "(?mi)^\s*(?:\*\s*)?$escapedHeader\s*:\s*(.+?)\s*$") {
        return $matches[1].Trim()
    }

    return $null
}

function Get-MDWReadmeFieldValue {
    [CmdletBinding()]
    param(
        [string] $Content,
        [string] $Field
    )

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $null
    }

    $escapedField = [regex]::Escape($Field)

    if ($Content -match "(?mi)^\s*$escapedField\s*:\s*(.+?)\s*$") {
        return $matches[1].Trim()
    }

    return $null
}

function Test-MDWPluginStructure {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $items = New-Object System.Collections.Generic.List[object]
    $mainFile = Get-MDWPluginMainFilePath -PluginSlug $PluginSlug -PluginPath $PluginPath
    $readmeFile = Join-Path $PluginPath "readme.txt"
    $languagesPath = Join-Path $PluginPath "languages"
    $assetsPath = Join-Path $PluginPath "assets"

    if (Test-Path -LiteralPath $PluginPath -PathType Container) {
        $items.Add((New-MDWPluginCheckItem -Name "Plugin folder" -Status "OK" -Message "Plugin folder found"))
    }
    else {
        $items.Add((New-MDWPluginCheckItem -Name "Plugin folder" -Status "FAIL" -Message "Plugin folder not found: $PluginPath"))
    }

    if (Test-Path -LiteralPath $mainFile -PathType Leaf) {
        $items.Add((New-MDWPluginCheckItem -Name "Main plugin file" -Status "OK" -Message "Main plugin file found"))
    }
    else {
        $items.Add((New-MDWPluginCheckItem -Name "Main plugin file" -Status "FAIL" -Message "Main plugin file not found: $mainFile"))
    }

    if (Test-Path -LiteralPath $readmeFile -PathType Leaf) {
        $items.Add((New-MDWPluginCheckItem -Name "readme.txt" -Status "OK" -Message "readme.txt found"))
    }
    else {
        $items.Add((New-MDWPluginCheckItem -Name "readme.txt" -Status "WARN" -Message "readme.txt not found"))
    }

    if (Test-Path -LiteralPath $languagesPath) {
        if (Test-Path -LiteralPath $languagesPath -PathType Container) {
            $items.Add((New-MDWPluginCheckItem -Name "languages" -Status "OK" -Message "languages directory is in the plugin root"))
        }
        else {
            $items.Add((New-MDWPluginCheckItem -Name "languages" -Status "WARN" -Message "languages exists but is not a directory"))
        }
    }

    if (Test-Path -LiteralPath $assetsPath) {
        if (Test-Path -LiteralPath $assetsPath -PathType Container) {
            $items.Add((New-MDWPluginCheckItem -Name "assets" -Status "OK" -Message "assets directory is in the plugin root"))
        }
        else {
            $items.Add((New-MDWPluginCheckItem -Name "assets" -Status "WARN" -Message "assets exists but is not a directory"))
        }
    }

    return New-MDWPluginCheckSection -Name "Structure" -Items @($items.ToArray())
}

function Test-MDWPluginMainFile {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $mainFile = Get-MDWPluginMainFilePath -PluginSlug $PluginSlug -PluginPath $PluginPath
    $items = @()

    if (Test-Path -LiteralPath $mainFile -PathType Leaf) {
        $items += New-MDWPluginCheckItem -Name "Main plugin file" -Status "OK" -Message $mainFile
    }
    else {
        $items += New-MDWPluginCheckItem -Name "Main plugin file" -Status "FAIL" -Message "Main plugin file not found: $mainFile"
    }

    return New-MDWPluginCheckSection -Name "Main File" -Items $items
}

function Test-MDWPluginHeaders {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $items = New-Object System.Collections.Generic.List[object]
    $mainFile = Get-MDWPluginMainFilePath -PluginSlug $PluginSlug -PluginPath $PluginPath

    if (-not (Test-Path -LiteralPath $mainFile -PathType Leaf)) {
        $items.Add((New-MDWPluginCheckItem -Name "Headers" -Status "FAIL" -Message "Main plugin file not found"))
        return New-MDWPluginCheckSection -Name "Headers" -Items @($items.ToArray())
    }

    $content = Get-Content -LiteralPath $mainFile -Raw -ErrorAction SilentlyContinue
    $requiredHeaders = @("Plugin Name", "Description", "Version", "Author", "Text Domain", "License")
    $blockingHeaders = @("Plugin Name", "Version")

    foreach ($header in $requiredHeaders) {
        $value = Get-MDWPluginFileHeaderValue -Content $content -Header $header

        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $items.Add((New-MDWPluginCheckItem -Name $header -Status "OK" -Message $value))
        }
        elseif ($header -in $blockingHeaders) {
            $items.Add((New-MDWPluginCheckItem -Name $header -Status "FAIL" -Message "Plugin header missing: $header"))
        }
        else {
            $items.Add((New-MDWPluginCheckItem -Name $header -Status "WARN" -Message "Plugin header missing: $header"))
        }
    }

    return New-MDWPluginCheckSection -Name "Headers" -Items @($items.ToArray())
}

function Test-MDWPluginReadme {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $items = New-Object System.Collections.Generic.List[object]
    $readmeFile = Join-Path $PluginPath "readme.txt"

    if (-not (Test-Path -LiteralPath $readmeFile -PathType Leaf)) {
        $items.Add((New-MDWPluginCheckItem -Name "readme.txt" -Status "WARN" -Message "readme.txt not found"))
        return New-MDWPluginCheckSection -Name "Readme" -Items @($items.ToArray())
    }

    $content = Get-Content -LiteralPath $readmeFile -Raw -ErrorAction SilentlyContinue

    if ($content -match '(?m)^\s*===\s*.+?\s*===\s*$') {
        $items.Add((New-MDWPluginCheckItem -Name "Plugin title" -Status "OK" -Message "Plugin title found"))
    }
    else {
        $items.Add((New-MDWPluginCheckItem -Name "Plugin title" -Status "WARN" -Message "readme.txt missing plugin title"))
    }

    foreach ($field in @("Contributors", "Tags", "Requires at least", "Tested up to", "Requires PHP", "Stable tag", "License")) {
        $value = Get-MDWReadmeFieldValue -Content $content -Field $field

        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $items.Add((New-MDWPluginCheckItem -Name $field -Status "OK" -Message $value))
        }
        else {
            $items.Add((New-MDWPluginCheckItem -Name $field -Status "WARN" -Message "readme.txt missing $field."))
        }
    }

    return New-MDWPluginCheckSection -Name "Readme" -Items @($items.ToArray())
}

function Test-MDWPluginTextDomain {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $items = New-Object System.Collections.Generic.List[object]
    $mainFile = Get-MDWPluginMainFilePath -PluginSlug $PluginSlug -PluginPath $PluginPath
    $readmeFile = Join-Path $PluginPath "readme.txt"
    $textDomain = $null

    if (Test-Path -LiteralPath $mainFile -PathType Leaf) {
        $content = Get-Content -LiteralPath $mainFile -Raw -ErrorAction SilentlyContinue
        $textDomain = Get-MDWPluginFileHeaderValue -Content $content -Header "Text Domain"
    }

    if ([string]::IsNullOrWhiteSpace($textDomain)) {
        $items.Add((New-MDWPluginCheckItem -Name "Text Domain" -Status "WARN" -Message "Plugin header missing: Text Domain"))
    }
    elseif ($textDomain -eq $PluginSlug) {
        $items.Add((New-MDWPluginCheckItem -Name "Text Domain" -Status "OK" -Message $textDomain))
    }
    else {
        $items.Add((New-MDWPluginCheckItem -Name "Text Domain" -Status "WARN" -Message "Text Domain '$textDomain' does not match plugin slug '$PluginSlug'."))
    }

    if (Test-Path -LiteralPath $readmeFile -PathType Leaf) {
        $readmeContent = Get-Content -LiteralPath $readmeFile -Raw -ErrorAction SilentlyContinue

        if (-not [string]::IsNullOrWhiteSpace($textDomain) -and $readmeContent -match [regex]::Escape($textDomain)) {
            $items.Add((New-MDWPluginCheckItem -Name "Readme text domain" -Status "OK" -Message "readme.txt references the text domain"))
        }
        else {
            $items.Add((New-MDWPluginCheckItem -Name "Readme text domain" -Status "WARN" -Message "readme.txt does not reference the plugin text domain"))
        }
    }

    return New-MDWPluginCheckSection -Name "Text Domain" -Items @($items.ToArray())
}

function Test-MDWPluginLicense {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $items = New-Object System.Collections.Generic.List[object]
    $mainFile = Get-MDWPluginMainFilePath -PluginSlug $PluginSlug -PluginPath $PluginPath
    $readmeFile = Join-Path $PluginPath "readme.txt"
    $pluginLicense = $null
    $readmeLicense = $null

    if (Test-Path -LiteralPath $mainFile -PathType Leaf) {
        $content = Get-Content -LiteralPath $mainFile -Raw -ErrorAction SilentlyContinue
        $pluginLicense = Get-MDWPluginFileHeaderValue -Content $content -Header "License"
    }

    if (Test-Path -LiteralPath $readmeFile -PathType Leaf) {
        $readmeContent = Get-Content -LiteralPath $readmeFile -Raw -ErrorAction SilentlyContinue
        $readmeLicense = Get-MDWReadmeFieldValue -Content $readmeContent -Field "License"
    }

    if ([string]::IsNullOrWhiteSpace($pluginLicense)) {
        $items.Add((New-MDWPluginCheckItem -Name "Plugin License" -Status "WARN" -Message "Plugin header missing: License"))
    }
    elseif ($pluginLicense -match '(?i)gpl') {
        $items.Add((New-MDWPluginCheckItem -Name "Plugin License" -Status "OK" -Message $pluginLicense))
    }
    else {
        $items.Add((New-MDWPluginCheckItem -Name "Plugin License" -Status "WARN" -Message "Plugin license may not be GPL-compatible: $pluginLicense"))
    }

    if ([string]::IsNullOrWhiteSpace($readmeLicense)) {
        $items.Add((New-MDWPluginCheckItem -Name "Readme License" -Status "WARN" -Message "readme.txt missing License."))
    }
    elseif ($readmeLicense -match '(?i)gpl') {
        $items.Add((New-MDWPluginCheckItem -Name "Readme License" -Status "OK" -Message $readmeLicense))
    }
    else {
        $items.Add((New-MDWPluginCheckItem -Name "Readme License" -Status "WARN" -Message "readme.txt license may not be GPL-compatible: $readmeLicense"))
    }

    if (-not [string]::IsNullOrWhiteSpace($pluginLicense) -and -not [string]::IsNullOrWhiteSpace($readmeLicense)) {
        if ($pluginLicense -eq $readmeLicense) {
            $items.Add((New-MDWPluginCheckItem -Name "License consistency" -Status "OK" -Message "Plugin header and readme license match"))
        }
        else {
            $items.Add((New-MDWPluginCheckItem -Name "License consistency" -Status "WARN" -Message "Plugin header and readme license do not match"))
        }
    }

    return New-MDWPluginCheckSection -Name "License" -Items @($items.ToArray())
}

function Test-MDWPluginAssets {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $items = New-Object System.Collections.Generic.List[object]

    foreach ($directoryName in @("assets", "languages")) {
        $directoryPath = Join-Path $PluginPath $directoryName

        if (Test-Path -LiteralPath $directoryPath) {
            if (Test-Path -LiteralPath $directoryPath -PathType Container) {
                $items.Add((New-MDWPluginCheckItem -Name $directoryName -Status "OK" -Message "$directoryName directory is valid"))
            }
            else {
                $items.Add((New-MDWPluginCheckItem -Name $directoryName -Status "WARN" -Message "$directoryName exists but is not a directory"))
            }
        }
        else {
            $items.Add((New-MDWPluginCheckItem -Name $directoryName -Status "OK" -Message "$directoryName directory is optional"))
        }
    }

    return New-MDWPluginCheckSection -Name "Assets" -Items @($items.ToArray())
}

function Test-MDWPluginForbiddenFiles {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $items = New-Object System.Collections.Generic.List[object]
    $forbiddenNames = @(".git", ".github", "node_modules", "tests", ".DS_Store", "Thumbs.db", ".env", ".env.local", "package-lock.json", "composer.lock")
    $forbiddenPatterns = @("*.log", "*.tmp")
    $forbiddenRelativePaths = @((Join-Path "vendor" "bin"))
    $found = New-Object System.Collections.Generic.List[string]

    if (Test-Path -LiteralPath $PluginPath -PathType Container) {
        Get-ChildItem -LiteralPath $PluginPath -Force -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -in $forbiddenNames) {
                $found.Add($_.FullName.Substring($PluginPath.Length).TrimStart("\", "/"))
            }
            else {
                foreach ($pattern in $forbiddenPatterns) {
                    if ($_.Name -like $pattern) {
                        $found.Add($_.FullName.Substring($PluginPath.Length).TrimStart("\", "/"))
                    }
                }
            }
        }

        foreach ($relativePath in $forbiddenRelativePaths) {
            $path = Join-Path $PluginPath $relativePath

            if (Test-Path -LiteralPath $path) {
                $found.Add($relativePath)
            }
        }
    }

    if ($found.Count -eq 0) {
        $items.Add((New-MDWPluginCheckItem -Name "Forbidden files" -Status "OK" -Message "No forbidden files found"))
    }
    else {
        foreach ($path in ($found | Sort-Object -Unique)) {
            $items.Add((New-MDWPluginCheckItem -Name "Forbidden file" -Status "WARN" -Message $path))
        }
    }

    return New-MDWPluginCheckSection -Name "Forbidden Files" -Items @($items.ToArray())
}

function Get-MDWPluginCheckReport {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [object[]] $Sections
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    foreach ($section in $Sections) {
        foreach ($item in $section.Items) {
            if ($item.Status -eq "FAIL") {
                $errors.Add($item.Message)
            }
            elseif ($item.Status -eq "WARN") {
                $warnings.Add($item.Message)
            }
        }
    }

    return @{
        Passed       = ($errors.Count -eq 0)
        ErrorCount   = $errors.Count
        WarningCount = $warnings.Count
        Errors       = @($errors.ToArray())
        Warnings     = @($warnings.ToArray())
        Sections     = @($Sections)
        PluginSlug   = $PluginSlug
        PluginPath   = $PluginPath
    }
}

function Invoke-MDWPluginCheck {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        $section = New-MDWPluginCheckSection -Name "Structure" -Items @(
            New-MDWPluginCheckItem -Name "Plugin slug" -Status "FAIL" -Message "Plugin slug could not be resolved."
        )

        return Get-MDWPluginCheckReport -PluginSlug $PluginSlug -PluginPath $null -Sections @($section)
    }

    $pluginPath = Resolve-MDWPluginPath -PluginSlug $PluginSlug

    $sections = @(
        Test-MDWPluginStructure -PluginSlug $PluginSlug -PluginPath $pluginPath
        Test-MDWPluginHeaders -PluginSlug $PluginSlug -PluginPath $pluginPath
        Test-MDWPluginReadme -PluginSlug $PluginSlug -PluginPath $pluginPath
        Test-MDWPluginTextDomain -PluginSlug $PluginSlug -PluginPath $pluginPath
        Test-MDWPluginLicense -PluginSlug $PluginSlug -PluginPath $pluginPath
        Test-MDWPluginAssets -PluginSlug $PluginSlug -PluginPath $pluginPath
        Test-MDWPluginForbiddenFiles -PluginSlug $PluginSlug -PluginPath $pluginPath
    )

    return Get-MDWPluginCheckReport -PluginSlug $PluginSlug -PluginPath $pluginPath -Sections $sections
}

function Invoke-MDWPluginCheckService {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    return Invoke-MDWPluginCheck -PluginSlug $PluginSlug
}
