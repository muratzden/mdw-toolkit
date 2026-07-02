<#
MDW Lint Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWLintArgumentValue {
    [CmdletBinding()]
    param(
        [string[]] $Arguments,
        [string] $Name
    )

    if (-not $Arguments) {
        return $null
    }

    for ($index = 0; $index -lt $Arguments.Count; $index++) {
        if ($Arguments[$index] -eq $Name -and ($index + 1) -lt $Arguments.Count) {
            return $Arguments[$index + 1]
        }
    }

    return $null
}

function Invoke-MDWLint {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $pluginPath = Get-MDWLintArgumentValue -Arguments $Arguments -Name "-PluginPath"
    $pluginSlug = Get-MDWLintArgumentValue -Arguments $Arguments -Name "-PluginSlug"

    if ([string]::IsNullOrWhiteSpace($pluginPath) -and $Arguments -and $Arguments.Count -gt 0) {
        if ($Arguments[0] -notlike "-*") {
            $pluginSlug = $Arguments[0]
        }
    }

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "PHP Lint"

    $result = Invoke-MDWLintService -PluginPath $pluginPath -PluginSlug $pluginSlug

    Write-MDWSection -Title "Scope"
    Write-MDWInfoCard -Label "Path" -Value $result.PluginPath
    Write-MDWInfoCard -Label "Files" -Value $result.FileCount

    Write-MDWSection -Title "Checks"

    foreach ($item in $result.Files) {
        Write-MDWStatus -Status $item.Status -Message $item.Message
    }

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Errors" -Value $result.ErrorCount
    Write-MDWInfoCard -Label "PHP" -Value $result.PhpVersion

    if ($result.Passed) {
        Write-MDWResult -Status "OK" -Message "PHP lint passed."
        return
    }

    Write-MDWResult -Status "FAIL" -Message "PHP lint failed."
}
