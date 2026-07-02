<#
MDW CLI UI Helper
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

$script:MDW_UI_MIN_WIDTH = 50
$script:MDW_UI_MAX_WIDTH = 78
$script:MDW_UI_LABEL_WIDTH = 12
$script:MDW_UI_SECTION_WRITTEN = $false

function Write-MDWLogo {
    [CmdletBinding()]
    param()

    $logo = @'
 __  __ ____  __        __
|  \/  |  _ \ \ \      / /
| |\/| | | | | \ \ /\ / /
| |  | | |_| |  \ V  V /
|_|  |_|____/    \_/\_/
'@

    Write-Host $logo -ForegroundColor Cyan
    Write-Host "             MDW TOOLKIT" -ForegroundColor Cyan
    Write-Host "     Professional WordPress CLI Toolkit" -ForegroundColor DarkGray
    Write-Host ""
}

function Get-MDWTerminalWidth {
    [CmdletBinding()]
    param()

    try {
        $width = [int]$Host.UI.RawUI.WindowSize.Width

        if ($width -lt $script:MDW_UI_MIN_WIDTH) {
            return $script:MDW_UI_MIN_WIDTH
        }

        if ($width -gt $script:MDW_UI_MAX_WIDTH) {
            return $script:MDW_UI_MAX_WIDTH
        }

        return ($width - 2)
    }
    catch {
        return 58
    }
}

function Get-MDWCommandColumnWidth {
    [CmdletBinding()]
    param()

    $width = Get-MDWTerminalWidth

    if ($width -le 58) {
        return 24
    }

    return 28
}

function Format-MDWText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object] $Value,
        [int] $MaxLength = 0
    )

    if ($null -eq $Value) {
        return "Not available"
    }

    $text = [string]$Value

    if ([string]::IsNullOrWhiteSpace($text)) {
        return "Not available"
    }

    if ($MaxLength -gt 3 -and $text.Length -gt $MaxLength) {
        return ($text.Substring(0, $MaxLength - 3) + "...")
    }

    return $text
}

function Write-MDWLine {
    [CmdletBinding()]
    param(
        [string] $Character = "=",
        [int] $Width = 0
    )

    if ($Width -le 0) {
        $Width = Get-MDWTerminalWidth
    }

    Write-Host (($Character) * $Width) -ForegroundColor DarkGray
}

function Write-MDWHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Title,

        [string] $Subtitle = ""
    )

    $script:MDW_UI_SECTION_WRITTEN = $false

    Write-MDWLine -Character "="
    Write-Host (" {0}" -f $Title) -ForegroundColor Cyan

    if (-not [string]::IsNullOrWhiteSpace($Subtitle)) {
        Write-Host (" {0}" -f $Subtitle) -ForegroundColor Cyan
    }

    Write-MDWLine -Character "="
    Write-Host ""
}

function Write-MDWSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Title
    )

    if ($script:MDW_UI_SECTION_WRITTEN) {
        Write-Host ""
    }

    Write-Host $Title -ForegroundColor Yellow
    Write-MDWLine -Character "-"
    Write-Host ""

    $script:MDW_UI_SECTION_WRITTEN = $true
}

function Write-MDWInfoCard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Label,

        [AllowNull()]
        [object] $Value
    )

    $safeValue = ""

    if ($null -ne $Value) {
        $safeValue = [string]$Value
    }

    $availableWidth = (Get-MDWTerminalWidth) - $script:MDW_UI_LABEL_WIDTH - 6

    if ($availableWidth -lt 16) {
        $availableWidth = 16
    }

    $safeValue = Format-MDWText -Value $safeValue -MaxLength $availableWidth

    Write-Host ("  {0,-$script:MDW_UI_LABEL_WIDTH} : {1}" -f $Label, $safeValue)
}

function Write-MDWCommandList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array] $Commands
    )

    $commandWidth = Get-MDWCommandColumnWidth

    foreach ($command in $Commands) {
        $name = [string]$command.Name
        $description = [string]$command.Description

        $availableWidth = (Get-MDWTerminalWidth) - $commandWidth - 3
        $description = Format-MDWText -Value $description -MaxLength $availableWidth

        Write-Host ("  {0,-$commandWidth} {1}" -f $name, $description)
    }
}

function Write-MDWExample {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Command
    )

    Write-Host ("  {0}" -f $Command)
}

function Write-MDWStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("OK", "WARN", "FAIL", "INFO")]
        [string] $Status,

        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    $color = "Gray"

    switch ($Status) {
        "OK" {
            $color = "Green"
        }
        "WARN" {
            $color = "DarkYellow"
        }
        "FAIL" {
            $color = "Red"
        }
        "INFO" {
            $color = "Cyan"
        }
    }

    $availableWidth = (Get-MDWTerminalWidth) - 11
    $safeMessage = Format-MDWText -Value $Message -MaxLength $availableWidth

    Write-Host ("  [{0,-4}] {1}" -f $Status, $safeMessage) -ForegroundColor $color
}

function Write-MDWResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("OK", "WARN", "FAIL", "INFO")]
        [string] $Status,

        [Parameter(Mandatory = $true)]
        [string] $Message
    )

    Write-MDWSection -Title "Result"
    Write-MDWStatus -Status $Status -Message $Message
}

function Write-MDWBlank {
    [CmdletBinding()]
    param()

    Write-Host ""
}
