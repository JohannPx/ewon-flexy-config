# PowerShell Script: Prepare Ewon Flexy SD card with online sources (PUBLIC)
# Version: 3.3.1
# Author: JPR
# Date: 2025-09-09

# =================== GENERAL SETTINGS ===================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Console UTF-8 si dispo; tout le texte est en ASCII pour compatibilite EXE
try { chcp 65001 > $null } catch {}
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# TLS 1.2
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$Host.UI.RawUI.WindowTitle = "Preparation Carte SD Ewon Flexy"

# ======= GITHUB CONFIG (PUBLIC REPO - NO TOKEN) =======
$GitHubRepo   = "JohannPx/ewon-flexy-config"   # owner/repo
$GitHubBranch = "main"

# Local cache folder (manifest, configs, firmwares ONLY)
$LocalCacheDir = Join-Path $env:APPDATA "EwonFlexConfig"

# =================== UTILS & LOGGING ===================
function Log { param([string]$msg) $ts = (Get-Date).ToString('s'); Write-Host ("{0} | {1}" -f $ts, $msg) }
function New-Dir([string]$Path) { if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }; return $Path }
function Pause-End([string]$msg = "Appuyez sur Entree pour fermer") { Write-Host ""; Read-Host $msg | Out-Null }

# SecureString -> Plain (avec liberation memoire)
function Convert-SecureToPlain {
    param([Parameter(Mandatory)][System.Security.SecureString]$Secure)
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringUni($bstr)
    } finally {
        if ($bstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    }
}

# =================== T2M (ASK JUST BEFORE SD, NO CACHE) ===================
# NB: appelee seulement en modes 1 et 2 (pas en 3)
function Prompt-T2M {
    Write-Host ""
    Write-Host "=== Donnees Talk2M (T2M.txt sera ECRIT UNIQUEMENT SUR LA SD) ===" -ForegroundColor Cyan
    do {
        $sec = Read-Host "Entrez T2MKey (masquee)" -AsSecureString
        if (-not $sec -or $sec.Length -eq 0) { Write-Host "T2MKey est obligatoire." -ForegroundColor Red }
    } until ($sec -and $sec.Length -gt 0)

    do {
        $note = Read-Host "Entrez T2MNote (obligatoire, non masquee)"
        if (-not $note) { Write-Host "T2MNote est obligatoire." -ForegroundColor Red }
    } until ($note)

    $keyPlain = Convert-SecureToPlain -Secure $sec
    return [PSCustomObject]@{ Key = $keyPlain; Note = $note }
}

function Write-T2MDirect {
    param(
        [Parameter(Mandatory)][string]$SdRoot,
        [Parameter(Mandatory)][string]$T2MKey,
        [Parameter(Mandatory)][string]$T2MNote
    )
    $dest = Join-Path $SdRoot "T2M.txt"
    $content = @(
        ("T2MKey:{0}" -f $T2MKey)
        ("T2MNote:{0}" -f $T2MNote)
    )
    $content | Out-File -FilePath $dest -Encoding ASCII -Force
    Write-Host ("T2M.txt ecrit -> {0}" -f $dest) -ForegroundColor Green
    return $dest
}

# =================== DOWNLOADS (PUBLIC) ===================
function Get-Manifest {
    $manifestUrl = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/manifest.json"
    try {
        Write-Host "Recuperation du manifest..." -ForegroundColor Gray
        $json = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing
        return $json
    } catch {
        Write-Host "Manifest indisponible en ligne. Recherche en cache..." -ForegroundColor Yellow
        $cached = Join-Path $LocalCacheDir "manifest.json"
        if (Test-Path $cached) { return Get-Content $cached | ConvertFrom-Json }
        return $null
    }
}

function Download-Configuration {
    param([Parameter(Mandatory)][ValidateSet("ethernet","4g")] [string]$Type,
          [Parameter(Mandatory)][string]$LocalPath)

    $url = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/configurations/$Type/backup.tar"
    try {
        New-Dir (Split-Path $LocalPath) | Out-Null
        Write-Host "Telechargement configuration $Type..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing
        Write-Host "  [OK]" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [ERREUR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# =================== FIRMWARE HMS (PUBLIC HMS SITE) ===================
function Parse-FirmwareVersion {
    param([string]$version)
    # Supporte 15.0s2 ou 15.6
    if ($version -match '^(\d+)\.(\d+)s?(\d+)?$') {
        $maj = [int]$Matches[1]
        $min = [int]$Matches[2]
        $svc = if ($Matches[3]) { [int]$Matches[3] } else { 0 }
        return [PSCustomObject]@{ Major=$maj; Minor=$min; Service=$svc; Full=$version }
    }
    return $null
}

function Download-HMSFirmware {
    param([Parameter(Mandatory)][string]$Version,
          [Parameter(Mandatory)][bool]$HasEbu)

    # 15.0s2 -> er-15-0s2-arm-ma_secure.ebus
    $versionForUrl = $Version -replace '\.', '-'
    $baseUrl = "https://hmsnetworks.blob.core.windows.net/nlw/docs/default-source/products/ewon/monitored/firmware/source"

    $fwBaseDir = New-Dir (Join-Path $LocalCacheDir "firmware")
    $versionDir = New-Dir (Join-Path $fwBaseDir $Version)

    $ebusPath = Join-Path $versionDir "ewonfwr.ebus"
    if (Test-Path $ebusPath) {
        Write-Host "  Firmware $Version deja en cache" -ForegroundColor Gray
        return $true
    }

    Write-Host "  Telechargement firmware $Version..." -ForegroundColor Gray
    try {
        # .ebus (secure)
        $ebusUrl = "$baseUrl/er-$versionForUrl-arm-ma_secure.ebus"
        Invoke-WebRequest -Uri $ebusUrl -OutFile $ebusPath -UseBasicParsing

        # .ebu (pivot 14.x) si necessaire
        if ($HasEbu) {
            $ebuUrl = "$baseUrl/er-$versionForUrl-arm-ma.ebu"
            $ebuPath = Join-Path $versionDir "ewonfwr.ebu"
            try {
                Invoke-WebRequest -Uri $ebuUrl -OutFile $ebuPath -UseBasicParsing
            } catch {
                Write-Host "    Note: .ebu non disponible pour $Version (OK)" -ForegroundColor Yellow
            }
        }

        Write-Host "    [OK] Firmware telecharge" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "    [ERREUR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-AvailableFirmwares {
    param([string]$firmwarePath, $manifest)
    $fw = @()
    if ($manifest) {
        foreach ($f in $manifest.firmwares) {
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
    param([string]$currentFw, [array]$availableFirmwares)
    $currentMajor = if ($currentFw -eq "14.x") { 14 } else { 15 }
    if ($currentMajor -eq 14) {
        $availableFirmwares | Where-Object { $_.Major -eq 15 -and $_.Minor -eq 0 }
    } else {
        $availableFirmwares | Where-Object { $_.Major -ge 15 }
    }
}

function Select-FromList {
    param([string]$Title, [string[]]$Options, [switch]$AllowNone)
    Write-Host ""; Write-Host $Title -ForegroundColor Cyan
    $opt = @($Options)
    if ($opt.Count -eq 0) {
        if ($AllowNone) { Write-Host "  Aucune option" -ForegroundColor Yellow; return $null }
        throw "Aucune option disponible"
    }
    if ($AllowNone) { Write-Host "  [0] Aucun / Passer" }
    for($i=0;$i -lt $opt.Count;$i++){ Write-Host ("  [{0}] {1}" -f ($i+1), $opt[$i]) }
    do {
        $max = $opt.Count
        $prompt = if ($AllowNone) { "Choix 0-$max" } else { "Choix 1-$max" }
        $choice = Read-Host $prompt
        if ($AllowNone -and $choice -eq "0") { return $null }
    } while (-not ($choice -as [int]) -or [int]$choice -lt 1 -or [int]$choice -gt $opt.Count)
    return $opt[[int]$choice-1]
}

# ===================== MAIN =====================
try {
    $headerBorder = "=" * 70
    Write-Host $headerBorder -ForegroundColor DarkCyan
    Write-Host "                  PREPARATION CARTE SD EWON FLEXY" -ForegroundColor Cyan
    Write-Host $headerBorder -ForegroundColor DarkCyan
    Write-Host ""

    # Mode selection
    Write-Host "=== Mode de fonctionnement ===" -ForegroundColor Cyan
    Write-Host "  [1] ONLINE       - Telecharger manifest + configs (Internet requis)"
    Write-Host "  [2] CACHE        - Utiliser cache local existant"
    Write-Host "  [3] PREPARATION  - Telecharger TOUT pour usage offline (manifest, configs, firmwares)"
    Write-Host ""
    $mode = Read-Host "Choisissez 1, 2 ou 3"

    $manifest = $null
    $SourceDir = $LocalCacheDir  # on opere depuis le cache

    if ($mode -eq "3") {
        # PREPARATION: remplir le cache, pas de T2M ni ecriture SD
        Write-Host "`n=== Mode PREPARATION ===" -ForegroundColor Magenta
        Write-Host "Ce mode telecharge toutes les ressources necessaires." -ForegroundColor Yellow
        $confirm = Read-Host "Continuer ? (O/N)"
        if ($confirm -notin @("O","o")) { Write-Host "Annule" -ForegroundColor Red; Pause-End; exit }

        $null = New-Dir $LocalCacheDir

        # Manifest
        $manifest = Get-Manifest
        if (-not $manifest) { throw "Impossible de recuperer le manifest en ligne et aucun cache disponible." }

        # Save manifest in cache
        ($manifest | ConvertTo-Json -Depth 10) | Out-File (Join-Path $LocalCacheDir "manifest.json") -Encoding UTF8

        # Configs
        Write-Host "`nTelechargement des configurations..." -ForegroundColor Cyan
        Download-Configuration -Type "ethernet" -LocalPath (Join-Path $LocalCacheDir "configurations\ethernet\backup.tar") | Out-Null
        Download-Configuration -Type "4g"      -LocalPath (Join-Path $LocalCacheDir "configurations\4g\backup.tar")       | Out-Null

        # Firmwares
        Write-Host "`nTelechargement des firmwares..." -ForegroundColor Cyan
        foreach ($fw in @($manifest.firmwares)) {
            $hasEbu = [bool]$fw.hasEbu
            Download-HMSFirmware -Version $fw.version -HasEbu $hasEbu | Out-Null
        }

        Write-Host "`n=== PREPARATION TERMINEE ===" -ForegroundColor Green
        Write-Host "Cache: $LocalCacheDir" -ForegroundColor Green
        Pause-End
        exit
    }
    elseif ($mode -eq "1") {
        # ONLINE: manifest + configs
        Write-Host "`n=== Mode ONLINE ===" -ForegroundColor Green
        $null = New-Dir $LocalCacheDir

        $manifest = Get-Manifest
        if (-not $manifest) { throw "Impossible de continuer: manifest indisponible." }

        ($manifest | ConvertTo-Json -Depth 10) | Out-File (Join-Path $LocalCacheDir "manifest.json") -Encoding UTF8

        Write-Host "`nTelechargement des configurations..." -ForegroundColor Cyan
        Download-Configuration -Type "ethernet" -LocalPath (Join-Path $LocalCacheDir "configurations\ethernet\backup.tar") | Out-Null
        Download-Configuration -Type "4g"      -LocalPath (Join-Path $LocalCacheDir "configurations\4g\backup.tar")       | Out-Null
    }
    elseif ($mode -eq "2") {
        # CACHE
        Write-Host "`n=== Mode CACHE ===" -ForegroundColor Yellow
        if (-not (Test-Path $LocalCacheDir)) {
            throw "Aucun cache trouve: $LocalCacheDir. Utilisez ONLINE ou PREPARATION d'abord."
        }

        $manifestCache = Join-Path $LocalCacheDir "manifest.json"
        if (Test-Path $manifestCache) {
            $manifest = Get-Content $manifestCache | ConvertFrom-Json
            Write-Host "Manifest depuis cache" -ForegroundColor Yellow
        } else {
            Write-Host "Manifest absent du cache: certaines fonctions seront limitees." -ForegroundColor Yellow
        }
    }
    else {
        throw "Choix invalide"
    }

    # Working dirs
    $CfgDir    = Join-Path $LocalCacheDir "configurations"
    $FwDir     = Join-Path $LocalCacheDir "firmware"
    $CfgEthDir = Join-Path $CfgDir "ethernet"
    $Cfg4GDir  = Join-Path $CfgDir "4g"

    if ($mode -eq "2") {
        foreach($p in @($CfgEthDir,$Cfg4GDir)) {
            if (-not (Test-Path $p)) { throw "Cache incomplet. Dossier manquant: $p" }
        }
    }

    # Firmware list
    $availableFirmwares = @($(Get-AvailableFirmwares -firmwarePath $FwDir -manifest $manifest))
    if ( (@($availableFirmwares)).Count -eq 0 ) {
        Log "Aucun firmware disponible (OK si configuration seule)."
    } else {
        Write-Host "=== Firmwares disponibles ===" -ForegroundColor Cyan
        foreach ($fw in $availableFirmwares) { Write-Host ("  - {0}" -f $fw.Full) -ForegroundColor Gray }
        Write-Host ""
    }

    # Current firmware list
    Write-Host "=== AIDE FIRMWARE ACTUEL ===" -ForegroundColor Yellow
    Write-Host "Si inconnu: demarrer sans SD, lire via eBuddy." -ForegroundColor Gray
    Write-Host ""
    $currentFwOptions = @("14.x")
    foreach ($fw in ($availableFirmwares | Where-Object { $_.Major -eq 15 })) {
        $currentFwOptions += ("{0}.x" -f $fw.Major)
    }
    $currentFwOptions = $currentFwOptions | Select-Object -Unique
    $currentFw = Select-FromList -Title "Firmware ACTUEL de l'Ewon" -Options $currentFwOptions

    # Compatible firmwares
    $compatibleFirmwares = @($(Get-CompatibleFirmwares -currentFw $currentFw -availableFirmwares $availableFirmwares))
    $cfwCount = (@($compatibleFirmwares)).Count
    $targetFw = $null
    $skipFirmwareUpdate = $false

    if ($cfwCount -eq 0) {
        Write-Host "`nAucun firmware compatible disponible (configuration seule)." -ForegroundColor Yellow
        if ($currentFw -eq "14.x") {
            Write-Host "Migration 14.x -> 15.x necessite 15.0.x pivot." -ForegroundColor Yellow
        }
        $skipFirmwareUpdate = $true
    } elseif ($cfwCount -eq 1) {
        $targetFw = $compatibleFirmwares[0].Full
        Write-Host ("`nFirmware cible: {0}" -f $targetFw) -ForegroundColor Green
    } else {
        $fwOptions = $compatibleFirmwares | ForEach-Object { $_.Full }
        if ($currentFw -eq "14.x") {
            Write-Host "`nNote: migration depuis 14.x = firmwares pivot (15.0.x)" -ForegroundColor Yellow
        }
        $sel = Select-FromList -Title "Firmware cible" -Options $fwOptions -AllowNone
        if ($sel) { $targetFw = $sel } else { $skipFirmwareUpdate = $true; Write-Host "Pas de MAJ firmware" -ForegroundColor Yellow }
    }

    # If ONLINE and firmware requested, ensure in cache
    if ($mode -eq "1" -and -not $skipFirmwareUpdate -and $manifest) {
        Write-Host "`nPreparation du firmware..." -ForegroundColor Cyan
        $fwInfo = $manifest.firmwares | Where-Object { $_.version -eq $targetFw }
        $hasEbu = [bool]$fwInfo.hasEbu
        $ok = Download-HMSFirmware -Version $targetFw -HasEbu $hasEbu
        if (-not $ok) { throw "Telechargement firmware echoue." }
    }

    # Internet profile
    $profile = Select-FromList -Title "Internet" -Options @("Modem 4G","Ethernet")

    # --- T2M ASK NOW (JUSTE AVANT LA SELECTION DU LECTEUR), MODES 1 & 2 SEULEMENT ---
    $T2M = $null
    if ($mode -ne "3") {
        $T2M = Prompt-T2M   # T2MKey masquee, T2MNote obligatoire
    }

    # SD drive
    Write-Host "`n=== Selection lecteur SD ===" -ForegroundColor Cyan
    $sdDrive = Read-Host "Lettre du lecteur (ex: E: ou F:)"
    if ($sdDrive -match '^[A-Za-z]$') { $sdDrive = "${sdDrive}:\" }
    elseif ($sdDrive -match '^[A-Za-z]:$') { $sdDrive = "${sdDrive}\" }
    elseif ($sdDrive -notmatch '^[A-Za-z]:\\') { throw "Format de lecteur invalide ($sdDrive)" }
    if (-not (Test-Path $sdDrive)) { throw "Lecteur $sdDrive non trouve." }
    Log ("Drive={0}" -f $sdDrive)

    # Files to copy (configs d'abord)
    $filesToCopy = @()
    if ($profile -eq "Ethernet") { $filesToCopy += Join-Path $CfgEthDir "backup.tar" }
    else { $filesToCopy += Join-Path $Cfg4GDir "backup.tar" }

    # Firmware files to copy
    $firmwareNote = ""
    if (-not $skipFirmwareUpdate -and $targetFw) {
        $targetFwDir = Join-Path $FwDir $targetFw
        if (-not (Test-Path $targetFwDir)) { throw "Firmware non trouve dans le cache: $targetFwDir" }
        $ebus = Join-Path $targetFwDir "ewonfwr.ebus"
        $ebu  = Join-Path $targetFwDir "ewonfwr.ebu"
        if ($currentFw -eq "14.x" -and (Test-Path $ebu)) {
            $filesToCopy += @($ebus,$ebu)
            $firmwareNote = "Migration 14.x -> $targetFw : ewonfwr.ebus et ewonfwr.ebu necessaires"
        } else {
            $filesToCopy += $ebus
            $firmwareNote = "Mise a jour $currentFw -> $targetFw : ewonfwr.ebus necessaire"
        }
    } else {
        $firmwareNote = "Configuration uniquement (pas de MAJ firmware)"
    }

    # Copy configs/firmware to SD
    Write-Host ""; Write-Host ("=== Copie des fichiers vers {0} ===" -f $sdDrive) -ForegroundColor Green
    Write-Host $firmwareNote -ForegroundColor Yellow
    Write-Host ""

    $missing = @()
    foreach($src in $filesToCopy){
        $leaf = Split-Path $src -Leaf
        $dest = Join-Path $sdDrive $leaf
        if(Test-Path $src){
            Copy-Item -Path $src -Destination $dest -Force
            Write-Host (" + {0}" -f $leaf) -ForegroundColor DarkGreen
            Log ("Copy: {0} -> {1}" -f $src, $dest)
        } else {
            Write-Host (" ! Fichier manquant: {0}" -f $src) -ForegroundColor Red
            $missing += $src
        }
    }

    # ---- T2M written ONLY on SD (not in cache), modes 1 & 2 ----
    if ($mode -ne "3") {
        Write-Host ""
        Write-Host "Creation du T2M.txt directement sur la SD..." -ForegroundColor Cyan
        [void](Write-T2MDirect -SdRoot $sdDrive -T2MKey $T2M.Key -T2MNote $T2M.Note)
    }

    # Verify
    Write-Host ""; Write-Host "=== Verification des fichiers ===" -ForegroundColor Yellow
    $expected = @("backup.tar")
    if ($mode -ne "3") { $expected += "T2M.txt" }
    if (-not $skipFirmwareUpdate -and $targetFw) {
        $targetFwDir = Join-Path $FwDir $targetFw
        if ($currentFw -eq "14.x" -and (Test-Path (Join-Path $targetFwDir "ewonfwr.ebu"))) {
            $expected += @("ewonfwr.ebus", "ewonfwr.ebu")
        } else { $expected += "ewonfwr.ebus" }
    }
    $allOk = $true
    foreach ($f in $expected) {
        $p = Join-Path $sdDrive $f
        if (Test-Path $p) { Write-Host (" [OK] {0}" -f $f) -ForegroundColor Green }
        else { Write-Host (" [MANQUANT] {0}" -f $f) -ForegroundColor Red; $allOk = $false }
    }
    if (-not $allOk) { throw "Fichiers manquants sur la SD." }

    # Procedure detaillee (blocs d'origine en ASCII)
    $procPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "Procedure_Ewon.txt"
    if ($skipFirmwareUpdate) {
$proc = @'
PROCEDURE DETAILLEE APRES PREPARATION DE LA CARTE SD
--------------------------------------------------
CONFIGURATION SANS MISE A JOUR FIRMWARE

ETAPE 1 : PREPARATION
1. Dans Windows : faites un clic droit sur le lecteur SD et selectionnez "Ejecter"
2. Attendez que Windows confirme que vous pouvez retirer la carte en toute securite
3. Retirez physiquement la carte SD de votre ordinateur

ETAPE 2 : INSERTION DE LA CARTE (CONFIGURATION UNIQUEMENT)
1. Assurez-vous que l Ewon Flexy est SOUS TENSION et que la LED USR clignote en VERT
2. Inserez la carte SD dans l emplacement prevu sur l Ewon
3. ATTENDEZ que la LED USR devienne VERT FIXE (cette etape peut prendre quelques minutes)
4. Lorsque la LED est VERT FIXE, retirez la carte SD
5. La configuration est terminee lorsque la LED USR revient a un clignotement VERT regulier

ETAPE 3 : DEMANDE D ACCES A DISTANCE
Transmettez aux administrateurs/configurateurs les informations suivantes :
- Numero de serie de l Ewon
- Information carte SIM
- Identifiant IFS du site client
- Nom souhaite pour l Ewon

CONCLUSION
Votre Ewon Flexy est maintenant configure.
'@
    } else {
$proc = @'
PROCEDURE DETAILLEE APRES PREPARATION DE LA CARTE SD
--------------------------------------------------

ETAPE 1 : PREPARATION
1. Dans Windows : faites un clic droit sur le lecteur SD et selectionnez "Ejecter"
2. Attendez que Windows confirme que vous pouvez retirer la carte en toute securite
3. Retirez physiquement la carte SD de votre ordinateur

ETAPE 2 : PREMIERE INSERTION (MISE A JOUR DU FIRMWARE)
1. Assurez-vous que l Ewon Flexy est HORS TENSION
2. Inserez la carte SD dans l emplacement prevu sur l Ewon
3. Mettez l Ewon sous tension
4. ATTENDEZ que la LED USR devienne VERT FIXE (cette etape peut prendre plusieurs minutes)
5. Lorsque la LED est VERT FIXE, retirez la carte SD

ETAPE 3 : DEUXIEME INSERTION (CONFIGURATION)
1. ATTENDEZ que la LED USR clignote en VERT (alternance 500ms allumee/500ms eteinte)
2. Une fois que la LED clignote, reinserez la carte SD
3. ATTENDEZ a nouveau que la LED USR devienne VERT FIXE
4. Lorsque la LED est VERT FIXE, retirez definitivement la carte SD
5. La configuration est terminee lorsque la LED USR revient a un clignotement VERT regulier

ETAPE 4 : DEMANDE D ACCES A DISTANCE
Transmettez aux administrateurs/configurateurs les informations suivantes :
- Numero de serie de l Ewon
- Information carte SIM
- Identifiant IFS du site client
- Nom souhaite pour l Ewon

CONCLUSION
Votre Ewon Flexy est maintenant configure et a jour.
'@
    }
    $proc | Out-File -FilePath $procPath -Encoding ASCII
    try { Start-Process notepad.exe $procPath | Out-Null } catch {}

    # End
    Write-Host ""
    Write-Host "=== PREPARATION TERMINEE AVEC SUCCES ===" -ForegroundColor Green
    Write-Host ("MODE: {0}" -f ($(if($skipFirmwareUpdate){"Configuration uniquement"}else{"MAJ firmware + Configuration"}))) -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Lisez la procedure dans Notepad et ejectez proprement la carte SD." -ForegroundColor Yellow
    Pause-End
}
catch {
    Write-Host ("`n[ERREUR] {0}" -f $_.Exception.Message) -ForegroundColor Red
    Write-Host "`nDetails :" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Pause-End
}
