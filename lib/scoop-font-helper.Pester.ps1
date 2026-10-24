$config = New-PesterConfiguration
#$config.Filter.ExcludeTag = 'Regression'

$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\lib\scoop-font-helper.ps1'
$config.CodeCoverage.CoveragePercentTarget = 99

$config.Should.DisableV5 = $true

Invoke-Pester -Configuration $config

[xml]$coverage = Get-Content -Raw "$((Get-Location).Path)\coverage.xml"
$uncoveredLines = @(
    $coverage.SelectNodes('//sourcefile/line') |
    Where-Object {
        [int]$_.mi -gt 0 -and [int]$_.ci -eq 0
    }
)
Write-Information "Uncovered lines: $($uncoveredLines.Count)" -InformationAction Continue

(Get-FileHash '.\lib\scoop-font-helper.ps1' -Algorithm SHA256).Hash.ToLower()