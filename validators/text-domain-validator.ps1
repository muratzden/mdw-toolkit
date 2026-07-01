<#
MDW Text Domain Validator
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWTextDomainValidator {
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

        if (Test-Path $mainPluginFile -PathType Leaf) {
            $mainContent = Get-Content -Path $mainPluginFile -Raw

            if ($mainContent -notmatch "Text Domain:") {
                $warnings.Add("Plugin header missing: Text Domain")
            }
        }
    }

    return @{
        Passed   = ($errors.Count -eq 0)
        Errors   = @($errors.ToArray())
        Warnings = @($warnings.ToArray())
    }
}
