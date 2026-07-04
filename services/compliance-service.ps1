<#
MDW Compliance Service
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWComplianceValidatorFiles {
    [CmdletBinding()]
    param()

    $validatorRoot = Join-Path (Join-Path (Get-MDWRootPath) "validators") "compliance"

    if (-not (Test-Path -LiteralPath $validatorRoot -PathType Container)) {
        return @()
    }

    $files = Get-ChildItem -LiteralPath $validatorRoot -Filter "*.ps1" -File -ErrorAction SilentlyContinue | Sort-Object Name
    return @($files | Select-Object -ExpandProperty FullName)
}

function New-MDWComplianceResult {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix,
        [object[]] $Findings
    )

    $safeFindings = @($Findings)
    $failed = @($safeFindings | Where-Object { $_.Severity -eq "Error" -or $_.Status -eq "FAIL" }).Count
    $warnings = @($safeFindings | Where-Object { $_.Severity -eq "Warning" -or $_.Status -eq "WARN" }).Count

    return @{
        Passed        = ($failed -eq 0)
        Failed        = $failed
        Warnings      = $warnings
        Findings      = $safeFindings
        PluginSlug    = $PluginSlug
        PluginPath    = $PluginPath
        ExpectedPrefix = $ExpectedPrefix
    }
}

function Resolve-MDWComplianceScope {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath
    )

    $resolvedSlug = $PluginSlug
    $resolvedPath = $PluginPath

    if (-not [string]::IsNullOrWhiteSpace($resolvedPath)) {
        if (Test-Path -LiteralPath $resolvedPath -PathType Container) {
            $resolvedPath = (Resolve-Path -LiteralPath $resolvedPath).ProviderPath
        }

        if ([string]::IsNullOrWhiteSpace($resolvedSlug)) {
            $resolvedSlug = Split-Path -Path $resolvedPath -Leaf
        }
    }
    else {
        $resolvedPath = Resolve-MDWPluginPath -PluginSlug $resolvedSlug
    }

    return @{
        PluginSlug = $resolvedSlug
        PluginPath = $resolvedPath
    }
}

function Invoke-MDWComplianceService {
    [CmdletBinding()]
    param(
        [string] $PluginSlug,
        [string] $PluginPath,
        [string] $ExpectedPrefix
    )

    foreach ($validatorFile in (Get-MDWComplianceValidatorFiles)) {
        . $validatorFile
    }

    $scope = Resolve-MDWComplianceScope -PluginSlug $PluginSlug -PluginPath $PluginPath
    $findings = New-Object System.Collections.Generic.List[object]

    if (-not (Get-Command Invoke-MDWComplianceValidator -ErrorAction SilentlyContinue)) {
        $findings.Add(@{
            Rule             = "Compliance.Validator"
            Severity         = "Error"
            Status           = "FAIL"
            Message          = "Compliance validator is not available."
            File             = $null
            Line             = $null
            CurrentValue     = $null
            RecommendedValue = $null
        })

        return New-MDWComplianceResult -PluginSlug $scope.PluginSlug -PluginPath $scope.PluginPath -ExpectedPrefix $ExpectedPrefix -Findings @($findings.ToArray())
    }

    $validatorResult = Invoke-MDWComplianceValidator -PluginSlug $scope.PluginSlug -PluginPath $scope.PluginPath

    foreach ($finding in @($validatorResult.Findings)) {
        $findings.Add($finding)
    }

    if (Get-Command Invoke-MDWCompliancePrefixValidator -ErrorAction SilentlyContinue) {
        $prefixResult = Invoke-MDWCompliancePrefixValidator `
            -PluginSlug $scope.PluginSlug `
            -PluginPath $scope.PluginPath `
            -ExpectedPrefix $ExpectedPrefix

        foreach ($finding in @($prefixResult.Findings)) {
            $findings.Add($finding)
        }
    }

    return New-MDWComplianceResult -PluginSlug $scope.PluginSlug -PluginPath $scope.PluginPath -ExpectedPrefix $ExpectedPrefix -Findings @($findings.ToArray())
}
