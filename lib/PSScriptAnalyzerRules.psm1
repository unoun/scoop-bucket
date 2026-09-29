<#
.SYNOPSIS
    Checks parameter and local variable naming conventions.

.DESCRIPTION
    Parameters must use PascalCase.
    Local variables must use camelCase.
#>

function Measure-ParameterNaming {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]
        $Ast
    )

    $functions = $Ast.FindAll(
        {
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        },
        $true
    )

    foreach ($function in $functions) {
        foreach ($parameter in $function.Parameters) {
            $name = $parameter.Name.VariablePath.UserPath

            if ($name -cnotmatch '^[A-Z][a-zA-Z0-9]*$') {
                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    Message  = "Parameter '$name' must use PascalCase."
                    Extent   = $parameter.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
        }

        # param() block inside the function
        if ($function.Body.ParamBlock) {
            foreach ($parameter in $function.Body.ParamBlock.Parameters) {
                $name = $parameter.Name.VariablePath.UserPath

                if ($name -cnotmatch '^[A-Z][a-zA-Z0-9]*$') {
                    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message  = "Parameter '$name' must use PascalCase."
                        Extent   = $parameter.Extent
                        RuleName = $PSCmdlet.MyInvocation.InvocationName
                        Severity = 'Warning'
                    }
                }
            }
        }
    }
}

function Measure-LocalVariableNaming {
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.ScriptBlockAst]
        $Ast
    )

    $functions = $Ast.FindAll(
        {
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
        },
        $true
    )

    foreach ($function in $functions) {
        $parameterNames = @(
            $function.Parameters.Name.VariablePath.UserPath

            if ($function.Body.ParamBlock) {
                $function.Body.ParamBlock.Parameters.Name.VariablePath.UserPath
            }
        )

        $localNames = @(
            $function.Body.FindAll(
                {
                    param($node)
                    $node -is [System.Management.Automation.Language.AssignmentStatementAst]
                },
                $true
            ) | ForEach-Object {
                $_.Left | Where-Object {
                    $_ -is [System.Management.Automation.Language.VariableExpressionAst]
                } | ForEach-Object {
                    $_.VariablePath.UserPath
                }
            } | Sort-Object -Unique
        )

        $variables = $function.Body.FindAll(
            {
                param($node)
                $node -is [System.Management.Automation.Language.VariableExpressionAst]
            },
            $true
        )

        foreach ($variable in $variables) {
            $name = $variable.VariablePath.UserPath

            if ($variable.VariablePath.DriveName) {
                continue
            }

            # Parameters are checked by Measure-ParameterNaming.
            if ($parameterNames -contains $name) {
                continue
            }

            # Ignore PowerShell automatic variables.
            if ($name -match '^(true|false|null|this|args|input|PS\w+|_|HOME)$') {
                continue
            }

            # Variables that are not assigned in this function are external variables.
            if ($localNames -notcontains $name) {
                continue
            }

            if ($name -cnotmatch '^[a-z][a-zA-Z0-9]*$') {
                [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    Message  = "Local variable '$name' must use camelCase."
                    Extent   = $variable.Extent
                    RuleName = $PSCmdlet.MyInvocation.InvocationName
                    Severity = 'Warning'
                }
            }
        }
    }
}

Export-ModuleMember -Function @(
    'Measure-ParameterNaming'
    'Measure-LocalVariableNaming'
)