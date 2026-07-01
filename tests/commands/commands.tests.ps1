$tests = New-Object System.Collections.Generic.List[object]

$commands = @(
    @{ Name = "new"; EntryPoint = "Invoke-MDWNew" }
    @{ Name = "init"; EntryPoint = "Invoke-MDWInit" }
    @{ Name = "info"; EntryPoint = "Invoke-MDWInfo" }
    @{ Name = "doctor"; EntryPoint = "Invoke-MDWDoctor" }
    @{ Name = "build"; EntryPoint = "Invoke-MDWBuild" }
    @{ Name = "check"; EntryPoint = "Invoke-MDWCheck" }
    @{ Name = "zip"; EntryPoint = "Invoke-MDWZip" }
    @{ Name = "release"; EntryPoint = "Invoke-MDWRelease" }
    @{ Name = "plugin-check"; EntryPoint = "Invoke-MDWPluginCheck" }
    @{ Name = "test"; EntryPoint = "Invoke-MDWTest" }
)

foreach ($command in $commands) {
    $tests.Add(@{
        Name = $command.Name
        Passed = $null -ne (Get-Command $command.EntryPoint -ErrorAction SilentlyContinue)
        Duration = 0
        Message = ""
    })
}

return @($tests.ToArray())
