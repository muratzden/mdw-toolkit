<#
MDW Toolkit Command Registry
PowerShell 5.1 / 7 compatible
#>

Set-StrictMode -Version 2.0

function Get-MDWCommandRegistry {
    [CmdletBinding()]
    param()

    $registry = @{
        help = @{ Script = "commands/help.ps1"; EntryPoint = "Invoke-MDWHelp"; Description = "Show MDW command help." }
        version = @{ Script = "commands/version.ps1"; EntryPoint = "Invoke-MDWVersion"; Description = "Show MDW Toolkit version." }
        new = @{ Script = "commands/new.ps1"; EntryPoint = "Invoke-MDWNew"; Description = "Create a new WordPress plugin." }
        init = @{ Script = "commands/init.ps1"; EntryPoint = "Invoke-MDWInit"; Description = "Import an existing WordPress plugin." }
        info = @{ Script = "commands/info.ps1"; EntryPoint = "Invoke-MDWInfo"; Description = "Show MDW workspace intelligence." }
        doctor = @{ Script = "commands/doctor.ps1"; EntryPoint = "Invoke-MDWDoctor"; Description = "Check MDW environment requirements." }
        check = @{ Script = "commands/check.ps1"; EntryPoint = "Invoke-MDWCheck"; Description = "Run quick plugin checks." }
        lint = @{ Script = "commands/lint.ps1"; EntryPoint = "Invoke-MDWLint"; Description = "Run PHP syntax lint for a plugin." }
        "plugin-check" = @{ Script = "commands/plugin-check.ps1"; EntryPoint = "Invoke-MDWPluginCheckCommand"; Description = "Run internal or WP-CLI plugin validation." }
        validate = @{ Script = "commands/validate.ps1"; EntryPoint = "Invoke-MDWValidate"; Description = "Run release readiness validation checks." }
        build = @{ Script = "commands/build.ps1"; EntryPoint = "Invoke-MDWBuild"; Description = "Build current plugin." }
        zip = @{ Script = "commands/zip.ps1"; EntryPoint = "Invoke-MDWZip"; Description = "Create release ZIP package." }
        release = @{ Script = "commands/release.ps1"; EntryPoint = "Invoke-MDWRelease"; Description = "Create a production release." }
        backup = @{ Script = "commands/backup.ps1"; EntryPoint = "Invoke-MDWBackup"; Description = "Create a project backup." }
        clean = @{ Script = "commands/clean.ps1"; EntryPoint = "Invoke-MDWClean"; Description = "Clean build and temporary files." }
        git = @{ Script = "commands/git.ps1"; EntryPoint = "Invoke-MDWGitCommand"; Description = "Inspect Git repository information." }
        local = @{ Script = "commands/local.ps1"; EntryPoint = "Invoke-MDWLocal"; Description = "LocalWP development tools." }
        test = @{ Script = "commands/test.ps1"; EntryPoint = "Invoke-MDWTest"; Description = "Run MDW automated tests." }
    }

    return $registry
}

function Test-MDWCommandExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    $registry = Get-MDWCommandRegistry
    return $registry.ContainsKey($Name.ToLowerInvariant())
}

function Get-MDWCommandDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    $normalizedName = $Name.ToLowerInvariant()
    $registry = Get-MDWCommandRegistry

    if (-not $registry.ContainsKey($normalizedName)) {
        throw "Unknown MDW command: $Name"
    }

    return $registry[$normalizedName]
}
