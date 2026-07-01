<#
MDW License Validator
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWLicenseValidator {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        $errors.Add("Plugin slug could not be resolved.")
    }

    if ([string]::IsNullOrWhiteSpace($PluginPath)) {
        $errors.Add("Plugin path could not be resolved.")
    }

    if ($errors.Count -eq 0) {
        $mainPluginFile = Join-Path $PluginPath "$PluginSlug.php"
        $readmeFile = Join-Path $PluginPath "readme.txt"

        if (Test-Path $mainPluginFile -PathType Leaf) {
            $mainContent = Get-Content -Path $mainPluginFile -Raw

            if ($mainContent -notmatch "License:") {
                $warnings.Add("Plugin header missing: License")
            }
        }

        if (Test-Path $readmeFile -PathType Leaf) {
            $readmeContent = Get-Content -Path $readmeFile -Raw

            if ($readmeContent -notmatch "License:") {
                $warnings.Add("readme.txt missing License.")
            }
        }
    }

    return @{
        Passed   = ($errors.Count -eq 0)
        Errors   = @($errors.ToArray())
        Warnings = @($warnings.ToArray())
    }
}
