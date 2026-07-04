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
        elseif ($part -eq "reviewflow") {
            $converted.Add("ReviewFlow")
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
        [string] $RecommendedPrefix,
        [string] $Kind
    )

    if ([string]::IsNullOrWhiteSpace($CurrentValue) -or [string]::IsNullOrWhiteSpace($RecommendedPrefix)) {
        return $null
    }

    $candidate = Get-MDWCompliancePrefixCandidate -Value $CurrentValue

    if ($CurrentValue.StartsWith("CCK_RF_", [System.StringComparison]::OrdinalIgnoreCase)) {
        $candidate = $CurrentValue.Substring(0, 7)
    }
    elseif ($CurrentValue.Equals("CCK_RF", [System.StringComparison]::OrdinalIgnoreCase)) {
        $candidate = $CurrentValue
    }

    if ([string]::IsNullOrWhiteSpace($candidate)) {
        return $RecommendedPrefix
    }

    $suffix = ""

    if ($CurrentValue.Length -gt $candidate.Length) {
        $suffix = $CurrentValue.Substring($candidate.Length)
    }

    switch ($Kind) {
        "constant" {
            return ("{0}{1}" -f $RecommendedPrefix.ToUpperInvariant(), $suffix.ToUpperInvariant())
        }
        "PHP class" {
            return ("{0}{1}" -f (Convert-MDWCompliancePrefixToPascalPrefix -Prefix $RecommendedPrefix), $suffix)
        }
        default {
            if ($CurrentValue.Equals("CCK_RF", [System.StringComparison]::OrdinalIgnoreCase)) {
                return $RecommendedPrefix.TrimEnd("_".ToCharArray())
            }

            return ("{0}{1}" -f $RecommendedPrefix.ToLowerInvariant(), $suffix)
        }
    }
}
function Get-MDWComplianceFixKind {
    [CmdletBinding()]
    param(
        [object] $Finding
    )

    $message = [string] $Finding.Message

    if ($message -match ' for (.+)\.$') {
        return $matches[1]
    }

    if ($message -match ' in (.+)\.$') {
        return $matches[1]
    }

    return "unknown"
}

function Add-MDWComplianceSkippedFix {
    [CmdletBinding()]
    param(
        [System.Collections.Generic.List[object]] $Skipped,
        [object] $Finding,
        [string] $Reason
    )

    $Skipped.Add(@{
        File         = $Finding.File
        Line         = $Finding.Line
        CurrentValue = $Finding.CurrentValue
        Reason       = $Reason
    })
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
    $skipped = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($finding in @($prefixResult.Findings)) {
        if ($finding.Status -ne "FAIL") {
            continue
        }

        if ([string]::IsNullOrWhiteSpace([string] $finding.CurrentValue)) {
            Add-MDWComplianceSkippedFix -Skipped $skipped -Finding $finding -Reason "Missing current value metadata."
            continue
        }

        if ([string]::IsNullOrWhiteSpace([string] $finding.File) -or -not (Test-MDWComplianceFixablePhpFile -Path $finding.File)) {
            Add-MDWComplianceSkippedFix -Skipped $skipped -Finding $finding -Reason "File is not a fixable PHP source file."
            continue
        }

        if ($null -eq $finding.Line -or [int] $finding.Line -le 0) {
            Add-MDWComplianceSkippedFix -Skipped $skipped -Finding $finding -Reason "Missing line metadata."
            continue
        }

        if ($finding.CurrentValue -eq $PluginSlug) {
            Add-MDWComplianceSkippedFix -Skipped $skipped -Finding $finding -Reason "Plugin slug is never modified."
            continue
        }

        if ($finding.CurrentValue -like "__*") {
            Add-MDWComplianceSkippedFix -Skipped $skipped -Finding $finding -Reason "Magic and private underscore identifiers are skipped."
            continue
        }

        $kind = Get-MDWComplianceFixKind -Finding $finding

        if ($kind -eq "PHP function" -and $finding.Rule -eq "Prefix.TooShort" -and $finding.CurrentValue -notlike "CCK_*") {
            Add-MDWComplianceSkippedFix -Skipped $skipped -Finding $finding -Reason "Generic short PHP function or method name requires manual review."
            continue
        }

        if ($kind -eq "meta key" -and ([string] $finding.CurrentValue).StartsWith("_")) {
            Add-MDWComplianceSkippedFix -Skipped $skipped -Finding $finding -Reason "Private meta keys require manual migration review."
            continue
        }

        $replacement = Get-MDWComplianceFixReplacementValue -CurrentValue $finding.CurrentValue -RecommendedPrefix $ExpectedPrefix -Kind $kind

        if ([string]::IsNullOrWhiteSpace($replacement) -or $replacement -eq $finding.CurrentValue) {
            Add-MDWComplianceSkippedFix -Skipped $skipped -Finding $finding -Reason "Replacement could not be resolved safely."
            continue
        }

        $key = ("{0}|{1}|{2}|{3}|{4}" -f $finding.File, $finding.Line, $finding.CurrentValue, $replacement, $kind)

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
            Kind             = $kind
        })
    }

    return @{
        Items   = @($plan.ToArray())
        Skipped = @($skipped.ToArray())
    }
}

function Convert-MDWComplianceRegexReplacement {
    [CmdletBinding()]
    param(
        [string] $LineText,
        [string] $Pattern,
        [string] $RecommendedValue
    )

    $regex = New-Object System.Text.RegularExpressions.Regex($Pattern)
    $script:MDW_PREFIX_FIX_REPLACED = $false

    $result = $regex.Replace($LineText, [System.Text.RegularExpressions.MatchEvaluator] {
        param($match)

        if ($script:MDW_PREFIX_FIX_REPLACED) {
            return $match.Value
        }

        $script:MDW_PREFIX_FIX_REPLACED = $true
        return ("{0}{1}{2}" -f $match.Groups[1].Value, $RecommendedValue, $match.Groups[2].Value)
    }, 1)

    $replaced = [bool] $script:MDW_PREFIX_FIX_REPLACED
    $script:MDW_PREFIX_FIX_REPLACED = $false

    return @{
        Text     = $result
        Replaced = $replaced
    }
}

function Set-MDWComplianceTokenOnLine {
    [CmdletBinding()]
    param(
        [string] $LineText,
        [string] $CurrentValue,
        [string] $RecommendedValue,
        [string] $Kind
    )

    $value = [regex]::Escape($CurrentValue)
    $patterns = @()

    switch ($Kind) {
        "PHP class" {
            $patterns = @("(\b(?:class|interface|trait)\s+)${value}(\b)")
        }
        "PHP function" {
            $patterns = @("(\bfunction\s+)${value}(\s*\()")
        }
        "constant" {
            $patterns = @(
                "(\bconst\s+)${value}(\b)",
                "(\bdefine\s*\(\s*['\""'])${value}(['\""'])"
            )
        }
        "option name" {
            $patterns = @("(\b(?:get_option|update_option|add_option|delete_option)\s*\(\s*['\""'])${value}(['\""'])")
        }
        "register_setting group" {
            $patterns = @("(\bregister_setting\s*\(\s*['\""'])${value}(['\""'])")
        }
        "register_setting option" {
            $patterns = @("(\bregister_setting\s*\(\s*['\""'][^'\""']+['\""']\s*,\s*['\""'])${value}(['\""'])")
        }
        "wp_ajax hook" {
            $patterns = @("(\badd_action\s*\(\s*['\""']wp_ajax_)${value}(['\""'])")
        }
        "wp_ajax_nopriv hook" {
            $patterns = @("(\badd_action\s*\(\s*['\""']wp_ajax_nopriv_)${value}(['\""'])")
        }
        "nonce action" {
            $patterns = @("(\b(?:wp_create_nonce|check_admin_referer|check_ajax_referer)\s*\(\s*['\""'])${value}(['\""'])")
        }
        "script/style handle" {
            $patterns = @("(\b(?:wp_enqueue_script|wp_register_script|wp_enqueue_style|wp_register_style)\s*\(\s*['\""'])${value}(['\""'])")
        }
        "localized object" {
            $patterns = @("(\bwp_localize_script\s*\(\s*[^,]+,\s*['\""'])${value}(['\""'])")
        }
        "meta key" {
            $patterns = @("(\b(?:get_post_meta|update_post_meta|add_post_meta|delete_post_meta|get_user_meta|update_user_meta|add_user_meta|delete_user_meta)\s*\(\s*[^,]+,\s*['\""'])${value}(['\""'])")
        }
        "global variable" {
            $patterns = @(
                "(\`$GLOBALS\s*\[\s*['\""'])${value}(['\""']\s*\])",
                "(\bglobal\s+\$)${value}(\b)"
            )
        }
        default {
            return @{ Text = $LineText; Replaced = $false; Reason = "Unsupported semantic context: $Kind" }
        }
    }

    foreach ($pattern in $patterns) {
        $result = Convert-MDWComplianceRegexReplacement -LineText $LineText -Pattern $pattern -RecommendedValue $RecommendedValue

        if ($result.Replaced) {
            return @{ Text = $result.Text; Replaced = $true; Reason = $null }
        }
    }

    return @{ Text = $LineText; Replaced = $false; Reason = "Exact semantic token was not found on the reported line." }
}

function Get-MDWComplianceFileEncoding {
    [CmdletBinding()]
    param(
        [string] $Path
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)

    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        return New-Object System.Text.UTF8Encoding($true)
    }

    return New-Object System.Text.UTF8Encoding($false)
}

function Invoke-MDWCompliancePrefixFixer {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix,
        [switch] $WhatIf
    )

    $fixPlan = Get-MDWCompliancePrefixFixPlan -PluginSlug $PluginSlug -PluginPath $PluginPath -ExpectedPrefix $ExpectedPrefix
    $plan = @($fixPlan["Items"])
    $skipped = New-Object System.Collections.Generic.List[object]

    foreach ($skip in @($fixPlan["Skipped"])) {
        $skipped.Add($skip)
    }

    $changes = New-Object System.Collections.Generic.List[object]
    $files = @($plan | ForEach-Object { $_["File"] } | Sort-Object -Unique)

    foreach ($file in $files) {
        $originalText = [System.IO.File]::ReadAllText($file)
        $lineEnding = "`n"

        if ($originalText -match "`r`n") {
            $lineEnding = "`r`n"
        }

        $lines = @([System.IO.File]::ReadAllLines($file))
        $fileReplacementCount = 0
        $filePlan = @($plan | Where-Object { $_["File"] -eq $file } | Sort-Object { [int] $_["Line"] })

        foreach ($item in $filePlan) {
            $lineNumber = [int] $item["Line"]

            if ($lineNumber -le 0 -or $lineNumber -gt $lines.Count) {
                $skipped.Add(@{
                    File         = $file
                    Line         = $lineNumber
                    CurrentValue = $item["CurrentValue"]
                    Reason       = "Reported line is outside file bounds."
                })
                continue
            }

            $before = $lines[$lineNumber - 1]
            $result = Set-MDWComplianceTokenOnLine `
                -LineText $before `
                -CurrentValue ([string] $item["CurrentValue"]) `
                -RecommendedValue ([string] $item["RecommendedValue"]) `
                -Kind ([string] $item["Kind"])

            if ($result.Replaced) {
                $lines[$lineNumber - 1] = $result.Text
                $fileReplacementCount++
            }
            else {
                $skipped.Add(@{
                    File         = $file
                    Line         = $lineNumber
                    CurrentValue = $item["CurrentValue"]
                    Reason       = $result.Reason
                })
            }
        }

        if ($fileReplacementCount -gt 0) {
            if (-not $WhatIf) {
                $encoding = Get-MDWComplianceFileEncoding -Path $file
                [System.IO.File]::WriteAllText($file, ($lines -join $lineEnding), $encoding)
            }

            $changes.Add(@{
                File             = $file
                ReplacementCount = $fileReplacementCount
                WhatIf           = [bool] $WhatIf
            })
        }
    }

    $replacementCount = 0

    foreach ($change in @($changes.ToArray())) {
        $replacementCount += [int] $change.ReplacementCount
    }

    return @{
        ChangedFiles     = @($changes.ToArray())
        ReplacementCount = $replacementCount
        Skipped          = @($skipped.ToArray())
        SkippedCount     = $skipped.Count
        WhatIf           = [bool] $WhatIf
    }
}



