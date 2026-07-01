<#
MDW Plugin Check CLI Validator
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWPluginCheckCliValidator {
    [CmdletBinding()]
    param()

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    $wpCommand = Get-Command "wp" -ErrorAction SilentlyContinue

    if ($null -eq $wpCommand) {
        $warnings.Add("WordPress Plugin Check CLI is not available.")

        return @{
            Passed    = $true
            Available = $false
            Errors    = @($errors.ToArray())
            Warnings  = @($warnings.ToArray())
            Command   = $null
        }
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    try {
        & wp plugin check --help *> $null

        if ($LASTEXITCODE -eq 0) {
            return @{
                Passed    = $true
                Available = $true
                Errors    = @($errors.ToArray())
                Warnings  = @($warnings.ToArray())
                Command   = $wpCommand.Source
            }
        }

        $warnings.Add("WordPress Plugin Check CLI is not available.")
    }
    catch {
        $warnings.Add("WordPress Plugin Check CLI is not available.")
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    return @{
        Passed    = $true
        Available = $false
        Errors    = @($errors.ToArray())
        Warnings  = @($warnings.ToArray())
        Command   = $wpCommand.Source
    }
}
