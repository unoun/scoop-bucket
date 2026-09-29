#Requires -Version 5
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='6.2' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost',
    '',
    Justification = 'Write-Host is used for test diagnostics.'
)]
param()

BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
    function info { Write-Host "called info(): $args" }
    function warn { Write-Host "called warn(): $args" }
    function error { Write-Host "called error(): $args" }
    function is_admin { $false }
    function appdir { throw 'appdir should be mocked' }
}

Describe 'Get-FontFamily' {
    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\msgothic.ttc"; TypeName = 'Object[]'; NumOfFonts = 3; FontName = 'MS UI Gothic' }
        @{ File = "$env:SystemRoot\Fonts\tahoma.ttf"; TypeName = 'String'; NumOfFonts = 1; FontName = 'Tahoma' }
    ) {
        It 'typeName:<typeName>' {
            (Get-FontFamily $file).GetType().Name | Should -Be $typeName
            Get-FontFamily $file | Should -BeOfType [String]
        }

        It 'numOfFonts:<numOfFonts>' {
            Get-FontFamily $file | Should -HaveCount $numOfFonts
        }

        It 'contains fontName:<fontName>' {
            $ret = Get-FontFamily $file
            $ret | Should -Contain $fontName
        }
    }
}

Describe 'Get-InstalledFontFamily' {
    It 'then contains fontName:<fontName>' -ForEach @(
        @{ FontName = 'Tahoma' }
        @{ FontName = 'Times New Roman' }
    ) {
        Get-InstalledFontFamily | Should -Contain $fontName
    }
}

Describe 'Get-AlreadyInstalledFontFamily' {
    It 'when $installed does not contains any items from $list, return null' {
        $installed = ('i1', 'i2', 'i3', 'i4', 'i5')
        Get-AlreadyInstalledFontFamily $installed 'i9' | Should -BeNullOrEmpty
        Get-AlreadyInstalledFontFamily $installed ('i8', 'i9') | Should -BeNullOrEmpty
        Get-AlreadyInstalledFontFamily $installed 'i9' | Should -Not -BeGreaterThan 0
    }

    It 'when $installed contains a single item from $list, return a single value' {
        $installed = ('i1', 'i2', 'i3', 'i4', 'i5')
        Get-AlreadyInstalledFontFamily $installed 'i1' | Should -Be 'i1'
        Get-AlreadyInstalledFontFamily $installed ('i5', 'i9') | Should -Be 'i5'
        Get-AlreadyInstalledFontFamily $installed 'i1' | Should -BeGreaterThan 0
        Get-AlreadyInstalledFontFamily $installed ('i5', 'i9') | Should -BeGreaterThan 0
    }

    It 'when $installed contains multiple items from $list, return multiple values' {
        $installed = ('i1', 'i2', 'i3', 'i4', 'i5')
        Get-AlreadyInstalledFontFamily $installed ('i1', 'i2') | Should -Be ('i1', 'i2')
        Get-AlreadyInstalledFontFamily $installed ('i3', 'i4', 'i9') | Should -Be ('i3', 'i4')
        Get-AlreadyInstalledFontFamily $installed ('i1', 'i2') | Should -BeGreaterThan 0
        Get-AlreadyInstalledFontFamily $installed ('i3', 'i4', 'i9') | Should -BeGreaterThan 0
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

Describe 'Get-FontCount' {
    Context 'when <file>' -ForEach @(
        @{ File = "$env:SystemRoot\Fonts\msgothic.ttc"; NumOfFonts = 3 }
    ) {
        It 'then return <numOfFonts>' {
            Get-FontCount $file | Should -Be $numOfFonts
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
            Mock Get-FontCount { return 1 }
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
            Mock Get-FontCount { return 255 }
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

    Context 'comparing with the already installed fonts' -Tag 'Regression' {
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

        Context 'when <file>' -ForEach $installedFonts {
            It "return '<fontName>'" {
                $name = Get-FontName $file
                $name | Should -Be $fontName
            }
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

Describe 'Wait-ServiceStatus' {
    It 'WaitForStatus' {
        Mock Get-Service {
            $service = [PSCustomObject]@{}
            $service | Add-Member -Name WaitForStatus -Type ScriptMethod -Value {}
            return $service
        }
        Wait-ServiceStatus 'FontCache' 'Stopped' ([TimeSpan]::New(0, 0, 0, 1))
        Should -Invoke -CommandName Get-Service -Times 1 -Exactly -ParameterFilter { $ServiceName -eq 'FontCache' }
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
        Should -Invoke -CommandName Get-Service -Times 1 -Exactly -ParameterFilter { $ServiceName -eq 'FontCache' }
    }

    It 'when initially timed out then stopped, return true' {
        $script:callCount = 0

        Mock Wait-ServiceStatus {
            $script:callCount++
            if ($script:callCount -eq 1) {
                throw [System.ServiceProcess.TimeoutException]::new('timeout')
            }
        }
        Wait-ServiceStopped 'FontCache' | Should -BeTrue
        Should -Invoke -CommandName Wait-ServiceStatus -Times 2 -Exactly -ParameterFilter { $ServiceName -eq 'FontCache' }
    }
}

Describe 'Exit-Process' {
    It 'exit' {
        { Exit-Process 1 }
    }
}

Describe 'Confirm-Action' {
    BeforeEach {
        $script:character = $null
        Mock Get-Host {
            $RawUI = [PSCustomObject]@{
                KeyAvailable = $true
            }
            $RawUI | Add-Member -Name FlushInputBuffer -Type ScriptMethod -Value {}
            $RawUI | Add-Member -Name ReadKey -Type ScriptMethod -Value { return @{ Character = $script:character } }
            return [PSCustomObject]@{
                UI = [PSCustomObject]@{
                    RawUI = $RawUI
                }
            }
        }
    }

    Context 'when <char> is pressed' -ForEach @(
        @{ dispChar = 'Y'  ; char = 'Y'; result = 'Y'; isError = $false }
        @{ dispChar = 'y'  ; char = 'y'; result = 'Y'; isError = $false }
        @{ dispChar = 'N'  ; char = 'N'; result = 'N'; isError = $true }
        @{ dispChar = 'n'  ; char = 'n'; result = 'N'; isError = $true }
        @{ dispChar = 'ESC'; char = 27 ; result = 'Cancelled'; isError = $true }
    ) {
        It 'return <result>' {
            $script:character = $char
            $ret = Confirm-Action
            if ($isError) {
                $ret.isError | Should-BeTrue
            }
            else {
                $ret.isError | Should-BeFalse
            }
            $ret.result | Should-Be $result
        }
    }

    Context 'when timeout with TimeoutIsError:<timeoutIsError>' -ForEach @(
        @{ timeoutIsError = $true }
        @{ timeoutIsError = $false }
    ) {
        It 'return Timeout with isError:<timeoutIsError>' {
            $ret = Confirm-Action $timeoutIsError 1
            if ($timeoutIsError) {
                $ret.isError | Should-BeTrue
            }
            else {
                $ret.isError | Should-BeFalse
            }
            $ret.result | Should-Be 'Timeout'
        }
    }
}

Describe 'Resolve-UninstallDirectory' {
    BeforeAll {
        Mock appdir { 'C:\app' }
    }

    It 'when specified directory exists, return it' {
        Mock Test-Path { $true }

        Resolve-UninstallDirectory 'C:\exists' $null $null | Should -Be 'C:\exists'

        Should -Invoke Test-Path -Times 1 -Exactly
        Should -Invoke appdir -Times 0 -Exactly
    }

    It 'when app is missing, return specified directory' {
        Mock Test-Path { $false }

        Resolve-UninstallDirectory 'C:\missing' $null '1.0' | Should -Be 'C:\missing'
    }

    It 'when old_version is missing, return specified directory' {
        Mock Test-Path { $false }

        Resolve-UninstallDirectory 'C:\missing' 'app' $null | Should -Be 'C:\missing'
    }

    It 'when no candidate is found, exit with error' {
        Mock Test-Path { $false }
        Mock Get-ChildItem { @() }
        Mock Exit-Process { throw $code }
        Mock error { Write-Host "called error(): $args" }

        { Resolve-UninstallDirectory 'C:\missing' 'app' '1.0' } | Should -Throw 1
        Should -Invoke error -Times 2 -Exactly
    }

    It 'when multiple candidate directories are found, exit with error' {
        Mock Test-Path {
            param($path)
            return $path -like '*Fonts\*'
        }
        Mock Get-ChildItem {
            @(
                [PSCustomObject]@{
                    Name          = 'font1.otf'
                    Extension     = '.otf'
                    DirectoryName = 'C:\app\1.0\dir1'
                },
                [PSCustomObject]@{
                    Name          = 'font2.ttf'
                    Extension     = '.ttf'
                    DirectoryName = 'C:\app\1.0\dir2'
                }
            )
        }
        Mock Exit-Process { throw $code }
        Mock error { Write-Host "called error(): $args" }

        { Resolve-UninstallDirectory 'C:\missing' 'app' '1.0' } | Should -Throw 1
        Should -Invoke error -Times 4 -Exactly
    }

    It 'when one candidate is found and action is confirmed, return candidate' {
        Mock Test-Path {
            param($path)
            return $path -like '*Fonts\*'
        }
        Mock Get-ChildItem {
            @(
                [PSCustomObject]@{
                    Name          = 'font3.ttf'
                    Extension     = '.ttf'
                    DirectoryName = 'C:\app\1.0\dir3'
                },
                [PSCustomObject]@{
                    Name          = 'font4.ttf'
                    Extension     = '.ttf'
                    DirectoryName = 'C:\app\1.0\dir3'
                }
            )
        }
        Mock Confirm-Action {
            return @{
                isError = $false
            }
        }
        Resolve-UninstallDirectory 'C:\missing' 'app' '1.0' | Should -Be 'C:\app\1.0\dir3'
    }

    It 'when one candidate is found and action is cancelled, exit with error' {
        Mock Test-Path {
            param($path)
            return $path -like '*Fonts\*'
        }
        Mock Get-ChildItem {
            @(
                [PSCustomObject]@{
                    Name          = 'font4.ttc'
                    Extension     = '.ttc'
                    DirectoryName = 'C:\app\1.0\dir4'
                }
            )
        }
        Mock Confirm-Action {
            return @{
                isError = $true
            }
        }
        Mock Exit-Process { throw $code }
        Mock error { Write-Host "called error(): $args" }

        { Resolve-UninstallDirectory 'C:\missing' 'app' '1.0' } | Should -Throw 1
        Should -Invoke error -Times 0 -Exactly
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
                Mock Get-AlreadyInstalledFontFamily { return @('') }
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
                    Should -Invoke -CommandName Test-Path -Times 2 -Exactly
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
