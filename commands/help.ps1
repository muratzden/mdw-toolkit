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

    $commonCommands = @(
        @{ Name = "mdw doctor"; Description = "Check environment" }
        @{ Name = "mdw build <plugin-slug>"; Description = "Build package" }
        @{ Name = "mdw release <plugin-slug>"; Description = "Release plugin" }
    )

    $workflowCommands = @(
        @{ Name = "mdw check <plugin-slug>"; Description = "Validate plugin" }
        @{ Name = "mdw plugin-check <plugin-slug>"; Description = "Plugin checks" }
        @{ Name = "mdw zip <plugin-slug>"; Description = "Create ZIP" }
        @{ Name = "mdw test"; Description = "Run tests" }
    )

    $utilityCommands = @(
        @{ Name = "mdw help"; Description = "Show help" }
        @{ Name = "mdw info"; Description = "Workspace info" }
        @{ Name = "mdw version"; Description = "Show version" }
        @{ Name = "mdw git"; Description = "Git status" }
        @{ Name = "mdw local"; Description = "LocalWP" }
    )

    Write-MDWLogo

Write-MDWHeader `
    -Title $metadata.Name `
    -Subtitle $metadata.Slogan

    Write-MDWSection -Title "Workspace"
    Write-MDWInfoCard -Label "Workspace" -Value $workspacePath
    Write-MDWInfoCard -Label "Toolkit" -Value $toolkitRoot

    Write-MDWSection -Title "Common Commands"
    Write-MDWCommandList -Commands $commonCommands

    Write-MDWSection -Title "Workflow Commands"
    Write-MDWCommandList -Commands $workflowCommands

    Write-MDWSection -Title "Utility Commands"
    Write-MDWCommandList -Commands $utilityCommands

    Write-MDWSection -Title "Getting Started"
    Write-MDWExample -Command "mdw doctor"

    Write-Host ""
}