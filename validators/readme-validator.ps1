<#
MDW Readme Validator
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWReadmeValidator {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $warnings = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($PluginPath)) {
        $errors.Add("Plugin path could not be resolved.")
    }

    if ($errors.Count -eq 0) {
        $readmeFile = Join-Path $PluginPath "readme.txt"

        if (-not (Test-Path $readmeFile -PathType Leaf)) {
            $warnings.Add("readme.txt not found.")
        }
        else {
            $readmeContent = Get-Content -Path $readmeFile -Raw

            if ($readmeContent -notmatch "Stable tag:") {
                $warnings.Add("readme.txt missing Stable tag.")
            }
        }
    }

    return @{
        Passed   = ($errors.Count -eq 0)
        Errors   = @($errors.ToArray())
        Warnings = @($warnings.ToArray())
    }
}
