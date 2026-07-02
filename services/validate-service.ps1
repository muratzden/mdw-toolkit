<#
MDW Validate Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

$outputServicePath = Join-Path (Split-Path -Parent $PSCommandPath) "output-service.ps1"

if (Test-Path $outputServicePath) {
    . $outputServicePath
}
else {
    throw "Output service not found: $outputServicePath"
}

function Write-MDWValidateLine {
    param(
        [string]$Level,
        [string]$Message
    )

    switch ($Level) {
        "PASS" { Write-MDWSuccess $Message }
        "WARN" { Write-MDWWarning $Message }
        "FAIL" { Write-MDWError $Message }
        default { Write-MDWInfo $Message }
    }
}

function Get-MDWPluginPath {
    param(
        [string]$PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        return $null
    }

    $defaultPath = Join-Path "C:\Workspace\Plugins" $PluginSlug

    if (Test-Path $defaultPath) {
        return $defaultPath
    }

    return $null
}

function Get-MDWMainPluginFile {
    param(
        [string]$PluginPath
    )

    $phpFiles = Get-ChildItem -Path $PluginPath -Filter "*.php" -File -ErrorAction SilentlyContinue

    foreach ($file in $phpFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue

        if ($content -match "Plugin Name:") {
            return $file.FullName
        }
    }

    return $null
}

function Test-MDWTextExists {
    param(
        [string]$Content,
        [string]$Pattern
    )

    return ($Content -match [regex]::Escape($Pattern))
}

function Invoke-MDWValidateService {
    param(
        [string]$ToolkitRoot,
        [string]$PluginSlug
    )

    $failed = 0
    $warnings = 0

        Write-MDWTitle "MDW Validate"

    $configPath = Join-Path $ToolkitRoot "mdw.json"

    if (Test-Path $configPath) {
        Write-MDWValidateLine "PASS" "mdw.json found"
    }
    else {
        Write-MDWValidateLine "FAIL" "mdw.json not found"
        $failed++
    }

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        Write-MDWValidateLine "WARN" "No plugin slug provided. Toolkit-only validation completed."
        $warnings++
    }
    else {
        $pluginPath = Get-MDWPluginPath -PluginSlug $PluginSlug

        if (-not $pluginPath) {
            Write-MDWValidateLine "FAIL" "Plugin not found: C:\Workspace\Plugins\$PluginSlug"
            $failed++
        }
        else {
            Write-MDWValidateLine "PASS" "Plugin found: $pluginPath"

            $mainFile = Get-MDWMainPluginFile -PluginPath $pluginPath

            if ($mainFile) {
                Write-MDWValidateLine "PASS" "Main plugin file found: $mainFile"

                $mainContent = Get-Content $mainFile -Raw

                $requiredHeaders = @(
                    "Plugin Name:",
                    "Description:",
                    "Version:",
                    "Author:",
                    "Text Domain:",
                    "Requires at least:",
                    "Requires PHP:",
                    "License:"
                )

                foreach ($header in $requiredHeaders) {
                    if (Test-MDWTextExists -Content $mainContent -Pattern $header) {
                        Write-MDWValidateLine "PASS" "Header exists: $header"
                    }
                    else {
                        Write-MDWValidateLine "FAIL" "Missing plugin header: $header"
                        $failed++
                    }
                }
            }
            else {
                Write-MDWValidateLine "FAIL" "Main plugin file could not be detected"
                $failed++
            }

            $readmePath = Join-Path $pluginPath "readme.txt"

            if (Test-Path $readmePath) {
                Write-MDWValidateLine "PASS" "readme.txt found"

                $readmeContent = Get-Content $readmePath -Raw

                $requiredReadmeFields = @(
                    "=== ",
                    "Contributors:",
                    "Tags:",
                    "Requires at least:",
                    "Tested up to:",
                    "Requires PHP:",
                    "Stable tag:",
                    "License:",
                    "License URI:",
                    "== Description ==",
                    "== Installation ==",
                    "== Changelog =="
                )

                foreach ($field in $requiredReadmeFields) {
                    if (Test-MDWTextExists -Content $readmeContent -Pattern $field) {
                        Write-MDWValidateLine "PASS" "readme field exists: $field"
                    }
                    else {
                        Write-MDWValidateLine "FAIL" "Missing readme field: $field"
                        $failed++
                    }
                }
            }
            else {
                Write-MDWValidateLine "FAIL" "readme.txt not found"
                $failed++
            }

            $gitPath = Join-Path $pluginPath ".git"

            if (Test-Path $gitPath) {
                Push-Location $pluginPath
                $gitStatus = git status --short 2>$null
                Pop-Location

                if ($LASTEXITCODE -eq 0) {
                    if ([string]::IsNullOrWhiteSpace($gitStatus)) {
                        Write-MDWValidateLine "PASS" "Git working tree clean"
                    }
                    else {
                        Write-MDWValidateLine "WARN" "Git working tree has uncommitted changes"
                        $warnings++
                    }
                }
                else {
                    Write-MDWValidateLine "WARN" "Git status could not be checked"
                    $warnings++
                }
            }
            else {
                Write-MDWValidateLine "WARN" "Plugin is not a Git repository"
                $warnings++
            }
        }
    }

       Write-MDWSummary -Failed $failed -Warnings $warnings

    if ($failed -gt 0) {
        return 1
    }

    return 0
}