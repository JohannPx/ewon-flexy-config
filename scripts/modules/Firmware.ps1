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
        & $OnLog "Firmware $Version deja en cache"
        return $true
    }

    & $OnLog "Telechargement firmware $Version..."
    try {
        $ebusUrl = "$baseUrl/er-$versionForUrl-arm-ma_secure.ebus"
        Invoke-WebRequest -Uri $ebusUrl -OutFile $ebusPath -UseBasicParsing

        if ($HasEbu) {
            $ebuUrl = "$baseUrl/er-$versionForUrl-arm-ma.ebu"
            $ebuPath = Join-Path $versionDir "ewonfwr.ebu"
            try {
                Invoke-WebRequest -Uri $ebuUrl -OutFile $ebuPath -UseBasicParsing
            } catch {
                & $OnLog "Note: .ebu non disponible pour $Version (OK)"
            }
        }

        & $OnLog "[OK] Firmware $Version telecharge"
        return $true
    } catch {
        & $OnLog "[ERREUR] $($_.Exception.Message)"
        return $false
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

    if (-not (Test-Path $targetFwDir)) { throw "Firmware non trouve dans le cache: $targetFwDir" }

    $ebus = Join-Path $targetFwDir "ewonfwr.ebus"
    $ebu  = Join-Path $targetFwDir "ewonfwr.ebu"

    $filesToCopy = @()
    if ($CurrentFw -eq "14.x" -and (Test-Path $ebu)) {
        $filesToCopy = @($ebus, $ebu)
        & $OnLog "Migration 14.x -> $TargetFw : ewonfwr.ebus et ewonfwr.ebu"
    } else {
        $filesToCopy = @($ebus)
        & $OnLog "Mise a jour -> $TargetFw : ewonfwr.ebus"
    }

    foreach ($src in $filesToCopy) {
        $leaf = Split-Path $src -Leaf
        $dest = Join-Path $SdRoot $leaf
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dest -Force
            & $OnLog "+ $leaf copie"
        } else {
            & $OnLog "! Fichier manquant: $src"
        }
    }
}
