# Requires -Modules Pester

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $repositoryRoot "core\bootstrap.ps1")
foreach ($validatorFile in (Get-MDWComplianceValidatorFiles)) {
    . $validatorFile
}

function New-MDWCompliancePesterPlugin {
    param(
        [string] $Name,
        [string] $PhpCode
    )

    $basePath = Join-Path ([System.IO.Path]::GetTempPath()) ("mdw-compliance-{0}-{1}" -f $Name, ([guid]::NewGuid().ToString("N")))
    New-Item -ItemType Directory -Path $basePath -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $basePath ("{0}.php" -f $Name)) -Value $PhpCode -Encoding ASCII
    return $basePath
}

function Remove-MDWCompliancePesterPlugin {
    param(
        [string] $Path
    )

    if (-not [string]::IsNullOrWhiteSpace($Path) -and (Test-Path -LiteralPath $Path)) {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "MDW Compliance Foundation" {
    It "returns the shared compliance result object" {
        $fixture = Join-Path $repositoryRoot "tests\fixtures\valid-plugin"
        $result = Invoke-MDWComplianceService -PluginSlug "valid-plugin" -PluginPath $fixture

        $result.ContainsKey("Passed") | Should Be $true
        $result.ContainsKey("Failed") | Should Be $true
        $result.ContainsKey("Warnings") | Should Be $true
        $result.ContainsKey("Findings") | Should Be $true
    }

    It "reports missing plugin headers as failures" {
        $fixture = Join-Path $repositoryRoot "tests\fixtures\missing-header"
        $result = Invoke-MDWComplianceService -PluginSlug "missing-header" -PluginPath $fixture

        $result.Passed | Should Be $false
        ($result.Failed -gt 0) | Should Be $true
    }
}

Describe "MDW Compliance Prefix Validator" {
    It "fails unsafe short prefixes" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-short" -PhpCode @"
<?php
function abc_run() {}
"@

        try {
            $result = Invoke-MDWCompliancePrefixValidator -PluginSlug "prefix-short" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_"
            $matches = @($result.Findings | Where-Object { $_.Rule -eq "Prefix.TooShort" -and $_.Status -eq "FAIL" })
            ($matches.Count -gt 0) | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }

    It "fails wp_ prefixes" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-wp" -PhpCode @"
<?php
function wp_bad_prefix() {}
"@

        try {
            $result = Invoke-MDWCompliancePrefixValidator -PluginSlug "prefix-wp" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_"
            $matches = @($result.Findings | Where-Object { $_.Rule -eq "Prefix.Reserved" -and $_.Status -eq "FAIL" })
            ($matches.Count -gt 0) | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }

    It "fails CCK_RF prefixes" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-cck-rf" -PhpCode @"
<?php
define('CCK_RF_VERSION', '1.0.0');
"@

        try {
            $result = Invoke-MDWCompliancePrefixValidator -PluginSlug "prefix-cck-rf" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_"
            $matches = @($result.Findings | Where-Object { $_.Rule -eq "Prefix.CCKAbbreviation" -and $_.Status -eq "FAIL" })
            ($matches.Count -gt 0) | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }

    It "passes craftcommercekit_reviewflow_ prefixes" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-safe" -PhpCode @"
<?php
class CraftCommerceKit_ReviewFlow_Admin {}
function craftcommercekit_reviewflow_boot() {}
define('CRAFTCOMMERCEKIT_REVIEWFLOW_VERSION', '1.0.0');
update_option('craftcommercekit_reviewflow_settings', array());
register_setting('craftcommercekit_reviewflow_group', 'craftcommercekit_reviewflow_option');
add_action('wp_ajax_craftcommercekit_reviewflow_save', 'craftcommercekit_reviewflow_boot');
wp_create_nonce('craftcommercekit_reviewflow_nonce');
wp_enqueue_script('craftcommercekit_reviewflow_admin');
wp_localize_script('craftcommercekit_reviewflow_admin', 'CraftCommerceKit_ReviewFlow_Data', array());
update_post_meta(1, 'craftcommercekit_reviewflow_meta', 'yes');
`$GLOBALS['craftcommercekit_reviewflow_state'] = array();
"@

        try {
            $result = Invoke-MDWCompliancePrefixValidator -PluginSlug "prefix-safe" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_"
            $failures = @($result.Findings | Where-Object { $_.Status -eq "FAIL" -or $_.Status -eq "WARN" })
            $passes = @($result.Findings | Where-Object { $_.Rule -eq "Prefix.Result" -and $_.Status -eq "OK" })
            $failures.Count | Should Be 0
            ($passes.Count -gt 0) | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }

    It "returns structured prefix findings" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-structured" -PhpCode @"
<?php
function wp_structured_check() {}
"@

        try {
            $result = Invoke-MDWCompliancePrefixValidator -PluginSlug "prefix-structured" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_"
            $finding = @($result.Findings | Where-Object { $_.Status -eq "FAIL" })[0]

            $finding.ContainsKey("Rule") | Should Be $true
            $finding.ContainsKey("Severity") | Should Be $true
            $finding.ContainsKey("Status") | Should Be $true
            $finding.ContainsKey("Message") | Should Be $true
            $finding.ContainsKey("File") | Should Be $true
            $finding.ContainsKey("Line") | Should Be $true
            $finding.ContainsKey("CurrentValue") | Should Be $true
            $finding.ContainsKey("RecommendedValue") | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }
}

Describe "MDW Compliance Prefix Fixer" {
    It "dry-run reports replacements without modifying files" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-fix-dry" -PhpCode @"
<?php
function abc_run() {}
"@
        $file = Join-Path $pluginPath "prefix-fix-dry.php"

        try {
            $result = Invoke-MDWComplianceFixService -PluginSlug "prefix-fix-dry" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_" -WhatIf
            $content = Get-Content -LiteralPath $file -Raw

            ($result.ReplacementCount -gt 0) | Should Be $true
            $result.WhatIf | Should Be $true
            ($content -match "abc_run") | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }

    It "apply mode is enabled and creates a backup" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-fix-apply" -PhpCode @"
<?php
function abc_run() {}
"@
        $file = Join-Path $pluginPath "prefix-fix-apply.php"

        try {
            $result = Invoke-MDWComplianceFixService -PluginSlug "prefix-fix-apply" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_"
            $content = Get-Content -LiteralPath $file -Raw

            ($result.ReplacementCount -gt 0) | Should Be $true
            $result.WhatIf | Should Be $false
            (Test-Path -LiteralPath $result.BackupPath -PathType Container) | Should Be $true
            ($content -match "craftcommercekit_reviewflow_run") | Should Be $true
            ($content -match "abc_run") | Should Be $false
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }

    It "apply mode changes only validator-confirmed semantic identifiers" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-fix-semantic" -PhpCode @"
<?php
/*
Plugin Name: Semantic Safety
Text Domain: prefix-fix-semantic
abc_run comment should remain.
*/
require_once __DIR__ . '/abc-file.php';
echo '<div class="abc-card" id="abc-id" data-abc="yes"></div>';
`$selector = '.abc-card #abc-id [data-abc="yes"]';
__('abc translation string', 'prefix-fix-semantic');
function abc_run() {}
update_option('abc_option', 'yes');
"@
        $file = Join-Path $pluginPath "prefix-fix-semantic.php"

        try {
            $result = Invoke-MDWComplianceFixService -PluginSlug "prefix-fix-semantic" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_"
            $content = Get-Content -LiteralPath $file -Raw

            $result.ReplacementCount | Should Be 2
            ($content -match "function craftcommercekit_reviewflow_run") | Should Be $true
            ($content -match "update_option\('craftcommercekit_reviewflow_option'") | Should Be $true
            ($content -match "abc_run comment should remain") | Should Be $true
            ($content -match "abc-file.php") | Should Be $true
            ($content -match "abc-card") | Should Be $true
            ($content -match "abc-id") | Should Be $true
            ($content -match "data-abc") | Should Be $true
            ($content -match "abc translation string") | Should Be $true
            ($content -match "Text Domain: prefix-fix-semantic") | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }

    It "does not rename files or folders" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-fix-name" -PhpCode @"
<?php
function abc_main() {}
"@
        $file = Join-Path $pluginPath "prefix-fix-name.php"

        try {
            Invoke-MDWComplianceFixService -PluginSlug "prefix-fix-name" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_" | Out-Null
            (Test-Path -LiteralPath $file -PathType Leaf) | Should Be $true
            (Split-Path -Path $pluginPath -Leaf) -like "mdw-compliance-prefix-fix-name-*" | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }

    It "does not include vendor files in apply plan" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-fix-vendor" -PhpCode @"
<?php
function abc_main() {}
"@
        $vendorPath = Join-Path $pluginPath "vendor"
        New-Item -ItemType Directory -Path $vendorPath -Force | Out-Null
        $vendorFile = Join-Path $vendorPath "third-party.php"
        Set-Content -LiteralPath $vendorFile -Value "<?php`nfunction abc_vendor() {}" -Encoding ASCII

        try {
            $result = Invoke-MDWComplianceFixService -PluginSlug "prefix-fix-vendor" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_"
            $vendorContent = Get-Content -LiteralPath $vendorFile -Raw
            $result.ReplacementCount | Should Be 1
            ($vendorContent -match "abc_vendor") | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }

    It "does not replace partial substrings inside unrelated values" {
        $pluginPath = New-MDWCompliancePesterPlugin -Name "prefix-fix-partial" -PhpCode @"
<?php
`$value = 'prefix abc_run suffix';
function abc_run() {}
"@
        $file = Join-Path $pluginPath "prefix-fix-partial.php"

        try {
            Invoke-MDWComplianceFixService -PluginSlug "prefix-fix-partial" -PluginPath $pluginPath -ExpectedPrefix "craftcommercekit_reviewflow_" | Out-Null
            $content = Get-Content -LiteralPath $file -Raw
            ($content -match "prefix abc_run suffix") | Should Be $true
            ($content -match "function craftcommercekit_reviewflow_run") | Should Be $true
        }
        finally {
            Remove-MDWCompliancePesterPlugin -Path $pluginPath
        }
    }
}
