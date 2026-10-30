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

# Le firmware est distribue sous forme d'image complete .ebus (commune a tous les Flexy),
# accompagnee du .ebu pour un Ewon encore en 14.x. Contrairement au paquet .edfs, l'Ewon ne
# reinstalle pas une image .ebus deja en place : la carte peut rester telle quelle pour la
# deuxieme insertion, qui applique backup.tar et T2M.txt.

# Retourne les fichiers du firmware a copier sur la SD pour le firmware actuel de l'Ewon.
function Get-FirmwareFilesForCurrent {
    param($FwInfo, [string]$CurrentFw)
    return @(Get-FwProp $FwInfo 'files' @() | Where-Object {
        $copyOnlyForCurrent = [string](Get-FwProp $_ 'copyOnlyForCurrent' '')
        -not $copyOnlyForCurrent -or $copyOnlyForCurrent -eq $CurrentFw
    })
}

function Get-FirmwareSdFiles {
    param($FwInfo, [string]$CurrentFw)
    return @(Get-FirmwareFilesForCurrent -FwInfo $FwInfo -CurrentFw $CurrentFw | ForEach-Object { [string](Get-FwProp $_ 'sdName' '') } | Where-Object { $_ })
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

    # Already cached if every file exists locally.
    $missing = @($files | Where-Object {
        $cacheName = [string](Get-FwProp $_ 'cacheName' '')
        $cacheName -and -not (Test-Path (Join-Path $versionDir $cacheName))
    })
    if ($files.Count -gt 0 -and $missing.Count -eq 0) {
        & $OnLog ((T "FwCached") -f $FwInfo.version)
        return $true
    }

    & $OnLog ((T "FwDownloading") -f $FwInfo.version)
    foreach ($f in $missing) {
        $url  = [string](Get-FwProp $f 'url' '')
        if (-not $url) { continue }
        $dest = Join-Path $versionDir ([string](Get-FwProp $f 'cacheName' ''))
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        } catch {
            Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
            & $OnLog "$(T 'ErrorPrefix') $($_.Exception.Message)"
            return $false
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
                    if (-not $url -or -not $cacheName) { continue }
                    $dest = Join-Path $versionDir $cacheName
                    if (Test-Path $dest) { continue }
                    $wc = New-Object System.Net.WebClient
                    try { $wc.DownloadFile($url, $dest) }
                    catch { Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue; throw }
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

# Une image .ebus 15.x s'installe directement depuis la 14.x comme depuis la 15.x.
function Get-CompatibleFirmwares {
    param([array]$AvailableFirmwares)
    return @($AvailableFirmwares | Where-Object { $_.Major -ge 15 })
}

function Get-CurrentFirmwareOptions {
    param([array]$AvailableFirmwares)

    $options = @("14.x")
    foreach ($fw in ($AvailableFirmwares | Where-Object { $_.Major -eq 15 })) {
        $options += ("{0}.x" -f $fw.Major)
    }
    return $options | Select-Object -Unique
}

# Motif des fichiers firmware traites par l'Ewon a la racine de la SD (ewonfwr.* et dewonfwr.*).
$Script:SdFirmwareFilePattern = "*ewonfwr.*"

# Supprime les firmwares laisses par une preparation precedente : un ancien fichier serait
# traite en plus du firmware cible (un .edf/.edfs est meme reinstalle a chaque insertion et
# empeche alors l'application de backup.tar).
function Remove-FirmwareFromSD {
    param(
        [Parameter(Mandatory)][string]$SdRoot,
        [scriptblock]$OnLog = { param($msg) }
    )
    foreach ($file in @(Get-ChildItem -Path $SdRoot -Filter $Script:SdFirmwareFilePattern -File -Force)) {
        Remove-Item -LiteralPath $file.FullName -Force
        & $OnLog ((T "FwRemoved") -f $file.Name)
    }
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

    foreach ($f in (Get-FirmwareFilesForCurrent -FwInfo $fwInfo -CurrentFw $CurrentFw)) {
        $cacheName = [string](Get-FwProp $f 'cacheName' '')
        $sdName    = [string](Get-FwProp $f 'sdName' '')
        if (-not $cacheName -or -not $sdName) { continue }

        $src  = Join-Path $targetDir $cacheName
        $dest = Join-Path $SdRoot $sdName
        if (-not (Test-Path $src)) {
            & $OnLog ((T "FwFileMissing") -f $src)
            continue
        }
        Copy-Item -Path $src -Destination $dest -Force
        & $OnLog ((T "FwCopied") -f $sdName)
    }
}
