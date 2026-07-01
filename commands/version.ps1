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

    $toolkitRoot = Get-MDWToolkitPath
    $workspaceRoot = Get-MDWWorkspacePath
    $config = Get-MDWConfig -ToolkitRoot $toolkitRoot
    $metadata = Get-MDWToolkitMetadata -Config $config
    $powerShellVersion = $PSVersionTable.PSVersion.ToString()

    $logoPath = Join-Path $toolkitRoot 'assets\logo-terminal.txt'

    Write-Host ''

    if (Test-Path $logoPath) {
        Get-Content $logoPath | ForEach-Object {
            Write-Host $_ -ForegroundColor Cyan
        }

        Write-Host ''
    }

    Write-Host $metadata.Slogan -ForegroundColor Blue

    Write-Host ''
    Write-Host ('-' * 60) -ForegroundColor DarkGray
    Write-Host ''

    Write-Host "Version      : " -NoNewline -ForegroundColor DarkGray
    Write-Host $metadata.Version -ForegroundColor Green

    Write-Host "Channel      : " -NoNewline -ForegroundColor DarkGray
    Write-Host $metadata.Channel -ForegroundColor Yellow

    Write-Host "PowerShell   : " -NoNewline -ForegroundColor DarkGray
    Write-Host $powerShellVersion -ForegroundColor White

    Write-Host "Workspace    : " -NoNewline -ForegroundColor DarkGray
    Write-Host $workspaceRoot -ForegroundColor Cyan

    Write-Host "Toolkit      : " -NoNewline -ForegroundColor DarkGray
    Write-Host $toolkitRoot -ForegroundColor Cyan

    Write-Host "GitHub       : " -NoNewline -ForegroundColor DarkGray
    Write-Host $metadata.GitHubUrl -ForegroundColor Blue

    Write-Host ''
    Write-Host ('-' * 60) -ForegroundColor DarkGray
    Write-Host ''
}
