# Firmware.ps1 - Firmware version parsing, download, compatibility

$Script:HmsFirmwareBaseUrl = "https://hmsnetworks.blob.core.windows.net/nlw/docs/default-source/products/ewon/monitored/firmware/source"

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

function Get-FlexyProductCode {
    param([string]$FlexyModel)
    switch ($FlexyModel) {
        "202" { return 21 }
        "205" { return 24 }
        default { return 21 }
    }
}

# Returns the list of files to download for a firmware entry: @{Url; CacheName}
function Get-FirmwareDownloadFiles {
    param([Parameter(Mandatory)]$FwInfo)

    $verDash       = $FwInfo.version -replace '\.', '-'
    $verUnderscore = $FwInfo.version -replace '\.', '_'
    $format        = [string](Get-FwProp $FwInfo 'format' 'ebus-secure')
    $hasEbu        = [bool]  (Get-FwProp $FwInfo 'hasEbu' $false)
    $productCodes  = @(Get-FwProp $FwInfo 'productCodes' @())
    $files = @()

    switch ($format) {
        "edfs-pc" {
            foreach ($pc in $productCodes) {
                $files += @{
                    Url       = "$Script:HmsFirmwareBaseUrl/er${verUnderscore}p${pc}_ma.edfs"
                    CacheName = "ewonfwr_p${pc}.edfs"
                }
            }
        }
        default {
            $files += @{
                Url       = "$Script:HmsFirmwareBaseUrl/er-${verDash}-arm-ma_secure.ebus"
                CacheName = "ewonfwr.ebus"
            }
            if ($hasEbu) {
                $files += @{
                    Url       = "$Script:HmsFirmwareBaseUrl/er-${verDash}-arm-ma.ebu"
                    CacheName = "ewonfwr.ebu"
                }
            }
        }
    }

    return $files
}

function Download-HMSFirmware {
    param(
        [Parameter(Mandatory)]$FwInfo,
        [scriptblock]$OnLog = { param($msg) }
    )

    $cacheDir   = Get-LocalCacheDir
    $fwBaseDir  = New-Dir (Join-Path $cacheDir "firmware")
    $versionDir = New-Dir (Join-Path $fwBaseDir $FwInfo.version)
    $files      = Get-FirmwareDownloadFiles -FwInfo $FwInfo

    # Required files = all files that don't end with .ebu (the .ebu is best-effort)
    $required = @($files | Where-Object { -not $_.CacheName.EndsWith('.ebu') })
    $allRequiredCached = $true
    foreach ($f in $required) {
        if (-not (Test-Path (Join-Path $versionDir $f.CacheName))) { $allRequiredCached = $false; break }
    }
    if ($allRequiredCached) {
        & $OnLog ((T "FwCached") -f $FwInfo.version)
        return $true
    }

    & $OnLog ((T "FwDownloading") -f $FwInfo.version)
    foreach ($f in $files) {
        $dest = Join-Path $versionDir $f.CacheName
        if (Test-Path $dest) { continue }
        try {
            Invoke-WebRequest -Uri $f.Url -OutFile $dest -UseBasicParsing
        } catch {
            if ($f.CacheName.EndsWith('.ebu')) {
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
        param($FwList, $State, $BaseCache, $BaseUrl)

        # Background runspace: no Set-StrictMode, but stay defensive about optional manifest fields.
        function Get-Prop { param($Obj, $Name, $Default = $null)
            if ($null -eq $Obj) { return $Default }
            $p = $Obj.PSObject.Properties[$Name]
            if ($p) { return $p.Value }
            return $Default
        }

        function Build-Files {
            param($Fw)
            $verDash       = $Fw.version -replace '\.', '-'
            $verUnderscore = $Fw.version -replace '\.', '_'
            $format        = [string](Get-Prop $Fw 'format' 'ebus-secure')
            $hasEbu        = [bool]  (Get-Prop $Fw 'hasEbu' $false)
            $productCodes  = @(Get-Prop $Fw 'productCodes' @())
            $list = @()
            switch ($format) {
                "edfs-pc" {
                    foreach ($pc in $productCodes) {
                        $list += @{ Url = "$BaseUrl/er${verUnderscore}p${pc}_ma.edfs"; CacheName = "ewonfwr_p${pc}.edfs"; Optional = $false }
                    }
                }
                default {
                    $list += @{ Url = "$BaseUrl/er-${verDash}-arm-ma_secure.ebus"; CacheName = "ewonfwr.ebus"; Optional = $false }
                    if ($hasEbu) {
                        $list += @{ Url = "$BaseUrl/er-${verDash}-arm-ma.ebu"; CacheName = "ewonfwr.ebu"; Optional = $true }
                    }
                }
            }
            return $list
        }

        foreach ($fw in $FwList) {
            $State.CurrentFw = $fw.version
            $State.Status = "Downloading"
            try {
                $versionDir = Join-Path $BaseCache "firmware\$($fw.version)"
                if (-not (Test-Path $versionDir)) {
                    New-Item -Path $versionDir -ItemType Directory -Force | Out-Null
                }
                foreach ($f in (Build-Files -Fw $fw)) {
                    $dest = Join-Path $versionDir $f.CacheName
                    if (Test-Path $dest) { continue }
                    $wc = New-Object System.Net.WebClient
                    try { $wc.DownloadFile($f.Url, $dest) }
                    catch { if (-not $f.Optional) { throw } }
                    finally { $wc.Dispose() }
                }
            } catch {}
            $State.Index++
        }
        $State.Status = "Complete"
        $State.Done = $true
    }).AddArgument($Firmwares).AddArgument($Script:FwCacheState).AddArgument($CacheDir).AddArgument($Script:HmsFirmwareBaseUrl)

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

    $cacheDir   = Get-LocalCacheDir
    $fwDir      = Join-Path $cacheDir "firmware"
    $targetDir  = Join-Path $fwDir $TargetFw
    if (-not (Test-Path $targetDir)) { throw ((T "FwNotFound") -f $targetDir) }

    $fwInfo = $null
    if ($Manifest) {
        $fwInfo = $Manifest.firmwares | Where-Object { $_.version -eq $TargetFw } | Select-Object -First 1
    }
    $format   = [string](Get-FwProp $fwInfo 'format'   'ebus-secure')
    $destName = [string](Get-FwProp $fwInfo 'destName' 'ewonfwr.ebus')

    switch ($format) {
        "edfs-pc" {
            $pc      = Get-FlexyProductCode -FlexyModel $FlexyModel
            $srcName = "ewonfwr_p${pc}.edfs"
            $src     = Join-Path $targetDir $srcName
            if (-not (Test-Path $src)) { & $OnLog ((T "FwFileMissing") -f $src); return }
            Copy-Item -Path $src -Destination (Join-Path $SdRoot $destName) -Force
            & $OnLog ((T "FwUpdateMsg") -f $TargetFw)
            & $OnLog ((T "FwCopied") -f $destName)
        }
        default {
            $ebus = Join-Path $targetDir "ewonfwr.ebus"
            $ebu  = Join-Path $targetDir "ewonfwr.ebu"
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
    }
}
