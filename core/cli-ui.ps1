<#
MDW CLI UI Helpers
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Write-MDWColor {
    [CmdletBinding()]
    param(
        [string] $Text,
        [string] $Color = "White",
        [switch] $NoNewline
    )

    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Write-MDWDivider {
    [CmdletBinding()]
    param(
        [int] $Width = 60
    )

    if ($Width -lt 20) {
        $Width = 20
    }

    Write-MDWColor -Text ("=" * $Width) -Color "DarkGray"
}

function Write-MDWHeader {
    [CmdletBinding()]
    param(
        [string] $Title = "MDW Toolkit",
        [string] $Subtitle = "Professional WordPress CLI Toolkit"
    )

    Write-Host ""
    Write-MDWDivider
    Write-MDWColor -Text (" {0}" -f $Title) -Color "Cyan"
    Write-MDWColor -Text (" {0}" -f $Subtitle) -Color "Cyan"
    Write-MDWDivider
    Write-Host ""
}

function Write-MDWSection {
    [CmdletBinding()]
    param(
        [string] $Title
    )

    Write-Host ""
    Write-MDWColor -Text $Title -Color "Yellow"
    Write-MDWColor -Text ("-" * 40) -Color "DarkGray"
}

function Write-MDWCommandList {
    [CmdletBinding()]
    param(
        [object[]] $Commands
    )

    foreach ($command in $Commands) {
        Write-Host ("  {0,-14} {1}" -f $command.Name, $command.Description)
    }
}

function Write-MDWExample {
    [CmdletBinding()]
    param(
        [string] $Command
    )

    Write-MDWColor -Text ("  {0}" -f $Command) -Color "Gray"
}

function Write-MDWInfoCard {
    [CmdletBinding()]
    param(
        [string] $Label,
        [object] $Value
    )

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string] $Value)) {
        $Value = "Not configured"
    }

    Write-Host ("  {0,-14}: {1}" -f $Label, $Value)
}

function Write-MDWStatusLine {
    [CmdletBinding()]
    param(
        [string] $Status,
        [string] $Message
    )

    $normalizedStatus = $Status.ToUpperInvariant()
    $color = "Cyan"

    if ($normalizedStatus -eq "OK") {
        $color = "Green"
    }
    elseif ($normalizedStatus -eq "WARN") {
        $color = "Yellow"
    }
    elseif ($normalizedStatus -eq "FAIL") {
        $color = "Red"
    }

    Write-MDWColor -Text ("  [{0,-4}] " -f $normalizedStatus) -Color $color -NoNewline
    Write-Host $Message
}

function Write-MDWStep {
    [CmdletBinding()]
    param(
        [string] $Name,
        [string] $Status = "INFO"
    )

    Write-MDWStatusLine -Status $Status -Message $Name
}

function Write-MDWPipeline {
    [CmdletBinding()]
    param(
        [string[]] $Steps
    )

    foreach ($step in $Steps) {
        Write-Host ("  {0}" -f $step)
        if ($step -ne $Steps[$Steps.Count - 1]) {
            Write-MDWColor -Text "  |" -Color "DarkGray"
        }
    }
}

function Write-MDWTestSummary {
    [CmdletBinding()]
    param(
        [object] $Result
    )

    Write-MDWSection -Title "Test Report"
    Write-MDWInfoCard -Label "Total" -Value ($Result.PassedCount + $Result.FailedCount)
    Write-MDWInfoCard -Label "Passed" -Value $Result.PassedCount
    Write-MDWInfoCard -Label "Failed" -Value $Result.FailedCount
    Write-MDWInfoCard -Label "Warnings" -Value $Result.WarningCount
    Write-MDWInfoCard -Label "Duration" -Value ("{0:N2} sec" -f $Result.Duration)

    if ($Result.Passed) {
        Write-MDWStatusLine -Status "OK" -Message "Result: PASS"
    }
    else {
        Write-MDWStatusLine -Status "FAIL" -Message "Result: FAIL"
    }
}
