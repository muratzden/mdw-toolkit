<#
MDW Version Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWVersion {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $version = "0.1.1-alpha"

    Write-Host "MDW Toolkit $version"
}