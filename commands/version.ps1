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

    $version = "0.1.0"

    try {
        $rootPath = Get-MDWRootPath

        if (Get-Command Get-MDWConfigValue -ErrorAction SilentlyContinue) {
            $configuredVersion = Get-MDWConfigValue -ToolkitRoot $rootPath -Key "version"

            if ($configuredVersion) {
                $version = $configuredVersion
            }
        }
    }
    catch {
        $version = "0.1.0"
    }

    Write-Host "MDW Toolkit $version"
}