<#
MDW Output Service
PowerShell 5.1 / 7 compatible

Compatibility helpers for older service code. Core CLI rendering is provided by
core/cli-ui.ps1 and these wrappers intentionally avoid redefining core helper
names such as Write-MDWSection.
#>

Set-StrictMode -Version 2.0

function Write-MDWTitle {
    [CmdletBinding()]
    param(
        [string] $Text
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle $Text
}

function Write-MDWOutputSection {
    [CmdletBinding()]
    param(
        [string] $Text
    )

    Write-MDWSection -Title $Text
}

function Write-MDWInfo {
    [CmdletBinding()]
    param(
        [string] $Message
    )

    Write-MDWStatus -Status "INFO" -Message $Message
}

function Write-MDWSuccess {
    [CmdletBinding()]
    param(
        [string] $Message
    )

    Write-MDWStatus -Status "OK" -Message $Message
}

function Write-MDWWarning {
    [CmdletBinding()]
    param(
        [string] $Message
    )

    Write-MDWStatus -Status "WARN" -Message $Message
}

function Write-MDWError {
    [CmdletBinding()]
    param(
        [string] $Message
    )

    Write-MDWStatus -Status "FAIL" -Message $Message
}

function Write-MDWSummary {
    [CmdletBinding()]
    param(
        [int] $Failed,
        [int] $Warnings
    )

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Failed" -Value $Failed
    Write-MDWInfoCard -Label "Warnings" -Value $Warnings

    if ($Failed -gt 0) {
        Write-MDWResult -Status "FAIL" -Message "Result: FAILED"
        return
    }

    if ($Warnings -gt 0) {
        Write-MDWResult -Status "WARN" -Message "Result: PASSED WITH WARNINGS"
        return
    }

    Write-MDWResult -Status "OK" -Message "Result: PASSED"
}
