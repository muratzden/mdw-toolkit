<#
MDW Plugin Check Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWPluginCheckArgumentValue {
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

function Invoke-MDWPluginCheckCommand {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $pluginSlug = Get-MDWPluginCheckArgumentValue -Arguments $Arguments -Name "-PluginSlug"
    $wordpressPath = Get-MDWPluginCheckArgumentValue -Arguments $Arguments -Name "-WordPressPath"

    if ([string]::IsNullOrWhiteSpace($pluginSlug) -and $Arguments -and $Arguments.Count -gt 0) {
        if ($Arguments[0] -notlike "-*") {
            $pluginSlug = $Arguments[0]
        }
    }

    if ([string]::IsNullOrWhiteSpace($pluginSlug)) {
        $currentPath = Get-Location
        $pluginSlug = Split-Path $currentPath -Leaf
    }

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Plugin Check"

    if ([string]::IsNullOrWhiteSpace($pluginSlug)) {
        Write-MDWResult -Status "FAIL" -Message "Plugin slug could not be resolved."
        return
    }

    $result = Invoke-MDWPluginCheckService -PluginSlug $pluginSlug -WordPressPath $wordpressPath

    Write-MDWSection -Title "Plugin"
    Write-MDWInfoCard -Label "Plugin" -Value $pluginSlug
    Write-MDWInfoCard -Label "Mode" -Value $result.Mode

    if (-not [string]::IsNullOrWhiteSpace($wordpressPath)) {
        Write-MDWInfoCard -Label "WordPress" -Value $wordpressPath
    }

    foreach ($section in $result.Sections) {
        Write-MDWSection -Title $section.Name

        foreach ($item in $section.Items) {
            Write-MDWStatus `
                -Status $item.Status `
                -Message $item.Message
        }
    }

    if ($result.Output -and $result.Output.Count -gt 0) {
        Write-MDWSection -Title "Output"

        foreach ($line in $result.Output) {
            if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
                Write-MDWStatus -Status "INFO" -Message $line
            }
        }
    }

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Warnings" -Value $result.WarningCount
    Write-MDWInfoCard -Label "Errors" -Value $result.ErrorCount

    if ($result.ErrorCount -gt 0) {
        Write-MDWResult `
            -Status "FAIL" `
            -Message ("Plugin Check failed with {0} errors." -f $result.ErrorCount)

        return
    }

    if ($result.WarningCount -gt 0) {
        Write-MDWResult `
            -Status "WARN" `
            -Message ("Plugin Check passed with {0} warnings." -f $result.WarningCount)

        return
    }

    Write-MDWResult `
        -Status "OK" `
        -Message "Plugin Check passed."
}

