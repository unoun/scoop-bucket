$results = @(
    Invoke-ScriptAnalyzer `
        -Path $PSScriptRoot `
        -CustomRulePath "$PSScriptRoot\PSScriptAnalyzerRules.psm1" `
        -IncludeDefaultRules `
        -Settings "$PSScriptRoot\PSScriptAnalyzerSettings.psd1"
)
if ($results.Count -eq 0) {
    Write-Information 'PSScriptAnalyzer: No issues found.' -InformationAction Continue
}
else {
    $results
}