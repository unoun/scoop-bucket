#Requires -Version 5
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.7' }

BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    function info { Write-Host "called info(): $args" }
    function warn { Write-Host "called warn(): $args" }
    function error { Write-Host "called error(): $args" }
    function is_admin { $false }
}

Describe 'Get-FontFamilies' {
    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\msgothic.ttc"; TypeName = 'Object[]'; NumOfFonts = 3; FontName = 'MS UI Gothic' }
        @{ File = "$env:SystemRoot\Fonts\tahoma.ttf"; TypeName = 'String'; NumOfFonts = 1; FontName = 'Tahoma' }
    ) {
        It 'typeName:<typeName>' {
            (Get-FontFamilies $file).GetType().Name | Should -Be $typeName
            Get-FontFamilies $file | Should -BeOfType [String]
        }

        It 'numOfFonts:<numOfFonts>' {
            Get-FontFamilies $file | Should -HaveCount $numOfFonts
        }

        It 'contains fontName:<fontName>' {
            $ret = Get-FontFamilies $file
            $ret | Should -Contain $fontName
        }
    }
}

Describe 'Get-InstalledFontFamilies' {
    It 'then contains fontName:<fontName>' -ForEach @(
        @{ FontName = 'Tahoma' }
        @{ FontName = 'Times New Roman' }
    ) {
        Get-InstalledFontFamilies | Should -Contain $fontName
    }
}

Describe 'Get-AlreadyInstalledFontFamilies' {
    It 'when $installed does not contains any items from $list, return null' {
        $installed = ('i1', 'i2', 'i3', 'i4', 'i5')
        Get-AlreadyInstalledFontFamilies $installed 'i9' | Should -BeNullOrEmpty
        Get-AlreadyInstalledFontFamilies $installed ('i8', 'i9') | Should -BeNullOrEmpty
        Get-AlreadyInstalledFontFamilies $installed 'i9' | Should -Not -BeGreaterThan 0
    }

    It 'when $installed contains a single item from $list, return a single value' {
        $installed = ('i1', 'i2', 'i3', 'i4', 'i5')
        Get-AlreadyInstalledFontFamilies $installed 'i1' | Should -Be 'i1'
        Get-AlreadyInstalledFontFamilies $installed ('i5', 'i9') | Should -Be 'i5'
        Get-AlreadyInstalledFontFamilies $installed 'i1' | Should -BeGreaterThan 0
        Get-AlreadyInstalledFontFamilies $installed ('i5', 'i9') | Should -BeGreaterThan 0
    }

    It 'when $installed contains multiple items from $list, return multiple values' {
        $installed = ('i1', 'i2', 'i3', 'i4', 'i5')
        Get-AlreadyInstalledFontFamilies $installed ('i1', 'i2') | Should -Be ('i1', 'i2')
        Get-AlreadyInstalledFontFamilies $installed ('i3', 'i4', 'i9') | Should -Be ('i3', 'i4')
        Get-AlreadyInstalledFontFamilies $installed ('i1', 'i2') | Should -BeGreaterThan 0
        Get-AlreadyInstalledFontFamilies $installed ('i3', 'i4', 'i9') | Should -BeGreaterThan 0
    }
}

Describe 'Get-FontInfo' {
    Context 'when <file> without index' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\tahoma.ttf"; FamilyName = 'Tahoma'; FaceName = 'Regular' }
        @{ File = "$env:SystemRoot\Fonts\msgothic.ttc"; FamilyName = 'MS Gothic'; FaceName = 'Regular' }
    ) {
        It 'familyName:<familyName>' {
            (Get-FontInfo $file).FamilyName | Should -Be $familyName
            (Get-FontInfo $file).Win32FamilyName | Should -Be $familyName
        }

        It 'faceName:<faceName>' {
            (Get-FontInfo $file).FaceName | Should -Be $faceName
            (Get-FontInfo $file).Win32FaceName | Should -Be $faceName
        }
    }

    Context 'when <file> with index' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\msgothic.ttc" }
    ) {
        Context 'with index:<index>' -ForEach @(
            @{ Index = 0; FamilyName = 'MS Gothic'; FaceName = 'Regular' }
            @{ Index = 1; FamilyName = 'MS UI Gothic'; FaceName = 'Regular' }
            @{ Index = 2; FamilyName = 'MS PGothic'; FaceName = 'Regular' }
        ) {
            It 'familyName:<familyName>' {
                (Get-FontInfo $file $index).FamilyName | Should -Be $familyName
                (Get-FontInfo $file $index).Win32FamilyName | Should -Be $familyName
            }

            It 'faceName:<faceName>' {
                (Get-FontInfo $file $index).FaceName | Should -Be $faceName
                (Get-FontInfo $file $index).Win32FaceName | Should -Be $faceName
            }
        }
    }
}

Describe 'Get-NumberOfFonts' {
    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\msgothic.ttc"; NumOfFonts = 3 }
    ) {
        It 'then return <numOfFonts>' {
            Get-NumberOfFonts $file | Should -Be $numOfFonts
        }
    }
}

Describe 'Get-OTFName' {
    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\msgothic.ttc"; fontName = 'MS Gothic Regular (OpenType)' }
    ) {
        It "return '<fontName>'" {
            Get-OTFName $file | Should -Be $fontName
        }
    }
}

Describe 'Get-TTFName' {
    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\tahoma.ttf"; fontName = 'Tahoma Regular (TrueType)' }
    ) {
        It "return '<fontName>'" {
            Get-TTFName $file | Should -Be $fontName
        }
    }
}

Describe 'Get-TTCName' {
    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\msgothic.ttc"; fontName = 'MS Gothic Regular & MS UI Gothic Regular & MS PGothic Regular (TrueType)' }
    ) {
        It "return '<fontName>'" {
            Get-TTCName $file | Should -Be $fontName
        }
    }

    Context 'when FamilyName + FaceName == Win32FamilyName' {
        It 'return Win32FamilyName based name' {
            Mock Get-NumberOfFonts { return 1 }
            Mock Invoke-Job {
                return @{
                    FamilyName      = 'Dummy'
                    FaceName        = 'Regular'
                    Win32FamilyName = 'Dummy Regular'
                }
            }
            Get-TTCName 'dummy' | Should -Be 'Dummy Regular (TrueType)'
        }
    }

    Context 'when the length of the joined name string exceeds 255' {
        It 'then stop joining and return the joined name' {
            Mock Get-NumberOfFonts { return 255 }
            Mock Invoke-Job {
                return @{
                    FamilyName      = 'Dummy'
                    FaceName        = 'Regular'
                    Win32FamilyName = 'Dummy'
                    Win32FaceName   = 'Regular'
                }
            }
            $fontName = 'Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular & Dummy Regular'
            info "Expected fontName length: $($fontName.Length)"
            Get-TTCName 'dummy' | Should -Be $fontName
        }
    }
}

Describe 'Get-FontName' {
    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\tahoma.ttf"; fontName = 'Tahoma Regular (TrueType)' }
        @{ File = "$env:SystemRoot\Fonts\msgothic.ttc"; fontName = 'MS Gothic Regular & MS UI Gothic Regular & MS PGothic Regular (TrueType)' }
    ) {
        It "return '<fontName>'" {
            Get-FontName $file | Should -Be $fontName
        }
    }

    Context 'when .otf file' {
        It 'return fontName' {
            Mock Get-OTFName { return 'Dummy Regular' }
            $file = [System.IO.FileInfo]'dummy.otf'
            Get-FontName $file | Should -Be 'Dummy Regular'
        }
    }

    BeforeDiscovery {
        $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
        $installedFonts = Get-Item -Path $regPath | Select-Object -ExpandProperty Property | ForEach-Object {
            return @{
                File     = (Get-ItemPropertyValue -Path $regPath -Name $_)
                FontName = $_
            }
        }
        Write-Host "installedFonts.Count: $($installedFonts.Count)"
    }

    Context 'when <file>' -Tag 'Regression' -ForEach $installedFonts {
        It "return '<fontName>'" {
            $name = Get-FontName $file
            $name | Should -Be $fontName
        }

    }
}

Describe 'Wait-ForCondition' {
    It 'when job completed, return value' {
        $ret = Wait-ForCondition { Start-Sleep 1; return 42 }
        $ret.isError | Should -BeFalse
        $ret.result | Should -Be 'Completed'
        $ret.value | Should -Be 42
    }

    It 'when job timeout, return error' {
        $ret = Wait-ForCondition { Start-Sleep 10 } 1
        $ret.isError | Should -BeTrue
        $ret.result | Should -Be 'Timeout'
        $ret.value | Should -BeNullOrEmpty
    }

    It 'when job cancelled, return error' {
        Mock Get-Host {
            $RawUI = [PSCustomObject]@{
                KeyAvailable = $true
            }
            $RawUI | Add-Member -Name FlushInputBuffer -Type ScriptMethod -Value {}
            $RawUI | Add-Member -Name ReadKey -Type ScriptMethod -Value { return @{ Character = 27 } }
            return [PSCustomObject]@{
                UI = [PSCustomObject]@{
                    RawUI = $RawUI
                }
            }
        }
        $ret = Wait-ForCondition { Start-Sleep 10 }
        $ret.isError | Should -BeTrue
        $ret.result | Should -Be 'Cancelled'
        $ret.value | Should -BeNullOrEmpty
    }
}

Describe 'Wait-ServiceStopped' {
    It 'when stopped, return true' {
        Mock Get-Service {
            $service = [PSCustomObject]@{}
            $service | Add-Member -Name WaitForStatus -Type ScriptMethod -Value {}
            return $service
        }
        Wait-ServiceStopped 'FontCache' | Should -BeTrue
        Should -Invoke -CommandName Get-Service -Times 1 -Exactly -ParameterFilter { $serviceName -eq 'FontCache' }
    }
}

Describe 'Exit-Process' {
    It 'exit' {
        { Exit-Process 1 }
    }
}

Describe 'Install-Font' {
    BeforeAll {
        Mock New-Item { Write-Host "called New-Item: $($args[5])" }
        Mock Get-ChildItem { throw "Get-ChildItem" }
        Mock Remove-Item { throw "Remove-Item" }
        Mock Copy-Item { Write-Host "called Copy-Item: $($args[3]) $($args[1])" }
        Mock New-ItemProperty { Write-Host "called New-ItemProperty: $($args[5]) '$($args[7])' $($args[3])" }
        Mock Exit-Process { throw $code }
    }

    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\tahoma.ttf" }
    ) {
        BeforeEach {
            Mock Get-ChildItem { return [System.IO.FileInfo]$file }
        }

        It 'then exit with error code 1 because it is already installed' {
            { Install-Font 'dummy' } | Should -Throw 1
            Should -Invoke -CommandName Get-ChildItem -Times 1 -Exactly
            Should -Invoke -CommandName Remove-Item -Times 0 -Exactly
            Should -Invoke -CommandName Copy-Item -Times 0 -Exactly
            Should -Invoke -CommandName New-ItemProperty -Times 0 -Exactly
        }

        Context 'and not installed' {
            BeforeAll {
                Mock Get-AlreadyInstalledFontFamilies { return @('') }
                Mock Remove-Item { Write-Host "called Remove-Item: $($args[3])" }
            }

            Context 'and file cannot be deleted' {
                BeforeAll {
                    Mock Test-Path { return $true }
                }

                It 'then exit with error code 1 because font file cannot be deleted' {
                    { Install-Font 'dummy' } | Should -Throw 1
                    Should -Invoke -CommandName Remove-Item -Times 1 -Exactly
                    Should -Invoke -CommandName Test-Path -Times 1 -Exactly
                    Should -Invoke -CommandName Copy-Item -Times 0 -Exactly
                    Should -Invoke -CommandName New-ItemProperty -Times 0 -Exactly
                }
            }

            It 'then the installation is successful' {
                Install-Font 'dummy' | Should -BeNullOrEmpty
                Should -Invoke -CommandName Remove-Item -Times 1 -Exactly
                Should -Invoke -CommandName Copy-Item -Times 1 -Exactly
                Should -Invoke -CommandName New-ItemProperty -Times 1 -Exactly
            }

        }
    }
}

Describe 'Uninstall-Font' {
    BeforeAll {
        Mock Get-ChildItem { throw "Get-ChildItem" }
        Mock Remove-ItemProperty { Write-Host "called Remove-ItemProperty: $($args[3]) '$($args[5])'" }
        Mock Stop-Service { Write-Host "called Stop-Service $($args[1])" }
        Mock Wait-ForCondition { return @{ isError = $true; result = 'test' } }
        Mock Remove-Item { Write-Host "called Remove-Item: $($args[3])" }
        Mock Exit-Process { throw $code }
    }

    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\tahoma.ttf" }
    ) {
        BeforeEach {
            Mock Get-ChildItem { return [System.IO.FileInfo]$file }
        }

        Context 'and non-admin' {
            Context 'and file cannot be deleted' {
                BeforeAll {
                    Mock Test-Path { return $true }
                }

                It 'then exit with error code 1 because font file cannot be deleted' {
                    { Uninstall-Font 'dummy' } | Should -Throw 1
                    Should -Invoke -CommandName Remove-ItemProperty -Times 1 -Exactly
                    Should -Invoke -CommandName Remove-Item -Times 1 -Exactly
                    Should -Invoke -CommandName Test-Path -Times 1 -Exactly
                }
            }

            It 'then the uninstallation is successful with wait error' {
                Mock warn { Write-Host "called warn(): $args" }
                Uninstall-Font 'dummy' | Should -BeNullOrEmpty
                Should -Invoke -CommandName Remove-ItemProperty -Times 1 -Exactly
                Should -Invoke -CommandName Wait-ForCondition -Times 1 -Exactly
                Should -Invoke -CommandName warn -Times 1 -Exactly
                Should -Invoke -CommandName Remove-Item -Times 1 -Exactly
                Should -Invoke -CommandName Stop-Service -Times 0 -Exactly
            }
        }

        Context 'and admin' {
            BeforeAll {
                Mock is_admin { return $true }
            }

            It 'then the uninstallation is successful with stop service' {
                Uninstall-Font 'dummy' | Should -BeNullOrEmpty
                Should -Invoke -CommandName Stop-Service -Times 1 -Exactly
                Should -Invoke -CommandName Remove-ItemProperty -Times 1 -Exactly
                Should -Invoke -CommandName Remove-Item -Times 1 -Exactly
            }
        }
    }
}
