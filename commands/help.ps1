<#
MDW Help Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Invoke-MDWHelp {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $registry = Get-MDWCommandRegistry

    Write-Host ""
    Write-Host "MDW Toolkit" -ForegroundColor Cyan
    Write-Host "Professional WordPress Development CLI"
    Write-Host ""

    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  mdw <command> [arguments]"
    Write-Host ""

    Write-Host "Commands:" -ForegroundColor Yellow

    foreach ($name in ($registry.Keys | Sort-Object)) {
        $description = $registry[$name].Description
        Write-Host ("  {0,-12} {1}" -f $name, $description)
    }

    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  mdw help"
    Write-Host "  mdw version"
    Write-Host "  mdw new plugin my-plugin"
    Write-Host "  mdw build"
    Write-Host "  mdw check"
    Write-Host "  mdw release"
    Write-Host ""
}