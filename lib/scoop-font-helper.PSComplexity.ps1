#Requires -Version 7

Measure-PSComplexity -Path ./lib/scoop-font-helper.ps1 | Sort-Object Cognitive -Descending |
Format-Table File, Unit, Line, Cyclomatic, Cognitive

if (-not (Test-PSComplexity -Path ./lib/scoop-font-helper.ps1)) {
    throw 'Complexity gate failed'
}