function Invoke-Job([ScriptBlock] $JobScript, [Object[]] $ScriptArgumentList) {
    $job = Start-Job -ScriptBlock $JobScript -ArgumentList $ScriptArgumentList
    Wait-Job -Job $job | Out-Null
    $ret = Receive-Job $job
    Remove-Job $job
    return $ret
}

function Get-FontFamilies ([String] $fullName) {
    Add-Type -AssemblyName System.Drawing
    $col = [System.Drawing.Text.PrivateFontCollection]::new()
    $col.AddFontFile($fullName)
    $list = $col.Families.Name
    $col.Dispose()
    return $list
}

function Get-InstalledFontFamilies() {
    Add-Type -AssemblyName System.Drawing
    return [System.Drawing.FontFamily]::Families.Name
}

function Get-AlreadyInstalledFontFamilies([String[]] $installed, [String[]] $list) {
    return $list | Where-Object { $installed -contains $_ }
}

function Get-FontInfo([String] $fullName, [int] $index) {
    Add-Type -AssemblyName PresentationCore
    $uri = [UriBuilder]::new($fullName)
    $uri.Fragment = [String]$index
    $font = [Windows.Media.GlyphTypeface]::new($uri.Uri)
    return @{
        'FamilyName'      = $font.FamilyNames['en-US']
        'FaceName'        = $font.FaceNames['en-US']
        'Win32FamilyName' = $font.Win32FamilyNames['en-US']
        'Win32FaceName'   = $font.Win32FaceNames['en-US']
    }
}

function Get-NumberOfFonts([System.IO.FileInfo] $file) {
    try {
        $fr = [System.IO.File]::Open($file.FullName,
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

function Get-OTFName([System.IO.FileInfo] $file) {
    $fontInfo = Invoke-Job ${function:Get-FontInfo} $file.FullName
    return "$($fontInfo.Win32FamilyName) $($fontInfo.Win32FaceName) (OpenType)"
}

function Get-TTFName([System.IO.FileInfo] $file) {
    $fontInfo = Invoke-Job ${function:Get-FontInfo} $file.FullName
    return "$($fontInfo.Win32FamilyName) $($fontInfo.Win32FaceName) (TrueType)"
}

function Get-TTCName([System.IO.FileInfo] $file) {
    $numFonts = Get-NumberOfFonts $file
    $i = 0
    $fontList = @()
    while ($i -lt $numFonts) {
        $fontInfo = Invoke-Job ${function:Get-FontInfo} $file.FullName, $i
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

function Get-FontName([System.IO.FileInfo] $file) {
    if ($file.Extension -eq '.otf') {
        $fontName = Get-OTFName $file
    }
    elseif ($file.Extension -eq '.ttf') {
        $fontName = Get-TTFName $file
    }
    elseif ($file.Extension -eq '.ttc') {
        $fontName = Get-TTCName $file
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

function Wait-ServiceStopped([String] $serviceName) {
    while ($true) {
        try {
            (Get-Service $serviceName).WaitForStatus('Stopped', [TimeSpan]::New(0, 0, 0, 1))
            break
        }
        catch [System.ServiceProcess.TimeoutException] {
            # loop
        }
    }
    return $true
}

function Exit-Process([int] $code) {
    exit $code
}

function Install-Font([String] $dir) {
    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    $installedFontFamilies = Invoke-Job ${function:Get-InstalledFontFamilies}
    New-Item $fontsDir -ItemType Directory -ErrorAction SilentlyContinue
    Get-ChildItem $dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontFamilies = Invoke-Job ${function:Get-FontFamilies} $_.FullName
        $alreadyInstalledFontFamilies = Get-AlreadyInstalledFontFamilies $installedFontFamilies $fontFamilies
        if ($alreadyInstalledFontFamilies -gt 0) {
            error "Already exists font '$($alreadyInstalledFontFamilies | Select-Object -first 1)' in '$($_.FullName)'"
            Exit-Process 1
        }
    }
    Get-ChildItem $dir -Recurse | Where-Object {
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
    Get-ChildItem $dir -Recurse | Where-Object {
        $_.Extension -eq '.otf' -or $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontName = Get-FontName $_
        info "Installing font $($_.Name) -> $fontName"
        $fontFile = "$fontsDir\$($_.Name)"
        New-ItemProperty -Path $regPath -Name $fontName -Value $fontFile -Force | Out-Null
    }
}

function Uninstall-Font([String] $dir) {
    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    Get-ChildItem $dir -Recurse | Where-Object {
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
        $ret = Wait-ForCondition ${function:Wait-ServiceStopped} 60 'FontCache'
        if ($ret.isError) {
            warn "$($ret.result) and continue"
        }
    }
    Get-ChildItem $dir -Recurse | Where-Object {
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
