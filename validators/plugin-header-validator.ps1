<#
MDW Plugin Header Validator
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWPluginHeaderValidator {
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

        if (-not (Test-Path $mainPluginFile -PathType Leaf)) {
            $errors.Add("Main plugin file not found: $mainPluginFile")
        }
        else {
            $mainContent = Get-Content -Path $mainPluginFile -Raw

            if ($mainContent -notmatch "Plugin Name:") {
                $errors.Add("Plugin header missing: Plugin Name")
            }

            if ($mainContent -notmatch "Version:") {
                $errors.Add("Plugin header missing: Version")
            }
        }
    }

    return @{
        Passed   = ($errors.Count -eq 0)
        Errors   = @($errors.ToArray())
        Warnings = @($warnings.ToArray())
    }
}
