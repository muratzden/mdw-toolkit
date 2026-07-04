<#
MDW Compliance Prefix Fixer
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Test-MDWComplianceFixablePhpFile {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    $normalized = $Path -replace '/', '\'
    $blockedSegments = @("\.git\", "\.github\", "\vendor\", "\node_modules\")

    foreach ($segment in $blockedSegments) {
        if ($normalized.IndexOf($segment, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            return $false
        }
    }

    return ($Path -like "*.php")
}

function Convert-MDWCompliancePrefixToPascalPrefix {
    [CmdletBinding()]
    param(
        [string] $Prefix
    )

    $trimmed = $Prefix.Trim("_".ToCharArray())
    $parts = @($trimmed -split "_" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $converted = New-Object System.Collections.Generic.List[string]

    foreach ($part in $parts) {
        if ($part -eq "craftcommercekit") {
            $converted.Add("CraftCommerceKit")
        }
        else {
            $converted.Add($part.Substring(0, 1).ToUpperInvariant() + $part.Substring(1).ToLowerInvariant())
        }
    }

    return (($converted.ToArray() -join "_") + "_")
}

function Get-MDWComplianceFixReplacementValue {
    [CmdletBinding()]
    param(
        [string] $CurrentValue,
        [string] $RecommendedPrefix
    )

    if ([string]::IsNullOrWhiteSpace($CurrentValue) -or [string]::IsNullOrWhiteSpace($RecommendedPrefix)) {
        return $null
    }

    $candidate = Get-MDWCompliancePrefixCandidate -Value $CurrentValue

    if ([string]::IsNullOrWhiteSpace($candidate)) {
        return $RecommendedPrefix
    }

    $suffix = ""

    if ($CurrentValue.Length -gt $candidate.Length) {
        $suffix = $CurrentValue.Substring($candidate.Length)
    }

    $prefix = $RecommendedPrefix

    if ($CurrentValue -cmatch '^[A-Z0-9_]+$') {
        $prefix = $RecommendedPrefix.ToUpperInvariant()
    }
    elseif ($CurrentValue -cmatch '^[A-Z][A-Za-z0-9_]*$') {
        $prefix = Convert-MDWCompliancePrefixToPascalPrefix -Prefix $RecommendedPrefix
    }

    return ("{0}{1}" -f $prefix, $suffix)
}

function Get-MDWCompliancePrefixFixPlan {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix
    )

    $prefixResult = Invoke-MDWCompliancePrefixValidator `
        -PluginSlug $PluginSlug `
        -PluginPath $PluginPath `
        -ExpectedPrefix $ExpectedPrefix

    $plan = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($finding in @($prefixResult.Findings)) {
        if ($finding.Status -ne "FAIL" -and $finding.Status -ne "WARN") {
            continue
        }

        if ([string]::IsNullOrWhiteSpace([string] $finding.CurrentValue)) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace([string] $finding.File) -or -not (Test-MDWComplianceFixablePhpFile -Path $finding.File)) {
            continue
        }

        if ($finding.CurrentValue -eq $PluginSlug) {
            continue
        }

        $replacement = Get-MDWComplianceFixReplacementValue -CurrentValue $finding.CurrentValue -RecommendedPrefix $ExpectedPrefix

        if ([string]::IsNullOrWhiteSpace($replacement) -or $replacement -eq $finding.CurrentValue) {
            continue
        }

        $key = ("{0}|{1}|{2}" -f $finding.File, $finding.CurrentValue, $replacement)

        if ($seen.ContainsKey($key)) {
            continue
        }

        $seen[$key] = $true
        $plan.Add(@{
            File             = $finding.File
            CurrentValue     = $finding.CurrentValue
            RecommendedValue = $replacement
            Rule             = $finding.Rule
            Line             = $finding.Line
        })
    }

    return @($plan.ToArray())
}

function Invoke-MDWCompliancePrefixFixer {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix,
        [switch] $WhatIf
    )

    $plan = @(Get-MDWCompliancePrefixFixPlan -PluginSlug $PluginSlug -PluginPath $PluginPath -ExpectedPrefix $ExpectedPrefix)
    $changes = New-Object System.Collections.Generic.List[object]
    $files = @($plan | ForEach-Object { $_["File"] } | Sort-Object -Unique)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    foreach ($file in $files) {
        $content = [System.IO.File]::ReadAllText($file)
        $updatedContent = $content
        $fileReplacementCount = 0
        $filePlan = @($plan | Where-Object { $_["File"] -eq $file } | Sort-Object { ([string] $_["CurrentValue"]).Length } -Descending)

        foreach ($item in $filePlan) {
            $pattern = [regex]::Escape([string] $item["CurrentValue"])
            $matches = [regex]::Matches($updatedContent, $pattern)

            if ($matches.Count -le 0) {
                continue
            }

            $updatedContent = [regex]::Replace($updatedContent, $pattern, [System.Text.RegularExpressions.MatchEvaluator] { param($match) [string] $item["RecommendedValue"] })
            $fileReplacementCount += $matches.Count
        }

        if ($fileReplacementCount -gt 0) {
            if (-not $WhatIf) {
                [System.IO.File]::WriteAllText($file, $updatedContent, $utf8NoBom)
            }

            $changes.Add(@{
                File             = $file
                ReplacementCount = $fileReplacementCount
                WhatIf           = [bool] $WhatIf
            })
        }
    }

    return @{
        ChangedFiles     = @($changes.ToArray())
        ReplacementCount = (@($changes.ToArray()) | ForEach-Object { $_.ReplacementCount } | Measure-Object -Sum).Sum
        WhatIf           = [bool] $WhatIf
    }
}

