# Firmware.ps1 - Firmware version parsing, download, compatibility

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

function Download-HMSFirmware {
    param(
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][bool]$HasEbu,
        [scriptblock]$OnLog = { param($msg) }
    )

    $versionForUrl = $Version -replace '\.', '-'
    $baseUrl = "https://hmsnetworks.blob.core.windows.net/nlw/docs/default-source/products/ewon/monitored/firmware/source"

    $cacheDir = Get-LocalCacheDir
    $fwBaseDir = New-Dir (Join-Path $cacheDir "firmware")
    $versionDir = New-Dir (Join-Path $fwBaseDir $Version)

    $ebusPath = Join-Path $versionDir "ewonfwr.ebus"
    if (Test-Path $ebusPath) {
        & $OnLog ((T "FwCached") -f $Version)
        return $true
    }

    & $OnLog ((T "FwDownloading") -f $Version)
    try {
        $ebusUrl = "$baseUrl/er-$versionForUrl-arm-ma_secure.ebus"
        Invoke-WebRequest -Uri $ebusUrl -OutFile $ebusPath -UseBasicParsing

        if ($HasEbu) {
            $ebuUrl = "$baseUrl/er-$versionForUrl-arm-ma.ebu"
            $ebuPath = Join-Path $versionDir "ewonfwr.ebu"
            try {
                Invoke-WebRequest -Uri $ebuUrl -OutFile $ebuPath -UseBasicParsing
            } catch {
                & $OnLog ((T "FwEbuNote") -f $Version)
            }
        }

        & $OnLog ((T "FwDownloaded") -f $Version)
        return $true
    } catch {
        & $OnLog "$(T 'ErrorPrefix') $($_.Exception.Message)"
        return $false
    }
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
        $baseUrl = "https://hmsnetworks.blob.core.windows.net/nlw/docs/default-source/products/ewon/monitored/firmware/source"
        foreach ($fw in $FwList) {
            $State.CurrentFw = $fw.version
            $State.Status = "Downloading"
            try {
                $versionDir = Join-Path $BaseCache "firmware\$($fw.version)"
                if (-not (Test-Path $versionDir)) {
                    New-Item -Path $versionDir -ItemType Directory -Force | Out-Null
                }
                $ebusPath = Join-Path $versionDir "ewonfwr.ebus"
                if (-not (Test-Path $ebusPath)) {
                    $vUrl = $fw.version -replace '\.', '-'
                    $wc = New-Object System.Net.WebClient
                    $wc.DownloadFile("$baseUrl/er-$vUrl-arm-ma_secure.ebus", $ebusPath)
                    $wc.Dispose()
                }
                $hasEbu = if ($fw.hasEbu) { [bool]$fw.hasEbu } else { $false }
                if ($hasEbu) {
                    $ebuPath = Join-Path $versionDir "ewonfwr.ebu"
                    if (-not (Test-Path $ebuPath)) {
                        $vUrl = $fw.version -replace '\.', '-'
                        $wc = New-Object System.Net.WebClient
                        try { $wc.DownloadFile("$baseUrl/er-$vUrl-arm-ma.ebu", $ebuPath) } catch {}
                        $wc.Dispose()
                    }
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
        [array]$AvailableFirmwares
    )

    $currentMajor = if ($CurrentFw -eq "14.x") { 14 } else { 15 }
    if ($currentMajor -eq 14) {
        return @($AvailableFirmwares | Where-Object { $_.Major -eq 15 -and $_.Minor -eq 0 })
    } else {
        return @($AvailableFirmwares | Where-Object { $_.Major -ge 15 })
    }
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
        $Manifest,
        [scriptblock]$OnLog = { param($msg) }
    )

    if (-not $TargetFw) { return }

    $cacheDir = Get-LocalCacheDir
    $fwDir = Join-Path $cacheDir "firmware"
    $targetFwDir = Join-Path $fwDir $TargetFw

    if (-not (Test-Path $targetFwDir)) { throw ((T "FwNotFound") -f $targetFwDir) }

    $ebus = Join-Path $targetFwDir "ewonfwr.ebus"
    $ebu  = Join-Path $targetFwDir "ewonfwr.ebu"

    $filesToCopy = @()
    if ($CurrentFw -eq "14.x" -and (Test-Path $ebu)) {
        $filesToCopy = @($ebus, $ebu)
        & $OnLog ((T "FwMigration") -f $TargetFw)
    } else {
        $filesToCopy = @($ebus)
        & $OnLog ((T "FwUpdateMsg") -f $TargetFw)
    }

    foreach ($src in $filesToCopy) {
        $leaf = Split-Path $src -Leaf
        $dest = Join-Path $SdRoot $leaf
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dest -Force
            & $OnLog ((T "FwCopied") -f $leaf)
        } else {
            & $OnLog ((T "FwFileMissing") -f $src)
        }
    }
}
