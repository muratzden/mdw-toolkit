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

    $version = "v0.1.2-alpha"
    $toolkitRoot = Get-MDWRootPath
    $workspacePath = Get-MDWHelpWorkspacePath
    $githubUrl = "https://github.com/muratzden/mdw-toolkit"

    $commands = @(
        @{ Name = "mdw help"; Description = "Show this screen" }
        @{ Name = "mdw version"; Description = "Show version information" }
        @{ Name = "mdw info"; Description = "Show workspace information" }
        @{ Name = "mdw doctor"; Description = "Check environment" }
        @{ Name = "mdw check"; Description = "Validate plugin structure" }
        @{ Name = "mdw build"; Description = "Build production package" }
        @{ Name = "mdw zip"; Description = "Create release ZIP" }
        @{ Name = "mdw release"; Description = "Run release pipeline" }
        @{ Name = "mdw test"; Description = "Run test suite" }
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Build | Validate | Test | Release WordPress Plugins"
    Write-MDWInfoCard -Label "Version" -Value $version
    Write-MDWInfoCard -Label "Toolkit" -Value $toolkitRoot
    Write-MDWInfoCard -Label "Workspace" -Value $workspacePath
    Write-MDWInfoCard -Label "GitHub" -Value $githubUrl

    Write-MDWSection -Title "Available Commands"
    Write-MDWCommandList -Commands $commands

    Write-MDWSection -Title "Quick Examples"
    Write-MDWExample -Command "mdw doctor"
    Write-MDWExample -Command "mdw check <plugin-slug>"
    Write-MDWExample -Command "mdw build <plugin-slug>"
    Write-MDWExample -Command "mdw release <plugin-slug>"
    Write-Host ""
}
