function Get-FontInfo([System.IO.FileInfo] $file, $index) {
    $job = Start-Job -ScriptBlock {
        Add-Type -AssemblyName PresentationCore
        $uri = [UriBuilder]::new($using:file.FullName)
        $uri.Fragment = $using:index
        $font = [Windows.Media.GlyphTypeface]::new($uri.Uri)
        return @{
            'FamilyName' = $font.FamilyNames['en-US']
            'FaceName' = $font.FaceNames['en-US']
            'Win32FamilyName' = $font.Win32FamilyNames['en-US']
            'Win32FaceName' = $font.Win32FaceNames['en-US']
        }
    }
    Wait-Job -Job $job | Out-Null
    $ret = Receive-Job $job
    Remove-Job $job
    return $ret
}

function Get-NumberOfFonts([System.IO.FileInfo] $file) {
    try {
        $fr = [System.IO.File]::Open($file,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::ReadWrite + [System.IO.FileShare]::Delete)
        $br = [System.IO.BinaryReader]::new($fr)
        $br.ReadBytes(4+2+2) | Out-Null
        $b = $br.ReadBytes(4)
        if ([BitConverter]::IsLittleEndian) {
            [Array]::Reverse($b)
        }
        $ret = [BitConverter]::ToUInt32($b, 0)
    } finally {
        if ($br -ne $null) {
            $br.Close()
        }
        if ($fr -ne $null) {
            $fr.Close()
        }
    }
    return $ret
}

function Get-TTFName([System.IO.FileInfo] $file) {
    $fontInfo = Get-FontInfo $file
    return "$($fontInfo.Win32FamilyName) $($fontInfo.Win32FaceName) (TrueType)"
}

function Get-TTCName([System.IO.FileInfo] $file) {
    $numFonts = Get-NumberOfFonts($file)
    $i = 0
    $fontList = @()
    while ($i -lt $numFonts) {
        $fontInfo = Get-FontInfo $file $i
        if ("$($fontInfo.FamilyName) $($fontInfo.FaceName)" -eq $fontInfo.Win32FamilyName) {
            $fontList += $fontInfo.Win32FamilyName
        } else {
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
 
function Install-Font($dir) {
    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    New-Item $fontsDir -ItemType Directory -ErrorAction SilentlyContinue
    Get-ChildItem $dir -Recurse | Where-Object {
        $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        if ($_.Extension -eq '.ttf') {
            $fontName = Get-TTFName($_)
        } elseif ($_.Extension -eq '.ttc') {
            $fontName = Get-TTCName($_)
        }
        info "Installing font $($_.Name) -> $fontName"
        Copy-Item $_.FullName -Destination $fontsDir
        New-ItemProperty -Path $regPath -Name $fontName -Value "$fontsDir\$($_.Name)" -Force | Out-Null
    }
}

function Uninstall-Font($dir) {
    if (!(is_admin)) { error 'Use sudo'; exit 1 }
    $fontsDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    Get-ChildItem $dir -Recurse | Where-Object {
        $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        if ($_.Extension -eq '.ttf') {
            $fontName = Get-TTFName($_)
        } elseif ($_.Extension -eq '.ttc') {
            $fontName = Get-TTCName($_)
        }
        info "Uninstalling font $($_.Name) -> $fontName"
        Remove-ItemProperty -Path $regPath -Name $fontName -ErrorAction SilentlyContinue
    }
    if ((Get-Service 'FontCache').Status -eq 'Running') {
        info 'Restart FontCache service'
        Restart-Service FontCache
    }
    Get-ChildItem $dir -Recurse | Where-Object {
        $_.Extension -eq '.ttf' -or $_.Extension -eq '.ttc'
    } | ForEach-Object {
        $fontFile = "$fontsDir\$($_.Name)"
        Remove-Item $fontFile -ErrorAction SilentlyContinue
        if (Test-Path $fontFile) {
            warn "Couldn't remove '$fontFile'; it may be in use."
        }
    }
}
