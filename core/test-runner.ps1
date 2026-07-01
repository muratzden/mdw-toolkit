<#
MDW Test Runner
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function New-MDWTestResult {
    [CmdletBinding()]
    param(
        [string] $Name,
        [bool] $Passed,
        [double] $Duration,
        [string] $Message,
        [string] $Category
    )

    return @{
        Name     = $Name
        Passed   = $Passed
        Duration = $Duration
        Message  = $Message
        Category = $Category
    }
}

function Invoke-MDWTestFile {
    [CmdletBinding()]
    param(
        [string] $Path,
        [string] $Category
    )

    $testFileName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $startedAt = Get-Date

    try {
        $results = & $Path
        $duration = ((Get-Date) - $startedAt).TotalSeconds
        $normalizedResults = New-Object System.Collections.Generic.List[object]

        foreach ($result in @($results)) {
            if ($null -eq $result) {
                continue
            }

            if (-not $result.ContainsKey("Category")) {
                $result.Category = $Category
            }

            if (-not $result.ContainsKey("Duration")) {
                $result.Duration = $duration
            }

            $normalizedResults.Add($result)
        }

        if ($normalizedResults.Count -eq 0) {
            $normalizedResults.Add((New-MDWTestResult -Name $testFileName -Passed $true -Duration $duration -Message "" -Category $Category))
        }

        return @($normalizedResults.ToArray())
    }
    catch {
        $duration = ((Get-Date) - $startedAt).TotalSeconds

        return @(
            New-MDWTestResult -Name $testFileName -Passed $false -Duration $duration -Message $_.Exception.Message -Category $Category
        )
    }
}

function Invoke-MDWTestRunner {
    [CmdletBinding()]
    param(
        [string] $TestsRoot
    )

    if ([string]::IsNullOrWhiteSpace($TestsRoot)) {
        $TestsRoot = Join-Path (Get-MDWRootPath) "tests"
    }

    $startedAt = Get-Date
    $tests = New-Object System.Collections.Generic.List[object]
    $warnings = New-Object System.Collections.Generic.List[string]

    $categories = @(
        @{ Name = "Core"; Path = "core" }
        @{ Name = "Commands"; Path = "commands" }
        @{ Name = "Validators"; Path = "validators" }
        @{ Name = "Services"; Path = "services" }
    )

    foreach ($category in $categories) {
        $categoryPath = Join-Path $TestsRoot $category.Path

        if (-not (Test-Path -LiteralPath $categoryPath -PathType Container)) {
            $warnings.Add("Test category not found: $categoryPath")
            continue
        }

        $testFiles = Get-ChildItem -LiteralPath $categoryPath -Filter "*.tests.ps1" -File | Sort-Object Name

        foreach ($testFile in $testFiles) {
            $fileResults = Invoke-MDWTestFile -Path $testFile.FullName -Category $category.Name

            foreach ($fileResult in $fileResults) {
                $tests.Add($fileResult)
            }
        }
    }

    $passedCount = 0
    $failedCount = 0

    foreach ($test in $tests) {
        if ($test.Passed) {
            $passedCount++
        }
        else {
            $failedCount++
        }
    }

    return @{
        Passed       = ($failedCount -eq 0)
        PassedCount  = $passedCount
        FailedCount  = $failedCount
        WarningCount = $warnings.Count
        Duration     = ((Get-Date) - $startedAt).TotalSeconds
        Tests        = @($tests.ToArray())
        Warnings     = @($warnings.ToArray())
    }
}
