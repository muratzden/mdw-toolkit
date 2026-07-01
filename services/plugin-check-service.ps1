<#
MDW Plugin Check Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWPluginCheckService {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]
    $output = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        $errors.Add("Plugin slug could not be resolved.")

        return @{
            Passed       = $false
            ErrorCount   = $errors.Count
            WarningCount = $warnings.Count
            Errors       = @($errors.ToArray())
            Warnings     = @($warnings.ToArray())
            Output       = @($output.ToArray())
            PluginSlug   = $PluginSlug
            PluginPath   = $null
        }
    }

    $pluginPath = Resolve-MDWPluginPath -PluginSlug $PluginSlug -RequireExisting
    $cliResult = Invoke-MDWPluginCheckCliValidator

    foreach ($errorItem in $cliResult.Errors) {
        $errors.Add($errorItem)
    }

    foreach ($warning in $cliResult.Warnings) {
        $warnings.Add($warning)
    }

    if (-not $cliResult.Available) {
        return @{
            Passed       = ($errors.Count -eq 0)
            ErrorCount   = $errors.Count
            WarningCount = $warnings.Count
            Errors       = @($errors.ToArray())
            Warnings     = @($warnings.ToArray())
            Output       = @($output.ToArray())
            PluginSlug   = $PluginSlug
            PluginPath   = $pluginPath
        }
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        $rawOutput = & wp plugin check $pluginPath 2>&1

        foreach ($line in $rawOutput) {
            if ($null -ne $line) {
                $output.Add([string] $line)
            }
        }
    }
    catch {
        $errors.Add($_.Exception.Message)
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    foreach ($line in $output) {
        if ($line -match '(?i)\b(error|fatal)\b') {
            $errors.Add($line)
        }
        elseif ($line -match '(?i)\bwarning\b') {
            $warnings.Add($line)
        }
    }

    return @{
        Passed       = ($errors.Count -eq 0)
        ErrorCount   = $errors.Count
        WarningCount = $warnings.Count
        Errors       = @($errors.ToArray())
        Warnings     = @($warnings.ToArray())
        Output       = @($output.ToArray())
        PluginSlug   = $PluginSlug
        PluginPath   = $pluginPath
    }
}
