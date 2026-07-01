$tests = New-Object System.Collections.Generic.List[object]

$tests.Add(@{
    Name = "Bootstrap"
    Passed = ($null -ne (Get-Command Get-MDWRootPath -ErrorAction SilentlyContinue)) -and ($null -ne (Get-Command Resolve-MDWPath -ErrorAction SilentlyContinue))
    Duration = 0
    Message = ""
})

$registry = Get-MDWCommandRegistry

$tests.Add(@{
    Name = "Registry"
    Passed = $registry.ContainsKey("test") -and $registry.ContainsKey("plugin-check") -and $registry.ContainsKey("release")
    Duration = 0
    Message = ""
})

$configPassed = $false
$configMessage = ""

try {
    $config = Get-MDWConfig -ToolkitRoot (Get-MDWRootPath)
    $configPassed = $null -ne $config
}
catch {
    $configMessage = $_.Exception.Message
}

$tests.Add(@{
    Name = "Config"
    Passed = $configPassed
    Duration = 0
    Message = $configMessage
})

return @($tests.ToArray())
