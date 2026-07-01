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

    $toolkitRoot = Get-MDWToolkitPath
    $workspacePath = Get-MDWWorkspacePath
    $config = Get-MDWConfig -ToolkitRoot $toolkitRoot
    $metadata = Get-MDWToolkitMetadata -Config $config

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

    Write-MDWHeader -Title $metadata.Name -Subtitle $metadata.Slogan
    Write-MDWInfoCard -Label "Version" -Value ("v{0}" -f $metadata.Version)
    Write-MDWInfoCard -Label "Toolkit" -Value $toolkitRoot
    Write-MDWInfoCard -Label "Workspace" -Value $workspacePath
    Write-MDWInfoCard -Label "GitHub" -Value $metadata.GitHubUrl

    Write-MDWSection -Title "Available Commands"
    Write-MDWCommandList -Commands $commands

    Write-MDWSection -Title "Quick Examples"
    Write-MDWExample -Command "mdw doctor"
    Write-MDWExample -Command "mdw check <plugin-slug>"
    Write-MDWExample -Command "mdw build <plugin-slug>"
    Write-MDWExample -Command "mdw release <plugin-slug>"
    Write-Host ""
}
