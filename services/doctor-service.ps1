<#
MDW Doctor Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWDoctorService {
    [CmdletBinding()]
    param()

    $toolkitRoot = Get-MDWRootPath
    $validatorResult = Invoke-MDWEnvironmentValidator -ToolkitRoot $toolkitRoot

    return @{
        Passed       = $validatorResult.Passed
        ErrorCount   = $validatorResult.Errors.Count
        WarningCount = $validatorResult.Warnings.Count
        Errors       = @($validatorResult.Errors)
        Warnings     = @($validatorResult.Warnings)
        Checks       = @($validatorResult.Checks)
        ToolkitRoot  = $toolkitRoot
    }
}
