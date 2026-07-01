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

    $version = '0.1.1-alpha'
    $toolkitRoot = Get-MDWRootPath
    $workspaceRoot = Split-Path $toolkitRoot -Parent
    $powerShellVersion = $PSVersionTable.PSVersion.ToString()
    $githubUrl = 'https://github.com/muratzden/mdw-toolkit'
    $logoPath = Join-Path $toolkitRoot 'assets\logo-terminal.txt'

    Write-Host ''

    if (Test-Path $logoPath) {
        Get-Content -Path $logoPath | ForEach-Object {
            Write-Host $_ -ForegroundColor Cyan
        }

        Write-Host ''
    }

    Write-Host "Version      : $version" -ForegroundColor Green
    Write-Host "PowerShell   : $powerShellVersion"
    Write-Host "Workspace    : $workspaceRoot"
    Write-Host "Toolkit      : $toolkitRoot"
    Write-Host "GitHub       : $githubUrl"
    Write-Host ''
}