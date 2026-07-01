<#
MDW Help Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWHelpWorkspacePath {
    [CmdletBinding()]
    param()

    $toolkitRoot = Get-MDWRootPath
    $workspacePath = Split-Path $toolkitRoot -Parent

    try {
        $config = Get-MDWConfig -ToolkitRoot $toolkitRoot
        $configuredWorkspacePath = Get-MDWConfigValue -Config $config -Key "workspace.rootPath" -DefaultValue $null

        if (-not [string]::IsNullOrWhiteSpace([string] $configuredWorkspacePath)) {
            $workspacePath = [string] $configuredWorkspacePath
        }
    }
    catch {
        $workspacePath = Split-Path $toolkitRoot -Parent
    }

    return $workspacePath
}

function Invoke-MDWHelp {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $version = "0.1.1-alpha"
    $toolkitRoot = Get-MDWRootPath
    $workspacePath = Get-MDWHelpWorkspacePath
    $githubUrl = "https://github.com/muratzden/mdw-toolkit"

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " MDW Toolkit" -ForegroundColor Cyan
    Write-Host " Professional WordPress CLI Toolkit" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("Version    : {0}" -f $version)
    Write-Host ("Toolkit    : {0}" -f $toolkitRoot)
    Write-Host ("Workspace  : {0}" -f $workspacePath)
    Write-Host ("GitHub     : {0}" -f $githubUrl)
    Write-Host ""
    Write-Host "Available Commands" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  new            Create a new plugin"
    Write-Host "  init           Import or initialize a plugin"
    Write-Host "  doctor         Check development environment"
    Write-Host "  info           Show workspace information"
    Write-Host "  check          Validate plugin structure"
    Write-Host "  plugin-check   Run WordPress Plugin Check"
    Write-Host "  build          Build production package"
    Write-Host "  zip            Create release ZIP"
    Write-Host "  release        Run full release pipeline"
    Write-Host "  test           Run MDW test suite"
    Write-Host "  version        Show version information"
    Write-Host "  help           Show this help screen"
    Write-Host ""
    Write-Host "Examples" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  mdw doctor"
    Write-Host "  mdw new plugin my-plugin"
    Write-Host "  mdw check my-plugin"
    Write-Host "  mdw release my-plugin"
    Write-Host ""
}
