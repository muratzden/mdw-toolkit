<#
MDW Check Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWCheckService {
    [CmdletBinding()]
    param(
        [string] $PluginSlug
    )

    if ([string]::IsNullOrWhiteSpace($PluginSlug)) {
        throw "Plugin slug could not be resolved."
    }

    $pluginPath = Resolve-MDWPluginPath -PluginSlug $PluginSlug -RequireExisting

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    $validatorResults = @(
        Invoke-MDWPluginHeaderValidator -PluginSlug $PluginSlug -PluginPath $pluginPath
        Invoke-MDWReadmeValidator -PluginSlug $PluginSlug -PluginPath $pluginPath
        Invoke-MDWLicenseValidator -PluginSlug $PluginSlug -PluginPath $pluginPath
        Invoke-MDWTextDomainValidator -PluginSlug $PluginSlug -PluginPath $pluginPath
    )

    foreach ($validatorResult in $validatorResults) {
        foreach ($errorItem in $validatorResult.Errors) {
            $errors.Add($errorItem)
        }

        foreach ($warning in $validatorResult.Warnings) {
            $warnings.Add($warning)
        }
    }

    return @{
        Passed       = ($errors.Count -eq 0)
        ErrorCount   = $errors.Count
        WarningCount = $warnings.Count
        Errors       = @($errors.ToArray())
        Warnings     = @($warnings.ToArray())
        PluginSlug   = $PluginSlug
        PluginPath   = $pluginPath
    }
}
