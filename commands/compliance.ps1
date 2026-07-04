<#
MDW Compliance Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWComplianceArgumentValue {
    [CmdletBinding()]
    param(
        [string[]] $Arguments,
        [string] $Name
    )

    if (-not $Arguments) {
        return $null
    }

    for ($index = 0; $index -lt $Arguments.Count; $index++) {
        if (($Arguments[$index] -eq $Name -or $Arguments[$index] -eq $Name.Replace("-", "--")) -and ($index + 1) -lt $Arguments.Count) {
            return $Arguments[$index + 1]
        }
    }

    return $null
}

function Format-MDWComplianceFindingMessage {
    [CmdletBinding()]
    param(
        [object] $Finding
    )

    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add([string] $Finding.Message)

    if ($Finding.ContainsKey("CurrentValue") -and -not [string]::IsNullOrWhiteSpace([string] $Finding.CurrentValue)) {
        $parts.Add(("Current: {0}" -f $Finding.CurrentValue))
    }

    if ($Finding.ContainsKey("RecommendedValue") -and -not [string]::IsNullOrWhiteSpace([string] $Finding.RecommendedValue)) {
        $parts.Add(("Recommended: {0}" -f $Finding.RecommendedValue))
    }

    if ($Finding.ContainsKey("File") -and -not [string]::IsNullOrWhiteSpace([string] $Finding.File)) {
        $location = [string] $Finding.File

        if ($Finding.ContainsKey("Line") -and $null -ne $Finding.Line) {
            $location = ("{0}:{1}" -f $location, $Finding.Line)
        }

        $parts.Add(("File: {0}" -f $location))
    }

    return ($parts.ToArray() -join " | ")
}

function Invoke-MDWCompliance {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $pluginSlug = Get-MDWComplianceArgumentValue -Arguments $Arguments -Name "-PluginSlug"
    $pluginPath = Get-MDWComplianceArgumentValue -Arguments $Arguments -Name "-PluginPath"
    $expectedPrefix = Get-MDWComplianceArgumentValue -Arguments $Arguments -Name "-prefix"

    if ([string]::IsNullOrWhiteSpace($pluginSlug) -and $Arguments -and $Arguments.Count -gt 0) {
        if ($Arguments[0] -notlike "-*") {
            $pluginSlug = $Arguments[0]
        }
    }

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Compliance"

    if ([string]::IsNullOrWhiteSpace($pluginSlug) -and [string]::IsNullOrWhiteSpace($pluginPath)) {
        Write-MDWResult -Status "FAIL" -Message "Plugin slug or plugin path is required."
        return
    }

    $result = Invoke-MDWComplianceService -PluginSlug $pluginSlug -PluginPath $pluginPath -ExpectedPrefix $expectedPrefix

    Write-MDWSection -Title "Scope"
    Write-MDWInfoCard -Label "Plugin" -Value $result.PluginSlug
    Write-MDWInfoCard -Label "Path" -Value $result.PluginPath

    if (-not [string]::IsNullOrWhiteSpace($result.ExpectedPrefix)) {
        Write-MDWInfoCard -Label "Prefix" -Value $result.ExpectedPrefix
    }

    Write-MDWSection -Title "Findings"

    if (-not $result.Findings -or $result.Findings.Count -eq 0) {
        Write-MDWStatus -Status "OK" -Message "No compliance findings."
    }
    else {
        foreach ($finding in $result.Findings) {
            $status = "INFO"

            if ($finding.Status) {
                $status = $finding.Status
            }
            elseif ($finding.Severity -eq "Error") {
                $status = "FAIL"
            }
            elseif ($finding.Severity -eq "Warning") {
                $status = "WARN"
            }

            Write-MDWStatus -Status $status -Message (Format-MDWComplianceFindingMessage -Finding $finding)
        }
    }

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Failed" -Value $result.Failed
    Write-MDWInfoCard -Label "Warnings" -Value $result.Warnings

    if ($result.Failed -gt 0) {
        Write-MDWResult -Status "FAIL" -Message ("Compliance failed with {0} findings." -f $result.Failed)
        return
    }

    if ($result.Warnings -gt 0) {
        Write-MDWResult -Status "WARN" -Message ("Compliance passed with {0} warnings." -f $result.Warnings)
        return
    }

    Write-MDWResult -Status "OK" -Message "Compliance passed."
}
