<#
MDW Validate Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function New-MDWValidateItem {
    [CmdletBinding()]
    param(
        [string] $Name,
        [ValidateSet("OK", "WARN", "FAIL", "INFO")]
        [string] $Status,
        [string] $Message
    )

    return @{
        Name    = $Name
        Status  = $Status
        Message = $Message
    }
}

function New-MDWValidateSection {
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

function Get-MDWValidateMainPluginFile {
    [CmdletBinding()]
    param(
        [string] $PluginPath
    )

    $phpFiles = @(Get-ChildItem -LiteralPath $PluginPath -Filter "*.php" -File -ErrorAction SilentlyContinue)

    foreach ($file in $phpFiles) {
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -match "(?mi)^\s*(?:\*\s*)?Plugin Name\s*:") {
            return $file.FullName
        }
    }

    return $null
}

function Test-MDWValidateTextExists {
    [CmdletBinding()]
    param(
        [string] $Content,
        [string] $Pattern
    )

    return ($Content -match [regex]::Escape($Pattern))
}

function Get-MDWValidateResult {
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

function Invoke-MDWValidateService {
    [CmdletBinding()]
    param(
        [string] $ToolkitRoot,
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($ToolkitRoot)) {
        $ToolkitRoot = Get-MDWToolkitPath
    }

    $sections = New-Object System.Collections.Generic.List[object]

    $configItems = New-Object System.Collections.Generic.List[object]
    $configPath = $null

    try {
        $configPath = Get-MDWConfigPath -ToolkitRoot $ToolkitRoot

        if (Test-Path -LiteralPath $configPath -PathType Leaf) {
            $config = Get-MDWConfig -ToolkitRoot $ToolkitRoot
            Test-MDWConfig -Config $config | Out-Null
            $configItems.Add((New-MDWValidateItem -Name "mdw.json" -Status "OK" -Message "mdw.json is readable and valid"))
        }
        else {
            $configItems.Add((New-MDWValidateItem -Name "mdw.json" -Status "FAIL" -Message "mdw.json not found: $configPath"))
        }
    }
    catch {
        $configItems.Add((New-MDWValidateItem -Name "mdw.json" -Status "FAIL" -Message $_.Exception.Message))
    }

    $sections.Add((New-MDWValidateSection -Name "Configuration" -Items @($configItems.ToArray())))

    $pluginPath = $null

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        $pluginItems = @(
            New-MDWValidateItem -Name "Plugin" -Status "WARN" -Message "No plugin slug provided. Toolkit-only validation completed."
        )
        $sections.Add((New-MDWValidateSection -Name "Plugin" -Items $pluginItems))
        return Get-MDWValidateResult -PluginSlug $PluginSlug -PluginPath $pluginPath -Sections @($sections.ToArray())
    }

    $pluginPath = Resolve-MDWPluginPath -PluginSlug $PluginSlug
    $pluginItems = New-Object System.Collections.Generic.List[object]

    if (Test-Path -LiteralPath $pluginPath -PathType Container) {
        $pluginItems.Add((New-MDWValidateItem -Name "Plugin folder" -Status "OK" -Message "Plugin found: $pluginPath"))
    }
    else {
        $pluginItems.Add((New-MDWValidateItem -Name "Plugin folder" -Status "FAIL" -Message "Plugin not found: $pluginPath"))
        $sections.Add((New-MDWValidateSection -Name "Plugin" -Items @($pluginItems.ToArray())))
        return Get-MDWValidateResult -PluginSlug $PluginSlug -PluginPath $pluginPath -Sections @($sections.ToArray())
    }

    $sections.Add((New-MDWValidateSection -Name "Plugin" -Items @($pluginItems.ToArray())))

    $headerItems = New-Object System.Collections.Generic.List[object]
    $mainFile = Get-MDWValidateMainPluginFile -PluginPath $pluginPath

    if ([string]::IsNullOrWhiteSpace($mainFile)) {
        $headerItems.Add((New-MDWValidateItem -Name "Main plugin file" -Status "FAIL" -Message "Main plugin file could not be detected"))
    }
    else {
        $headerItems.Add((New-MDWValidateItem -Name "Main plugin file" -Status "OK" -Message $mainFile))
        $mainContent = Get-Content -LiteralPath $mainFile -Raw -ErrorAction SilentlyContinue

        foreach ($header in @("Plugin Name:", "Description:", "Version:", "Author:", "Text Domain:", "Requires at least:", "Requires PHP:", "License:")) {
            if (Test-MDWValidateTextExists -Content $mainContent -Pattern $header) {
                $headerItems.Add((New-MDWValidateItem -Name $header -Status "OK" -Message "Header exists: $header"))
            }
            else {
                $headerItems.Add((New-MDWValidateItem -Name $header -Status "FAIL" -Message "Missing plugin header: $header"))
            }
        }
    }

    $sections.Add((New-MDWValidateSection -Name "Plugin Header" -Items @($headerItems.ToArray())))

    $readmeItems = New-Object System.Collections.Generic.List[object]
    $readmePath = Join-Path $pluginPath "readme.txt"

    if (Test-Path -LiteralPath $readmePath -PathType Leaf) {
        $readmeItems.Add((New-MDWValidateItem -Name "readme.txt" -Status "OK" -Message "readme.txt found"))
        $readmeContent = Get-Content -LiteralPath $readmePath -Raw -ErrorAction SilentlyContinue

        foreach ($field in @("=== ", "Contributors:", "Tags:", "Requires at least:", "Tested up to:", "Requires PHP:", "Stable tag:", "License:", "License URI:", "== Description ==", "== Installation ==", "== Changelog ==")) {
            if (Test-MDWValidateTextExists -Content $readmeContent -Pattern $field) {
                $readmeItems.Add((New-MDWValidateItem -Name $field -Status "OK" -Message "readme field exists: $field"))
            }
            else {
                $readmeItems.Add((New-MDWValidateItem -Name $field -Status "FAIL" -Message "Missing readme field: $field"))
            }
        }
    }
    else {
        $readmeItems.Add((New-MDWValidateItem -Name "readme.txt" -Status "FAIL" -Message "readme.txt not found"))
    }

    $sections.Add((New-MDWValidateSection -Name "Readme" -Items @($readmeItems.ToArray())))

    $gitItems = New-Object System.Collections.Generic.List[object]
    $gitPath = Join-Path $pluginPath ".git"

    if (Test-Path -LiteralPath $gitPath -PathType Container) {
        $gitStatus = Get-MDWGitStatus -RepositoryPath $pluginPath

        if ($gitStatus.Repository -and $gitStatus.Clean) {
            $gitItems.Add((New-MDWValidateItem -Name "Working tree" -Status "OK" -Message "Git working tree clean"))
        }
        elseif ($gitStatus.Repository) {
            $gitItems.Add((New-MDWValidateItem -Name "Working tree" -Status "WARN" -Message "Git working tree has uncommitted changes"))
        }
        else {
            $gitItems.Add((New-MDWValidateItem -Name "Repository" -Status "WARN" -Message "Git status could not be checked"))
        }
    }
    else {
        $gitItems.Add((New-MDWValidateItem -Name "Repository" -Status "WARN" -Message "Plugin is not a Git repository"))
    }

    $sections.Add((New-MDWValidateSection -Name "Git" -Items @($gitItems.ToArray())))

    return Get-MDWValidateResult -PluginSlug $PluginSlug -PluginPath $pluginPath -Sections @($sections.ToArray())
}

