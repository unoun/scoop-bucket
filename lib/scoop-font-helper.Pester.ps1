$config = New-PesterConfiguration
$config.Filter.ExcludeTag = 'Regression'

$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\lib\scoop-font-helper.ps1'
$config.CodeCoverage.CoveragePercentTarget = 99

Invoke-Pester -Configuration $config
