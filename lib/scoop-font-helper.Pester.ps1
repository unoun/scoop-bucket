$config = New-PesterConfiguration
$config.Filter.ExcludeTag = 'Regression'

$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\lib\scoop-font-helper.ps1'
$config.CodeCoverage.CoveragePercentTarget = 99

$config.Should.DisableV5 = $true

Invoke-Pester -Configuration $config

(Get-FileHash '.\lib\scoop-font-helper.ps1' -Algorithm SHA256).Hash.ToLower()