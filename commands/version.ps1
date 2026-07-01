<#
MDW Version Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWVersionWorkspacePath {
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

function Invoke-MDWVersion {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $version = "v0.1.2-alpha"
    $powerShellVersion = $PSVersionTable.PSVersion.ToString()
    $toolkitRoot = Get-MDWRootPath
    $workspacePath = Get-MDWVersionWorkspacePath
    $githubUrl = "https://github.com/muratzden/mdw-toolkit"

    Write-Host ""
    Write-Host ("MDW Toolkit {0}" -f $version)
    Write-Host "Professional WordPress CLI Toolkit"
    Write-Host ""
    Write-MDWInfoCard -Label "PowerShell" -Value $powerShellVersion
    Write-MDWInfoCard -Label "Toolkit" -Value $toolkitRoot
    Write-MDWInfoCard -Label "Workspace" -Value $workspacePath
    Write-MDWInfoCard -Label "GitHub" -Value $githubUrl
    Write-Host ""
}
