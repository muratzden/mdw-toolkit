<#
MDW Compliance Prefix Validator
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWComplianceRecommendedPrefix {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $ExpectedPrefix
    )

    if (-not [string]::IsNullOrWhiteSpace($ExpectedPrefix)) {
        return $ExpectedPrefix
    }

    $key = $PluginSlug.ToLowerInvariant() -replace "[^a-z0-9]+", "_"
    $key = $key.Trim("_".ToCharArray())

    if ([string]::IsNullOrWhiteSpace($key)) {
        return "plugin_specific_"
    }

    if ($key -like "craft_commerce_kit*") {
        $pluginKey = $key -replace "^craft_commerce_kit_?", ""

        if ([string]::IsNullOrWhiteSpace($pluginKey)) {
            $pluginKey = "plugin"
        }

        return ("craftcommercekit_{0}_" -f $pluginKey)
    }

    return ("{0}_" -f $key)
}

function Get-MDWCompliancePrefixCandidate {
    [CmdletBinding()]
    param(
        [string] $Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    if ($Value.StartsWith("__")) {
        return "__"
    }

    if ($Value.StartsWith("_")) {
        return "_"
    }

    $underscoreIndex = $Value.IndexOf("_")
    $dashIndex = $Value.IndexOf("-")
    $index = -1

    if ($underscoreIndex -ge 0 -and $dashIndex -ge 0) {
        $index = [Math]::Min($underscoreIndex, $dashIndex)
    }
    elseif ($underscoreIndex -ge 0) {
        $index = $underscoreIndex
    }
    elseif ($dashIndex -ge 0) {
        $index = $dashIndex
    }

    if ($index -lt 0) {
        return $Value
    }

    return $Value.Substring(0, $index + 1)
}

function Get-MDWComplianceReplacementValue {
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

    $suffix = $CurrentValue

    if ($CurrentValue.Length -gt $candidate.Length) {
        $suffix = $CurrentValue.Substring($candidate.Length)
    }

    return ("{0}{1}" -f $RecommendedPrefix, $suffix)
}

function Test-MDWComplianceAllowedPrefix {
    [CmdletBinding()]
    param(
        [string] $Value,
        [string] $ExpectedPrefix,
        [string] $RecommendedPrefix
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    $allowedPrefixes = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($ExpectedPrefix)) {
        $allowedPrefixes.Add($ExpectedPrefix)
        $allowedPrefixes.Add($ExpectedPrefix.ToUpperInvariant())
    }

    if (-not [string]::IsNullOrWhiteSpace($RecommendedPrefix)) {
        $allowedPrefixes.Add($RecommendedPrefix)
        $allowedPrefixes.Add($RecommendedPrefix.ToUpperInvariant())
    }

    foreach ($prefix in $allowedPrefixes) {
        if (-not [string]::IsNullOrWhiteSpace($prefix) -and $Value.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function New-MDWCompliancePrefixFinding {
    [CmdletBinding()]
    param(
        [string] $Rule,
        [ValidateSet("Info", "Warning", "Error")]
        [string] $Severity,
        [ValidateSet("OK", "WARN", "FAIL", "INFO")]
        [string] $Status,
        [string] $Message,
        [string] $File,
        [int] $Line,
        [string] $CurrentValue,
        [string] $RecommendedValue
    )

    return @{
        Rule             = $Rule
        Severity         = $Severity
        Status           = $Status
        Message          = $Message
        File             = $File
        Line             = $Line
        CurrentValue     = $CurrentValue
        RecommendedValue = $RecommendedValue
    }
}

function Add-MDWCompliancePrefixToken {
    [CmdletBinding()]
    param(
        [System.Collections.Generic.List[object]] $Tokens,
        [string] $Kind,
        [string] $Value,
        [string] $File,
        [int] $Line
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return
    }

    $Tokens.Add(@{
        Kind  = $Kind
        Value = $Value
        File  = $File
        Line  = $Line
    })
}

function Get-MDWCompliancePrefixTokensFromLine {
    [CmdletBinding()]
    param(
        [string] $LineText,
        [string] $File,
        [int] $LineNumber
    )

    $tokens = New-Object System.Collections.Generic.List[object]

    foreach ($match in [regex]::Matches($LineText, '\b(?:class|interface|trait)\s+([A-Za-z_][A-Za-z0-9_]*)')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "PHP class" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\bfunction\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "PHP function" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\bconst\s+([A-Za-z_][A-Za-z0-9_]*)\b')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "constant" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\bdefine\s*\(\s*[''"]([^''"]+)[''"]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "constant" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\b(?:get_option|update_option|add_option|delete_option)\s*\(\s*[''"]([^''"]+)[''"]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "option name" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\bregister_setting\s*\(\s*[''"]([^''"]+)[''"]\s*,\s*[''"]([^''"]+)[''"]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "register_setting group" -Value $match.Groups[1].Value -File $File -Line $LineNumber
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "register_setting option" -Value $match.Groups[2].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\badd_action\s*\(\s*[''"]wp_ajax_nopriv_([^''"]+)[''"]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "wp_ajax_nopriv hook" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\badd_action\s*\(\s*[''"]wp_ajax_([^''"]+)[''"]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "wp_ajax hook" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\b(?:wp_create_nonce|check_admin_referer|check_ajax_referer)\s*\(\s*[''"]([^''"]+)[''"]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "nonce action" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\b(?:wp_enqueue_script|wp_register_script|wp_enqueue_style|wp_register_style)\s*\(\s*[''"]([^''"]+)[''"]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "script/style handle" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\bwp_localize_script\s*\(\s*[^,]+,\s*[''"]([^''"]+)[''"]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "localized object" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\b(?:get_post_meta|update_post_meta|add_post_meta|delete_post_meta|get_user_meta|update_user_meta|add_user_meta|delete_user_meta)\s*\(\s*[^,]+,\s*[''"]([^''"]+)[''"]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "meta key" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\$GLOBALS\s*\[\s*[''"]([^''"]+)[''"]\s*\]')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "global variable" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    foreach ($match in [regex]::Matches($LineText, '\bglobal\s+\$([A-Za-z_][A-Za-z0-9_]*)')) {
        Add-MDWCompliancePrefixToken -Tokens $tokens -Kind "global variable" -Value $match.Groups[1].Value -File $File -Line $LineNumber
    }

    return @($tokens.ToArray())
}

function Get-MDWCompliancePrefixTokens {
    [CmdletBinding()]
    param(
        [string] $PluginPath
    )

    $tokens = New-Object System.Collections.Generic.List[object]
    $phpFiles = @(Get-ChildItem -LiteralPath $PluginPath -Filter "*.php" -File -Recurse -ErrorAction SilentlyContinue)

    foreach ($file in $phpFiles) {
        $lines = @(Get-Content -LiteralPath $file.FullName -ErrorAction SilentlyContinue)

        for ($index = 0; $index -lt $lines.Count; $index++) {
            $lineTokens = Get-MDWCompliancePrefixTokensFromLine -LineText $lines[$index] -File $file.FullName -LineNumber ($index + 1)

            foreach ($token in $lineTokens) {
                $tokens.Add($token)
            }
        }
    }

    return @($tokens.ToArray())
}

function Invoke-MDWCompliancePrefixValidator {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix
    )

    $findings = New-Object System.Collections.Generic.List[object]
    $recommendedPrefix = Get-MDWComplianceRecommendedPrefix -PluginSlug $PluginSlug -ExpectedPrefix $ExpectedPrefix

    if ([string]::IsNullOrWhiteSpace($PluginPath) -or -not (Test-Path -LiteralPath $PluginPath -PathType Container)) {
        $findings.Add((New-MDWCompliancePrefixFinding -Rule "Prefix.Path" -Severity "Error" -Status "FAIL" -Message "Plugin directory not found for prefix validation." -File $PluginPath -Line 0 -CurrentValue $null -RecommendedValue $recommendedPrefix))
        return @{ Findings = @($findings.ToArray()) }
    }

    $tokens = @(Get-MDWCompliancePrefixTokens -PluginPath $PluginPath)
    $detected = @{}

    if ($tokens.Count -eq 0) {
        $findings.Add((New-MDWCompliancePrefixFinding -Rule "Prefix.Scan" -Severity "Info" -Status "OK" -Message "No prefix-sensitive identifiers detected." -File $PluginPath -Line 0 -CurrentValue $null -RecommendedValue $recommendedPrefix))
        return @{ Findings = @($findings.ToArray()) }
    }

    foreach ($token in $tokens) {
        $value = [string] $token.Value
        $candidate = Get-MDWCompliancePrefixCandidate -Value $value
        $recommendedValue = Get-MDWComplianceReplacementValue -CurrentValue $value -RecommendedPrefix $recommendedPrefix

        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $key = $candidate.ToLowerInvariant()

            if (-not $detected.ContainsKey($key)) {
                $detected[$key] = $candidate
                $findings.Add((New-MDWCompliancePrefixFinding -Rule "Prefix.Candidate" -Severity "Info" -Status "INFO" -Message ("Detected prefix candidate: {0}" -f $candidate) -File $token.File -Line $token.Line -CurrentValue $value -RecommendedValue $recommendedPrefix))
            }
        }

        if (Test-MDWComplianceAllowedPrefix -Value $value -ExpectedPrefix $ExpectedPrefix -RecommendedPrefix $recommendedPrefix) {
            continue
        }

        if ($value.StartsWith("wp_", [System.StringComparison]::OrdinalIgnoreCase)) {
            $findings.Add((New-MDWCompliancePrefixFinding -Rule "Prefix.Reserved" -Severity "Error" -Status "FAIL" -Message ("Reserved WordPress prefix used in {0}." -f $token.Kind) -File $token.File -Line $token.Line -CurrentValue $value -RecommendedValue $recommendedValue))
            continue
        }

        if ($value.StartsWith("__") -or $value.StartsWith("_")) {
            $findings.Add((New-MDWCompliancePrefixFinding -Rule "Prefix.Private" -Severity "Error" -Status "FAIL" -Message ("Unsafe underscore prefix used in {0}." -f $token.Kind) -File $token.File -Line $token.Line -CurrentValue $value -RecommendedValue $recommendedValue))
            continue
        }

        $candidateText = [string] $candidate
        $candidateCore = $candidateText.TrimEnd("_".ToCharArray()).TrimEnd("-".ToCharArray())

        if ($candidateText.StartsWith("CCK_", [System.StringComparison]::OrdinalIgnoreCase)) {
            $findings.Add((New-MDWCompliancePrefixFinding -Rule "Prefix.CCKAbbreviation" -Severity "Error" -Status "FAIL" -Message ("CCK abbreviation is too short for {0}." -f $token.Kind) -File $token.File -Line $token.Line -CurrentValue $value -RecommendedValue $recommendedValue))
            continue
        }

        if ($candidateCore.Length -lt 4) {
            $findings.Add((New-MDWCompliancePrefixFinding -Rule "Prefix.TooShort" -Severity "Error" -Status "FAIL" -Message ("Prefix must be at least 4 characters for {0}." -f $token.Kind) -File $token.File -Line $token.Line -CurrentValue $value -RecommendedValue $recommendedValue))
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($ExpectedPrefix)) {
            $findings.Add((New-MDWCompliancePrefixFinding -Rule "Prefix.Expected" -Severity "Warning" -Status "WARN" -Message ("Identifier does not use the expected plugin prefix for {0}." -f $token.Kind) -File $token.File -Line $token.Line -CurrentValue $value -RecommendedValue $recommendedValue))
        }
    }

    if (@($findings.ToArray() | Where-Object { $_.Rule -like "Prefix.*" -and ($_.Status -eq "FAIL" -or $_.Status -eq "WARN") }).Count -eq 0) {
        $findings.Add((New-MDWCompliancePrefixFinding -Rule "Prefix.Result" -Severity "Info" -Status "OK" -Message "Prefix validation passed." -File $PluginPath -Line 0 -CurrentValue $null -RecommendedValue $recommendedPrefix))
    }

    return @{ Findings = @($findings.ToArray()) }
}
