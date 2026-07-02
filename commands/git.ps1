<#
MDW Git Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Write-MDWGitRepositoryStatus {
    [CmdletBinding()]
    param(
        [object] $GitStatus
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Git Repository"

    Write-MDWSection -Title "Repository"
    Write-MDWInfoCard -Label "Path" -Value $GitStatus.RepositoryPath
    Write-MDWInfoCard -Label "Branch" -Value $GitStatus.Branch
    Write-MDWInfoCard -Label "Remote" -Value $GitStatus.Remote

    Write-MDWSection -Title "Status"

    if ($GitStatus.Available) {
        Write-MDWStatus -Status "OK" -Message "Git installed"
    }
    else {
        Write-MDWStatus -Status "FAIL" -Message "Git is not installed or not available in PATH."
        Write-MDWResult -Status "FAIL" -Message "Git is not installed or not available in PATH."
        return
    }

    if ($GitStatus.Repository) {
        Write-MDWStatus -Status "OK" -Message "Repository detected"
    }
    else {
        Write-MDWStatus -Status "FAIL" -Message "Not a Git repository."
        Write-MDWResult -Status "FAIL" -Message "Not a Git repository."
        return
    }

    if ([string]::IsNullOrWhiteSpace([string] $GitStatus.Remote)) {
        Write-MDWStatus -Status "WARN" -Message "Remote not configured"
    }
    else {
        Write-MDWStatus -Status "OK" -Message "Remote configured"
    }

    if ($GitStatus.Clean) {
        Write-MDWStatus -Status "OK" -Message "Working tree clean"
    }
    else {
        Write-MDWStatus -Status "WARN" -Message "Working tree has changes"
    }

    Write-MDWSection -Title "Commits"
    Write-MDWInfoCard -Label "Last Commit" -Value $GitStatus.LastCommit
    Write-MDWInfoCard -Label "Commit Count" -Value $GitStatus.CommitCount
    Write-MDWInfoCard -Label "Latest Tag" -Value $GitStatus.LatestTag

    Write-MDWSection -Title "Changes"
    Write-MDWInfoCard -Label "Changed" -Value $GitStatus.ChangedFileCount
    Write-MDWInfoCard -Label "Untracked" -Value $GitStatus.UntrackedFileCount

    if ($GitStatus.Clean) {
        Write-MDWResult -Status "OK" -Message "Repository is clean."
    }
    else {
        Write-MDWResult -Status "WARN" -Message "Repository has uncommitted changes."
    }
}

function Write-MDWGitDiff {
    [CmdletBinding()]
    param(
        [object] $GitStatus,
        [string] $RepositoryPath
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Git Diff"

    if (-not $GitStatus.Available) {
        Write-MDWResult -Status "FAIL" -Message "Git is not installed or not available in PATH."
        return
    }

    if (-not $GitStatus.Repository) {
        Write-MDWResult -Status "FAIL" -Message "Not a Git repository."
        return
    }

    $summary = Get-MDWGitDiffSummary -RepositoryPath $RepositoryPath

    Write-MDWSection -Title "Changed Files"

    if ($summary.Files.Count -gt 0) {
        foreach ($file in $summary.Files) {
            Write-MDWInfoCard -Label $file.Status -Value $file.Path
        }
    }
    else {
        Write-MDWStatus -Status "OK" -Message "No changes"
    }

    Write-MDWSection -Title "Summary"
    Write-MDWInfoCard -Label "Modified" -Value $summary.Modified
    Write-MDWInfoCard -Label "Added" -Value $summary.Added
    Write-MDWInfoCard -Label "Deleted" -Value $summary.Deleted
    Write-MDWInfoCard -Label "Untracked" -Value $summary.Untracked

    if ($summary.Total -gt 0) {
        Write-MDWResult -Status "WARN" -Message "Repository has uncommitted changes."
    }
    else {
        Write-MDWResult -Status "OK" -Message "Repository is clean."
    }
}

function Write-MDWGitHistory {
    [CmdletBinding()]
    param(
        [object] $GitStatus,
        [string] $RepositoryPath
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Git History"

    if (-not $GitStatus.Available) {
        Write-MDWResult -Status "FAIL" -Message "Git is not installed or not available in PATH."
        return
    }

    if (-not $GitStatus.Repository) {
        Write-MDWResult -Status "FAIL" -Message "Not a Git repository."
        return
    }

    $history = @(Get-MDWGitHistory -RepositoryPath $RepositoryPath -Limit 10)

    Write-MDWSection -Title "Last Commits"

    if ($history.Count -gt 0) {
        foreach ($commit in $history) {
            Write-MDWInfoCard -Label "Commit" -Value $commit
        }

        Write-MDWResult -Status "OK" -Message "History loaded."
    }
    else {
        Write-MDWResult -Status "WARN" -Message "No commit history found."
    }
}

function Write-MDWGitTags {
    [CmdletBinding()]
    param(
        [object] $GitStatus
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Git Tags"

    if (-not $GitStatus.Available) {
        Write-MDWResult -Status "FAIL" -Message "Git is not installed or not available in PATH."
        return
    }

    if (-not $GitStatus.Repository) {
        Write-MDWResult -Status "FAIL" -Message "Not a Git repository."
        return
    }

    Write-MDWSection -Title "Tags"

    if ($GitStatus.Tags -and $GitStatus.Tags.Count -gt 0) {
        foreach ($tag in $GitStatus.Tags) {
            Write-MDWInfoCard -Label "Tag" -Value $tag
        }

        Write-MDWResult -Status "OK" -Message "Tags loaded."
    }
    else {
        Write-MDWResult -Status "WARN" -Message "No tags found."
    }
}

function Write-MDWGitBranch {
    [CmdletBinding()]
    param(
        [object] $GitStatus
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Git Branch"

    if (-not $GitStatus.Available) {
        Write-MDWResult -Status "FAIL" -Message "Git is not installed or not available in PATH."
        return
    }

    if (-not $GitStatus.Repository) {
        Write-MDWResult -Status "FAIL" -Message "Not a Git repository."
        return
    }

    Write-MDWSection -Title "Repository"
    Write-MDWInfoCard -Label "Path" -Value $GitStatus.RepositoryPath
    Write-MDWInfoCard -Label "Branch" -Value $GitStatus.Branch
    Write-MDWResult -Status "OK" -Message "Branch loaded."
}

function Write-MDWGitCommit {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath,
        [string] $Message
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Git Commit"

    Write-MDWSection -Title "Commit"
    Write-MDWInfoCard -Label "Message" -Value $Message

    $result = New-MDWGitCommit -RepositoryPath $RepositoryPath -Message $Message

    Write-MDWSection -Title "Files"
    Write-MDWInfoCard -Label "Changed" -Value ("{0} changed files" -f $result.ChangedFileCount)

    if ($result.Passed) {
        Write-MDWResult -Status "OK" -Message "Commit created."
    }
    else {
        foreach ($errorItem in $result.Errors) {
            Write-MDWStatus -Status "FAIL" -Message $errorItem
        }

        Write-MDWResult -Status "FAIL" -Message "Commit was not created."
    }
}

function Write-MDWGitTag {
    [CmdletBinding()]
    param(
        [string] $RepositoryPath,
        [string] $Version
    )

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle "Git Tag"

    Write-MDWSection -Title "Tag"
    Write-MDWInfoCard -Label "Version" -Value $Version

    $result = New-MDWGitTag -RepositoryPath $RepositoryPath -Version $Version

    if ($result.Passed) {
        Write-MDWResult -Status "OK" -Message ("Tag created: {0}" -f $result.Tag)
    }
    else {
        foreach ($errorItem in $result.Errors) {
            Write-MDWStatus -Status "FAIL" -Message $errorItem
        }

        Write-MDWResult -Status "FAIL" -Message "Tag was not created."
    }
}

function Invoke-MDWGitCommand {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    $subCommand = "status"

    if ($Arguments -and $Arguments.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($Arguments[0])) {
        $subCommand = $Arguments[0].ToLowerInvariant()
    }

    $toolkitRoot = Get-MDWToolkitPath
    $gitStatus = Get-MDWGitStatus -RepositoryPath $toolkitRoot

    if ($subCommand -eq "status" -or $subCommand -eq "info") {
        Write-MDWGitRepositoryStatus -GitStatus $gitStatus
        return
    }

    if ($subCommand -eq "diff") {
        Write-MDWGitDiff -GitStatus $gitStatus -RepositoryPath $toolkitRoot
        return
    }

    if ($subCommand -eq "history" -or $subCommand -eq "log") {
        Write-MDWGitHistory -GitStatus $gitStatus -RepositoryPath $toolkitRoot
        return
    }

    if ($subCommand -eq "tags") {
        Write-MDWGitTags -GitStatus $gitStatus
        return
    }

    if ($subCommand -eq "branch") {
        Write-MDWGitBranch -GitStatus $gitStatus
        return
    }

    if ($subCommand -eq "commit") {
        $message = $null

        if ($Arguments.Count -gt 1) {
            $message = ($Arguments[1..($Arguments.Count - 1)] -join " ")
        }

        Write-MDWGitCommit -RepositoryPath $toolkitRoot -Message $message
        return
    }

    if ($subCommand -eq "tag") {
        $version = $null

        if ($Arguments.Count -gt 1) {
            $version = $Arguments[1]
        }

        Write-MDWGitTag -RepositoryPath $toolkitRoot -Version $version
        return
    }

    throw "Unknown git subcommand: $subCommand. Usage: mdw git [status|info|branch|log|tags|diff|history|commit|tag]"
}
