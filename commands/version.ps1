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
    $config      = Get-MDWConfig -ToolkitRoot $toolkitRoot
    $metadata    = Get-MDWToolkitMetadata -Config $config

    Write-MDWHeader `
        -Title $metadata.Name `
        -Subtitle $metadata.Slogan

    Write-MDWSection -Title "Version"

    Write-MDWInfoCard `
        -Label "Toolkit" `
        -Value $metadata.Name

    Write-MDWInfoCard `
        -Label "Version" `
        -Value $metadata.Version

    Write-MDWInfoCard `
        -Label "Channel" `
        -Value $metadata.Channel

    Write-MDWResult `
        -Status "OK" `
        -Message "MDW Toolkit is ready."
}