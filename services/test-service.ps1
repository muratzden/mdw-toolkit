<#
MDW Test Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWTestService {
    [CmdletBinding()]
    param()

    return Invoke-MDWTestRunner -TestsRoot (Join-Path (Get-MDWRootPath) "tests")
}
