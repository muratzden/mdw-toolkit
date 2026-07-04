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

function Test-MDWComplianceFlag {
    [CmdletBinding()]
    param(
        [string[]] $Arguments,
        [string] $Name
    )

    if (-not $Arguments) {
        return $false
    }

    foreach ($argument in $Arguments) {
        if ($argument -eq $Name -or $argument -eq $Name.Replace("-", "--")) {
            return $true
        }
    }

    return $false
}

function Get-MDWCompliancePluginArgument {
    [CmdletBinding()]
    param(
        [string[]] $Arguments,
        [int] $StartIndex = 0
    )

    if (-not $Arguments) {
        return $null
    }

    for ($index = $StartIndex; $index -lt $Arguments.Count; $index++) {
        $argument = $Arguments[$index]

        if ($argument -like "-*") {
            $index++
            continue
        }

        return $argument
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

function Write-MDWComplianceReport {
    [CmdletBinding()]
    param(
        [object] $Result
    )

    Write-MDWSection -Title "Scope"
    Write-MDWInfoCard -Label "Plugin" -Value $Result.PluginSlug
    Write-MDWInfoCard -Label "Path" -Value $Result.PluginPath

    if (-not [string]::IsNullOrWhiteSpace($Result.ExpectedPrefix)) {
        Write-MDWInfoCard -Label "Prefix" -Value $Result.ExpectedPrefix
    }

    Write-MDWSection -Title "Findings"

    if (-not $Result.Findings -or $Result.Findings.Count -eq 0) {
        Write-MDWStatus -Status "OK" -Message "No compliance findings."
    }
    else {
        foreach ($finding in $Result.Findings) {
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
    Write-MDWInfoCard -Label "Failed" -Value $Result.Failed
    Write-MDWInfoCard -Label "Warnings" -Value $Result.Warnings

    if ($Result.Failed -gt 0) {
        Write-MDWResult -Status "FAIL" -Message ("Compliance failed with {0} findings." -f $Result.Failed)
        return
    }

    if ($Result.Warnings -gt 0) {
        Write-MDWResult -Status "WARN" -Message ("Compliance passed with {0} warnings." -f $Result.Warnings)
        return
    }

    Write-MDWResult -Status "OK" -Message "Compliance passed."
}

function Write-MDWComplianceFixReport {
    [CmdletBinding()]
    param(
        [object] $Result
    )

    Write-MDWSection -Title "Scope"
    Write-MDWInfoCard -Label "Plugin" -Value $Result.PluginSlug
    Write-MDWInfoCard -Label "Path" -Value $Result.PluginPath
    Write-MDWInfoCard -Label "Prefix" -Value $Result.ExpectedPrefix
    Write-MDWInfoCard -Label "Mode" -Value $(if ($Result.WhatIf) { "WhatIf" } else { "Apply" })

    Write-MDWSection -Title "Backup"

    if ($Result.WhatIf) {
        Write-MDWStatus -Status "INFO" -Message "Dry run only. No backup created."
    }
    else {
        Write-MDWStatus -Status "OK" -Message "Backup created before modifying files."
        Write-MDWInfoCard -Label "Backup" -Value $Result.BackupPath
    }

    Write-MDWSection -Title "Changes"

    if (-not $Result.ChangedFiles -or $Result.ChangedFiles.Count -eq 0) {
        Write-MDWStatus -Status "OK" -Message "No unsafe prefixes require replacement."
    }
    else {
        foreach ($change in $Result.ChangedFiles) {
            $status = "OK"

            if ($Result.WhatIf) {
                $status = "INFO"
            }

            Write-MDWStatus -Status $status -Message ("{0} replacements in {1}" -f $change.ReplacementCount, $change.File)
        }
    }

    Write-MDWSection -Title "Skipped"

    if (-not $Result.Skipped -or $Result.Skipped.Count -eq 0) {
        Write-MDWStatus -Status "OK" -Message "No ambiguous findings skipped."
    }
    else {
        foreach ($skip in $Result.Skipped) {
            Write-MDWStatus -Status "WARN" -Message ("Skipped {0} at {1}:{2}. {3}" -f $skip.CurrentValue, $skip.File, $skip.Line, $skip.Reason)
        }
    }

    Write-MDWSection -Title "Validation"
    Write-MDWInfoCard -Label "Failed" -Value $Result.Validation.Failed
    Write-MDWInfoCard -Label "Warnings" -Value $Result.Validation.Warnings

    if ($Result.WhatIf) {
        Write-MDWResult -Status "INFO" -Message ("Dry run complete. {0} replacements would be made." -f $Result.ReplacementCount)
        return
    }

    if ($Result.Validation.Failed -gt 0) {
        Write-MDWResult -Status "FAIL" -Message "Prefix fix completed, but validation still has failures."
        return
    }

    if ($Result.Validation.Warnings -gt 0) {
        Write-MDWResult -Status "WARN" -Message ("Prefix fix completed with {0} validation warnings." -f $Result.Validation.Warnings)
        return
    }

    Write-MDWResult -Status "OK" -Message ("Prefix fix completed. {0} replacements applied." -f $Result.ReplacementCount)
}

function Invoke-MDWCompliance {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $isFix = $false
    $argumentOffset = 0

    if ($Arguments -and $Arguments.Count -gt 0 -and $Arguments[0].ToLowerInvariant() -eq "fix") {
        $isFix = $true
        $argumentOffset = 1
    }

    $pluginSlug = Get-MDWComplianceArgumentValue -Arguments $Arguments -Name "-PluginSlug"
    $pluginPath = Get-MDWComplianceArgumentValue -Arguments $Arguments -Name "-PluginPath"
    $expectedPrefix = Get-MDWComplianceArgumentValue -Arguments $Arguments -Name "-prefix"
    $whatIf = Test-MDWComplianceFlag -Arguments $Arguments -Name "-whatif"

    if ([string]::IsNullOrWhiteSpace($pluginSlug)) {
        $pluginSlug = Get-MDWCompliancePluginArgument -Arguments $Arguments -StartIndex $argumentOffset
    }

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle $(if ($isFix) { "Compliance Fix" } else { "Compliance" })

    if ([string]::IsNullOrWhiteSpace($pluginSlug) -and [string]::IsNullOrWhiteSpace($pluginPath)) {
        Write-MDWResult -Status "FAIL" -Message "Plugin slug or plugin path is required."
        return
    }

    if ($isFix) {
        if ([string]::IsNullOrWhiteSpace($expectedPrefix)) {
            Write-MDWResult -Status "FAIL" -Message "Prefix is required. Use: mdw compliance fix <plugin-slug> --prefix <prefix>"
            return
        }

        $fixResult = Invoke-MDWComplianceFixService `
            -PluginSlug $pluginSlug `
            -PluginPath $pluginPath `
            -ExpectedPrefix $expectedPrefix `
            -WhatIf:$whatIf

        Write-MDWComplianceFixReport -Result $fixResult
        return
    }

    $result = Invoke-MDWComplianceService -PluginSlug $pluginSlug -PluginPath $pluginPath -ExpectedPrefix $expectedPrefix
    Write-MDWComplianceReport -Result $result
}



