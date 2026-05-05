# Firmware.ps1 - Firmware version parsing, download, compatibility

# Strict-mode-safe accessor for optional PSCustomObject properties (manifest fields).
function Get-FwProp {
    param($Object, [string]$Name, $Default = $null)
    if ($null -eq $Object) { return $Default }
    $prop = $Object.PSObject.Properties[$Name]
    if ($prop) { return $prop.Value }
    return $Default
}

function Parse-FirmwareVersion {
    param([string]$Version)
    if ($Version -match '^(\d+)\.(\d+)s?(\d+)?$') {
        $maj = [int]$Matches[1]
        $min = [int]$Matches[2]
        $svc = if ($Matches[3]) { [int]$Matches[3] } else { 0 }
        return [PSCustomObject]@{ Major=$maj; Minor=$min; Service=$svc; Full=$Version }
    }
    return $null
}

# Returns the subset of files[] that should be copied to the SD card,
# given the current firmware (for migration .ebu) and Flexy model (for PC-specific .edfs).
function Get-FirmwareSdFiles {
    param($FwInfo, [string]$CurrentFw, [string]$FlexyModel)

    $sdFiles = @()
    foreach ($f in @(Get-FwProp $FwInfo 'files' @())) {
        $copyOnlyForCurrent = [string](Get-FwProp $f 'copyOnlyForCurrent' '')
        $forFlexy           = [string](Get-FwProp $f 'forFlexy' '')
        if ($copyOnlyForCurrent -and $copyOnlyForCurrent -ne $CurrentFw) { continue }
        if ($forFlexy           -and $forFlexy           -ne $FlexyModel) { continue }
        $sdName = [string](Get-FwProp $f 'sdName' '')
        if ($sdName) { $sdFiles += $sdName }
    }
    return $sdFiles
}

function Download-HMSFirmware {
    param(
        [Parameter(Mandatory)]$FwInfo,
        [scriptblock]$OnLog = { param($msg) }
    )

    $cacheDir   = Get-LocalCacheDir
    $fwBaseDir  = New-Dir (Join-Path $cacheDir "firmware")
    $versionDir = New-Dir (Join-Path $fwBaseDir $FwInfo.version)
    $files      = @(Get-FwProp $FwInfo 'files' @())

    # Already cached if every required file exists locally.
    $allRequiredCached = $true
    $hasRequired = $false
    foreach ($f in $files) {
        $optional  = [bool]  (Get-FwProp $f 'optional' $false)
        if ($optional) { continue }
        $hasRequired = $true
        $cacheName = [string](Get-FwProp $f 'cacheName' '')
        if (-not $cacheName) { continue }
        if (-not (Test-Path (Join-Path $versionDir $cacheName))) { $allRequiredCached = $false; break }
    }
    if ($hasRequired -and $allRequiredCached) {
        & $OnLog ((T "FwCached") -f $FwInfo.version)
        return $true
    }

    & $OnLog ((T "FwDownloading") -f $FwInfo.version)
    foreach ($f in $files) {
        $url       = [string](Get-FwProp $f 'url' '')
        $cacheName = [string](Get-FwProp $f 'cacheName' '')
        $optional  = [bool]  (Get-FwProp $f 'optional' $false)
        if (-not $url -or -not $cacheName) { continue }
        $dest = Join-Path $versionDir $cacheName
        if (Test-Path $dest) { continue }
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        } catch {
            if ($optional) {
                & $OnLog ((T "FwEbuNote") -f $FwInfo.version)
            } else {
                & $OnLog "$(T 'ErrorPrefix') $($_.Exception.Message)"
                return $false
            }
        }
    }

    & $OnLog ((T "FwDownloaded") -f $FwInfo.version)
    return $true
}

function Start-BackgroundFirmwareCache {
    param([array]$Firmwares, [string]$CacheDir)

    # Synchronized hashtable shared between UI thread and background runspace
    $Script:FwCacheState = [hashtable]::Synchronized(@{
        Status    = "Starting"
        CurrentFw = ""
        Index     = 0
        Total     = $Firmwares.Count
        Done      = $false
    })

    $ps = [powershell]::Create()
    $ps.Runspace = [runspacefactory]::CreateRunspace()
    $ps.Runspace.Open()

    $null = $ps.AddScript({
        param($FwList, $State, $BaseCache)

        function Get-Prop { param($Obj, $Name, $Default = $null)
            if ($null -eq $Obj) { return $Default }
            $p = $Obj.PSObject.Properties[$Name]
            if ($p) { return $p.Value }
            return $Default
        }

        foreach ($fw in $FwList) {
            $State.CurrentFw = $fw.version
            $State.Status = "Downloading"
            try {
                $versionDir = Join-Path $BaseCache "firmware\$($fw.version)"
                if (-not (Test-Path $versionDir)) {
                    New-Item -Path $versionDir -ItemType Directory -Force | Out-Null
                }
                foreach ($f in @(Get-Prop $fw 'files' @())) {
                    $url       = [string](Get-Prop $f 'url' '')
                    $cacheName = [string](Get-Prop $f 'cacheName' '')
                    $optional  = [bool]  (Get-Prop $f 'optional' $false)
                    if (-not $url -or -not $cacheName) { continue }
                    $dest = Join-Path $versionDir $cacheName
                    if (Test-Path $dest) { continue }
                    $wc = New-Object System.Net.WebClient
                    try { $wc.DownloadFile($url, $dest) }
                    catch { if (-not $optional) { throw } }
                    finally { $wc.Dispose() }
                }
            } catch {}
            $State.Index++
        }
        $State.Status = "Complete"
        $State.Done = $true
    }).AddArgument($Firmwares).AddArgument($Script:FwCacheState).AddArgument($CacheDir)

    $Script:FwCachePowerShell = $ps
    $Script:FwCacheAsync = $ps.BeginInvoke()
}

function Stop-BackgroundFirmwareCache {
    if ($Script:FwCachePowerShell) {
        try { $Script:FwCachePowerShell.Stop() } catch {}
        try { $Script:FwCachePowerShell.Runspace.Close() } catch {}
        try { $Script:FwCachePowerShell.Dispose() } catch {}
        $Script:FwCachePowerShell = $null
        $Script:FwCacheAsync = $null
    }
}

function Get-AvailableFirmwares {
    param($Manifest)

    $cacheDir = Get-LocalCacheDir
    $firmwarePath = Join-Path $cacheDir "firmware"
    $fw = @()

    if ($Manifest) {
        foreach ($f in $Manifest.firmwares) {
            $v = Parse-FirmwareVersion $f.version
            if ($v) { $fw += $v }
        }
    } elseif (Test-Path $firmwarePath) {
        Get-ChildItem -Path $firmwarePath -Directory | ForEach-Object {
            $v = Parse-FirmwareVersion $_.Name
            if ($v) { $fw += $v }
        }
    }

    return $fw | Sort-Object -Property Major, Minor, Service
}

function Get-CompatibleFirmwares {
    param(
        [string]$CurrentFw,
        [array]$AvailableFirmwares,
        $Manifest
    )

    $currentMajor = if ($CurrentFw -eq "14.x") { 14 } else { 15 }

    $pivotVersions = @()
    if ($Manifest) {
        $pivotVersions = @($Manifest.firmwares | Where-Object { [bool](Get-FwProp $_ 'pivot' $false) } | ForEach-Object { $_.version })
    }

    if ($currentMajor -eq 14) {
        # 14.x must go through a pivot firmware first (typically 15.0s2).
        if ($pivotVersions.Count -gt 0) {
            return @($AvailableFirmwares | Where-Object { $pivotVersions -contains $_.Full })
        }
        # Fallback (no manifest / no pivot declared): show 15.0.x as before.
        return @($AvailableFirmwares | Where-Object { $_.Major -eq 15 -and $_.Minor -eq 0 })
    }

    # Already on 15.x: show all 15+ except pivots (no need to re-flash a pivot).
    return @($AvailableFirmwares | Where-Object { $_.Major -ge 15 -and ($pivotVersions -notcontains $_.Full) })
}

function Get-CurrentFirmwareOptions {
    param([array]$AvailableFirmwares)

    $options = @("14.x")
    foreach ($fw in ($AvailableFirmwares | Where-Object { $_.Major -eq 15 })) {
        $options += ("{0}.x" -f $fw.Major)
    }
    return $options | Select-Object -Unique
}

function Copy-FirmwareToSD {
    param(
        [Parameter(Mandatory)][string]$SdRoot,
        [string]$TargetFw,
        [string]$CurrentFw,
        [string]$FlexyModel,
        $Manifest,
        [scriptblock]$OnLog = { param($msg) }
    )

    if (-not $TargetFw) { return }

    $cacheDir  = Get-LocalCacheDir
    $targetDir = Join-Path (Join-Path $cacheDir "firmware") $TargetFw
    if (-not (Test-Path $targetDir)) { throw ((T "FwNotFound") -f $targetDir) }

    $fwInfo = $null
    if ($Manifest) {
        $fwInfo = $Manifest.firmwares | Where-Object { $_.version -eq $TargetFw } | Select-Object -First 1
    }
    if (-not $fwInfo) { throw ((T "FwNotFound") -f $TargetFw) }

    if ($CurrentFw -eq "14.x") {
        & $OnLog ((T "FwMigration") -f $TargetFw)
    } else {
        & $OnLog ((T "FwUpdateMsg") -f $TargetFw)
    }

    foreach ($f in @(Get-FwProp $fwInfo 'files' @())) {
        $copyOnlyForCurrent = [string](Get-FwProp $f 'copyOnlyForCurrent' '')
        $forFlexy           = [string](Get-FwProp $f 'forFlexy' '')
        if ($copyOnlyForCurrent -and $copyOnlyForCurrent -ne $CurrentFw) { continue }
        if ($forFlexy           -and $forFlexy           -ne $FlexyModel) { continue }

        $cacheName = [string](Get-FwProp $f 'cacheName' '')
        $sdName    = [string](Get-FwProp $f 'sdName' '')
        if (-not $cacheName -or -not $sdName) { continue }

        $src  = Join-Path $targetDir $cacheName
        $dest = Join-Path $SdRoot $sdName
        if (-not (Test-Path $src)) {
            $optional = [bool](Get-FwProp $f 'optional' $false)
            if (-not $optional) { & $OnLog ((T "FwFileMissing") -f $src) }
            continue
        }
        Copy-Item -Path $src -Destination $dest -Force
        & $OnLog ((T "FwCopied") -f $sdName)
    }
}
