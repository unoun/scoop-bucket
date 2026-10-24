#Requires -Version 7

$timer = [System.Diagnostics.Stopwatch]::StartNew()
try {
    Invoke-PSMutation -ConfigFile '.\lib\psmutant.config.json'
}
finally {
    $timer.Stop()
    Write-Information "Elapsed: $($timer.Elapsed)" -InformationAction Continue
}