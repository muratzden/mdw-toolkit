<#
MDW Help Command
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWHelpPage {
    [CmdletBinding()]
    param(
        [string] $CommandName
    )

    $pages = @{
        build = @{ Description = "Build a production-ready plugin copy."; Usage = "mdw build <plugin-slug>"; Parameters = @("plugin-slug: Plugin folder name in the workspace."); Examples = @("mdw build my-plugin") }
        doctor = @{ Description = "Inspect the local development environment."; Usage = "mdw doctor"; Parameters = @("None"); Examples = @("mdw doctor") }
        validate = @{ Description = "Validate mdw.json, plugin headers, readme.txt and Git status."; Usage = "mdw validate <plugin-slug>"; Parameters = @("plugin-slug: Optional plugin folder name."); Examples = @("mdw validate my-plugin") }
        compliance = @{ Description = "Run WordPress compliance checks and safely fix unsafe prefixes."; Usage = "mdw compliance <plugin-slug> [--prefix <prefix>] or mdw compliance fix <plugin-slug> --prefix <prefix> [--whatif]"; Parameters = @("plugin-slug: Plugin folder name.", "fix: Preview or apply safe prefix replacements.", "-PluginSlug: Named plugin slug.", "-PluginPath: Direct plugin path.", "--prefix: Expected plugin-specific prefix.", "--whatif: Dry-run without modifying files."); Examples = @("mdw compliance my-plugin", "mdw compliance my-plugin --prefix craftcommercekit_reviewflow_", "mdw compliance fix my-plugin --prefix craftcommercekit_reviewflow_ --whatif", "mdw compliance fix my-plugin --prefix craftcommercekit_reviewflow_") }
        "plugin-check" = @{ Description = "Run MDW internal checks or WP-CLI Plugin Check when a WordPress path is supplied."; Usage = "mdw plugin-check <plugin-slug> [-WordPressPath <path>]"; Parameters = @("plugin-slug: Plugin folder name.", "-PluginSlug: Named plugin slug.", "-WordPressPath: WordPress test installation path."); Examples = @("mdw plugin-check my-plugin", "mdw plugin-check -PluginSlug my-plugin -WordPressPath C:\laragon\www\site") }
        check = @{ Description = "Run quick internal plugin structure checks."; Usage = "mdw check <plugin-slug>"; Parameters = @("plugin-slug: Plugin folder name."); Examples = @("mdw check my-plugin") }
        lint = @{ Description = "Run php -l across plugin PHP files."; Usage = "mdw lint <plugin-slug> or mdw lint -PluginPath <path>"; Parameters = @("plugin-slug: Plugin folder name.", "-PluginPath: Direct plugin path."); Examples = @("mdw lint my-plugin", "mdw lint -PluginPath C:\Workspace\Plugins\my-plugin") }
        release = @{ Description = "Run backup, build, validate and ZIP release preparation."; Usage = "mdw release <plugin-slug>"; Parameters = @("plugin-slug: Plugin folder name."); Examples = @("mdw release my-plugin") }
        svn = @{ Description = "Manage WordPress.org SVN status, checkout, sync, tag and publish workflows."; Usage = "mdw svn [status|checkout|sync|tag|publish] [--plugin <slug>] [--dry-run]"; Parameters = @("status: Inspect SVN readiness without changing files.", "checkout: Checkout or update the configured WordPress.org working copy.", "sync: Sync build output to SVN trunk.", "tag: Prepare an SVN tag from trunk.", "publish: Run the WordPress.org publish pipeline.", "--dry-run: Preview publish/sync/tag without committing."); Examples = @("mdw svn status", "mdw svn checkout", "mdw svn sync --dry-run", "mdw svn publish --dry-run") }
        zip = @{ Description = "Create a release ZIP from the build output."; Usage = "mdw zip <plugin-slug>"; Parameters = @("plugin-slug: Plugin folder name."); Examples = @("mdw build my-plugin", "mdw zip my-plugin") }
    }

    $key = $CommandName.ToLowerInvariant()

    if ($pages.ContainsKey($key)) {
        return $pages[$key]
    }

    return $null
}

function Write-MDWCommandHelp {
    [CmdletBinding()]
    param(
        [string] $CommandName
    )

    $page = Get-MDWHelpPage -CommandName $CommandName

    Write-MDWHeader -Title "MDW Toolkit" -Subtitle ("Help: {0}" -f $CommandName)

    if ($null -eq $page) {
        Write-MDWResult -Status "FAIL" -Message ("No help page found for command: {0}" -f $CommandName)
        return
    }

    Write-MDWSection -Title "Description"
    Write-MDWInfoCard -Label "Command" -Value $CommandName
    Write-MDWInfoCard -Label "Summary" -Value $page.Description

    Write-MDWSection -Title "Usage"
    Write-MDWExample -Command $page.Usage

    Write-MDWSection -Title "Parameters"
    foreach ($parameter in $page.Parameters) {
        Write-MDWStatus -Status "INFO" -Message $parameter
    }

    Write-MDWSection -Title "Examples"
    foreach ($example in $page.Examples) {
        Write-MDWExample -Command $example
    }

    Write-MDWResult -Status "OK" -Message "Help loaded."
}

function Invoke-MDWHelp {
    [CmdletBinding()]
    param(
        [string[]] $Arguments
    )

    if ($Arguments -and $Arguments.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($Arguments[0])) {
        Write-MDWCommandHelp -CommandName $Arguments[0]
        return
    }

    $toolkitRoot = Get-MDWToolkitPath
    $workspacePath = Get-MDWWorkspacePath
    $config = Get-MDWConfig -ToolkitRoot $toolkitRoot
    $metadata = Get-MDWToolkitMetadata -Config $config

    $commonCommands = @(
        @{ Name = "mdw doctor"; Description = "Check environment" }
        @{ Name = "mdw compliance <plugin>"; Description = "Compliance checks" }
        @{ Name = "mdw validate <plugin>"; Description = "Release readiness" }
        @{ Name = "mdw build <plugin>"; Description = "Build package" }
        @{ Name = "mdw release <plugin>"; Description = "Release plugin" }
        @{ Name = "mdw svn status"; Description = "WordPress.org SVN" }
    )

    $workflowCommands = @(
        @{ Name = "mdw check <plugin>"; Description = "Quick validation" }
        @{ Name = "mdw lint <plugin>"; Description = "PHP syntax lint" }
        @{ Name = "mdw plugin-check <plugin>"; Description = "Plugin checks" }
        @{ Name = "mdw zip <plugin>"; Description = "Create ZIP" }
        @{ Name = "mdw svn publish --dry-run"; Description = "WP.org dry run" }
        @{ Name = "mdw test"; Description = "Run tests" }
    )

    $utilityCommands = @(
        @{ Name = "mdw help <command>"; Description = "Command help" }
        @{ Name = "mdw info"; Description = "Workspace info" }
        @{ Name = "mdw version"; Description = "Show version" }
        @{ Name = "mdw git"; Description = "Git status" }
        @{ Name = "mdw local"; Description = "LocalWP" }
    )

    Write-MDWLogo
    Write-MDWHeader -Title $metadata.Name -Subtitle $metadata.Slogan

    Write-MDWSection -Title "Workspace"
    Write-MDWInfoCard -Label "Workspace" -Value $workspacePath
    Write-MDWInfoCard -Label "Toolkit" -Value $toolkitRoot

    Write-MDWSection -Title "Common Commands"
    Write-MDWCommandList -Commands $commonCommands

    Write-MDWSection -Title "Workflow Commands"
    Write-MDWCommandList -Commands $workflowCommands

    Write-MDWSection -Title "Utility Commands"
    Write-MDWCommandList -Commands $utilityCommands

    Write-MDWSection -Title "Getting Started"
    Write-MDWExample -Command "mdw doctor"
    Write-MDWExample -Command "mdw help compliance"

    Write-MDWBlank
}

