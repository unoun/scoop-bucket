function Invoke-Job([ScriptBlock] $JobScript, [Object[]] $ScriptArgumentList) {
    $job = Start-Job -ScriptBlock $JobScript -ArgumentList $ScriptArgumentList
    Wait-Job -Job $job | Out-Null
    $ret = Receive-Job $job
    Remove-Job $job
    return $ret
}

function Get-FontFamily ([String] $FullName) {
    Add-Type -AssemblyName System.Drawing
    $col = [System.Drawing.Text.PrivateFontCollection]::new()
    $col.AddFontFile($FullName)
    $list = $col.Families.Name
    $col.Dispose()
    return $list
}

function Get-InstalledFontFamily() {
    Add-Type -AssemblyName System.Drawing
    return [System.Drawing.FontFamily]::Families.Name
}

function Get-AlreadyInstalledFontFamily([String[]] $Installed, [String[]] $List) {
    return $List | Where-Object { $Installed -contains $_ }
}

function Get-FontInfo([String] $FullName, [int] $Index) {
    Add-Type -AssemblyName PresentationCore
    $uri = [UriBuilder]::new($FullName)
    $uri.Fragment = [String]$Index
    $font = [Windows.Media.GlyphTypeface]::new($uri.Uri)
    return @{
        'FamilyName'      = $font.FamilyNames['en-US']
        'FaceName'        = $font.FaceNames['en-US']
        'Win32FamilyName' = $font.Win32FamilyNames['en-US']
        'Win32FaceName'   = $font.Win32FaceNames['en-US']
    }
}

function Get-FontCount([System.IO.FileInfo] $File) {
    try {
        $fr = [System.IO.File]::Open($File.FullName,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite + [System.IO.FileShare]::Delete)
        $br = [System.IO.BinaryReader]::new($fr)
        $br.ReadBytes(4 + 2 + 2) | Out-Null
        $b = $br.ReadBytes(4)
        if ([BitConverter]::IsLittleEndian) {
            [Array]::Reverse($b)
        }
        $ret = [BitConverter]::ToUInt32($b, 0)
    }
    finally {
        if ($null -ne $br) {
            $br.Close()
            $br.Dispose()
        }
        if ($null -ne $fr) {
            $fr.Close()
            $fr.Dispose()
        }
    }
    return $ret
}

function Get-OTFName([System.IO.FileInfo] $File) {
    $fontInfo = Invoke-Job ${function:Get-FontInfo} $File.FullName
    return "$($fontInfo.Win32FamilyName) $($fontInfo.Win32FaceName) (OpenType)"
}

function Get-TTFName([System.IO.FileInfo] $File) {
    $fontInfo = Invoke-Job ${function:Get-FontInfo} $File.FullName
    return "$($fontInfo.Win32FamilyName) $($fontInfo.Win32FaceName) (TrueType)"
}

function Get-TTCName([System.IO.FileInfo] $File) {
    $numFonts = Get-FontCount $File
    $i = 0
    $fontList = @()
    while ($i -lt $numFonts) {
        $fontInfo = Invoke-Job ${function:Get-FontInfo} $File.FullName, $i
        if ("$($fontInfo.FamilyName) $($fontInfo.FaceName)" -eq $fontInfo.Win32FamilyName) {
            $fontList += $fontInfo.Win32FamilyName
        }
        else {
            $fontList += "$($fontInfo.Win32FamilyName) $($fontInfo.Win32FaceName)"
        }
        $i++
        if (($fontList -join ' & ').Length -gt 255) {
            break
        }
    }
    $fontName = $fontList -join ' & '
    if ($i -eq $numFonts) {
        $fontName += ' (TrueType)'
    }
    return $fontName
}

function Get-FontName([System.IO.FileInfo] $File) {
    if ($File.Extension -eq '.otf') {
        $fontName = Get-OTFName $File
    }
    elseif ($File.Extension -eq '.ttf') {
        $fontName = Get-TTFName $File
    }
    elseif ($File.Extension -eq '.ttc') {
        $fontName = Get-TTCName $File
    }
    return $fontName
}

function Wait-ForCondition([ScriptBlock] $ConditionScript, [int] $TimeoutSeconds = 60, [Object[]] $ScriptArgumentList) {
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($TimeoutSeconds)
    $ret = @{
        isError = $true
        result  = 'Error'
        value   = $null
    }
    try {
        $job = Start-Job -ScriptBlock $ConditionScript -ArgumentList $ScriptArgumentList
        (Get-Host).UI.RawUI.FlushInputBuffer()
        while ($true) {
            if ((Get-Host).UI.RawUI.KeyAvailable) {
                $keyinfo = (Get-Host).UI.RawUI.ReadKey('IncludeKeyUp,NoEcho')
                # ESC
                if (27 -eq $keyinfo.Character) {
                    $ret.isError = $true
                    $ret.result = 'Cancelled'
                    break
                }
            }
            if ((Get-Date) -ge $endTime) {
                $ret.isError = $true
                $ret.result = 'Timeout'
                break
            }
            $jobStatus = Get-Job $job.Id
            if ($jobStatus.State -eq 'Completed') {
                $ret.isError = $false
                $ret.result = 'Completed'
                $ret.value = Receive-Job $job
                break
            }
            Start-Sleep -Milliseconds 500
        }
    }
    finally {
        Stop-Job $job.Id
        Remove-Job $job
        (Get-Host).UI.RawUI.FlushInputBuffer()
    }
    return $ret
}

function Wait-ServiceStatus([String] $ServiceName, [System.ServiceProcess.ServiceControllerStatus] $DesiredStatus, [TimeSpan] $Timeout) {
    (Get-Service $ServiceName).WaitForStatus($DesiredStatus, $Timeout)
}

function Wait-ServiceStopped([String] $ServiceName) {
    while ($true) {
        try {
            Wait-ServiceStatus -ServiceName $ServiceName -DesiredStatus 'Stopped' -Timeout ([TimeSpan]::New(0, 0, 0, 1))
            break
        }
        catch [System.ServiceProcess.TimeoutException] {
            continue
        }
    }
    return $true
}

function Exit-Process([int] $Code) {
    exit $Code
}

function Confirm-Action([bool] $TimeoutIsError = $true, [int] $TimeoutSeconds = 60) {
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($TimeoutSeconds)
    $ret = @{
        isError = $true
        result  = 'Error'
    }
    try {
        (Get-Host).UI.RawUI.FlushInputBuffer()
        while ($true) {
            if ((Get-Host).UI.RawUI.KeyAvailable) {
                $keyinfo = (Get-Host).UI.RawUI.ReadKey('IncludeKeyUp,NoEcho')
                if ('y' -ieq $keyInfo.Character) {
                    $ret.isError = $false
                    $ret.result = 'Y'
                    break
                }
                if ('n' -ieq $keyInfo.Character) {
                    $ret.isError = $true
                    $ret.result = 'N'
                    break
                }
                # ESC
                if (27 -eq $keyinfo.Character) {
                    $ret.isError = $true
                    $ret.result = 'Cancelled'
                    break
                }
            }
            if ((Get-Date) -ge $endTime) {
                $ret.isError = $TimeoutIsError
                $ret.result = 'Timeout'
                break
            }
            Start-Sleep -Milliseconds 500
        }
    }
    finally {
        (Get-Host).UI.RawUI.FlushInputBuffer()
    }
    return $ret
}

function Resolve-UninstallDirectory([String] $Dir, [String] $App = $null, [String] $OldVersion = $null) {
    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    if ((Test-Path $Dir) -or [String]::IsNullOrEmpty($App) -or [String]::IsNullOrEmpty($OldVersion)) {
        return $Dir
    }
    $appRoot = "$(appdir $App)\$OldVersion"
    $candidates = @(
        Get-ChildItem $appRoot -Recurse | Where-Object {
            $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
        } | ForEach-Object {
            $fontFile = "$fontsDir\$($_.Name)"
            if (Test-Path $fontFile) {
                $_.DirectoryName
            }
        } | Sort-Object -Unique
    )
    if ($candidates.Count -ne 1) {
        error "Couldn't resolve the uninstall directory."
        if ($candidates.Count -eq 0) {
            error "Specified: '$Dir'"
        }
        else {
            error "Multiple directories were found:"
            $candidates | ForEach-Object { error "  $_" }
        }
        Exit-Process 1
    }
    $resolvedDir = $candidates[0]

    warn "The specified uninstall directory does not exist:"
    warn "  $Dir"
    warn "A different directory was found:"
    warn "  $resolvedDir"

    info 'Continue uninstalling from this directory? [y/N]'
    $ret = Confirm-Action
    if ($ret.isError) {
        info 'Uninstall cancelled.'
        Exit-Process 1
    }
    return $resolvedDir
}

function Install-Font([String] $Dir) {
    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    $installedFontFamilies = Invoke-Job ${function:Get-InstalledFontFamily}
    New-Item $fontsDir -ItemType Directory -ErrorAction SilentlyContinue
    Get-ChildItem $Dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontFamilies = Invoke-Job ${function:Get-FontFamily} $_.FullName
        $alreadyInstalledFontFamilies = Get-AlreadyInstalledFontFamily $installedFontFamilies $fontFamilies
        if (@($alreadyInstalledFontFamilies).Count -gt 0) {
            error "Already exists font '$($alreadyInstalledFontFamilies | Select-Object -first 1)' in '$($_.FullName)'"
            Exit-Process 1
        }
    }
    Get-ChildItem $Dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontFile = "$fontsDir\$($_.Name)"
        Remove-Item $fontFile -ErrorAction SilentlyContinue
        if (Test-Path $fontFile) {
            error "Couldn't remove '$fontFile'; it may be in use."
            Exit-Process 1
        }
        Copy-Item $_.FullName -Destination $fontsDir
    }
    Get-ChildItem $Dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontName = Get-FontName $_
        info "Installing font $($_.Name) -> $fontName"
        $fontFile = "$fontsDir\$($_.Name)"
        New-ItemProperty -Path $regPath -Name $fontName -Value $fontFile -Force | Out-Null
    }
}

function Uninstall-Font([String] $Dir) {
    $Dir = Resolve-UninstallDirectory -Dir $Dir -App $app -OldVersion $old_version

    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    Get-ChildItem $Dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontName = Get-FontName $_
        info "Uninstalling font $($_.Name) -> $fontName"
        Remove-ItemProperty -Path $regPath -Name $fontName -ErrorAction SilentlyContinue
    }
    if ((Get-Service 'FontCache').Status -eq 'Running') {
        info 'Stop FontCache service (stop the service manually as needed; ESC to cancel waiting and continue)'
        if (is_admin) {
            Stop-Service FontCache
        }
        $ret = Wait-ForCondition -ConditionScript ${function:Wait-ServiceStopped} -TimeoutSeconds 60 -ScriptArgumentList 'FontCache'
        if ($ret.isError) {
            warn "$($ret.result) and continue"
        }
    }
    Get-ChildItem $Dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontFile = "$fontsDir\$($_.Name)"
        Remove-Item $fontFile -ErrorAction SilentlyContinue
        if (Test-Path $fontFile) {
            error "Couldn't remove '$fontFile'; it may be in use."
            Exit-Process 1
        }
    }
}
