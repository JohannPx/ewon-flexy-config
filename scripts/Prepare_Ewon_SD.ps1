# PowerShell Script: Prepare Ewon Flexy SD card with online sources
# Version: 3.0.0
# Author: JPR
# Date: 2025-01-10

# Capture toutes les erreurs
trap {
    Write-Host "`n===== ERREUR CRITIQUE =====" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Type: $($_.Exception.GetType().FullName)" -ForegroundColor Yellow
    Write-Host "Script: $($_.InvocationInfo.ScriptName)" -ForegroundColor Yellow
    Write-Host "Ligne: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    Write-Host "`nAppuyez sur Entree pour fermer..." -ForegroundColor White
    Read-Host
    exit 1
}

$ErrorActionPreference = 'Stop'

# Configuration GitHub (A MODIFIER avec votre repository)
$GitHubRepo = "votre-username/nom-du-repo"
$GitHubBranch = "main"
$GitHubToken = "ghp_VotreTokenGitHub"
$LocalCacheDir = Join-Path $env:APPDATA "EwonFlexConfig"

function Log { param([string]$msg) $ts = (Get-Date).ToString('s'); Write-Host ("$ts | $msg") }

# ============================================================================
# FONCTIONS POUR TELECHARGEMENT DES SOURCES
# ============================================================================
function Show-WebError {
    param([Parameter(Mandatory=$true)]$Err)

    try {
        $ex   = $Err.Exception
        $resp = $ex.Response
        Write-Host "---- DIAGNOSTIC HTTP ----" -ForegroundColor Yellow
        if ($resp) {
            # HttpWebResponse
            $statusCode = [int]$resp.StatusCode
            $statusDesc = $resp.StatusDescription
            $finalUri   = $resp.ResponseUri
            Write-Host ("StatusCode: {0}" -f $statusCode)
            Write-Host ("StatusDesc:  {0}" -f $statusDesc)
            if ($finalUri) { Write-Host ("ResponseUri: {0}" -f $finalUri) }
            # (Optionnel) lire un bout du corps pour indices
            try {
                $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
                $body = $sr.ReadToEnd()
                if ($body) {
                    $snippet = $body.Substring(0, [Math]::Min(500, $body.Length))
                    Write-Host "Body (snippet):" -ForegroundColor DarkYellow
                    Write-Host $snippet
                }
            } catch {}
        } else {
            Write-Host "Pas d'objet Response sur l'exception." -ForegroundColor Yellow
        }
        Write-Host "-------------------------" -ForegroundColor Yellow
    } catch { }
}

# Fonction pour télécharger le manifest
function Get-Manifest {
    # NOTE : raw.githubusercontent.com ignore l’Authorization sur repo privé → 404 masqué
    $manifestUrl = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/manifest.json"
    $apiUrl      = "https://api.github.com/repos/$GitHubRepo/contents/manifest.json?ref=$GitHubBranch"

    try {
        Write-Host "Recuperation du catalogue des firmwares..." -ForegroundColor Gray
        # Write-Host "URL (RAW): $manifestUrl"
        # Write-Host "URL (API): $apiUrl"
        # Write-Host ("Auth header present: {0}" -f ([bool]$GitHubToken))

        # Garde ton implémentation actuelle mais LOG l’URL utilisée :
        # Ici je laisse ton appel tel quel (RAW) pour rester minimaliste.
        $headers = @{
            Authorization = "token $GitHubToken"
            Accept        = "application/vnd.github.v3.raw"
        }
        # Important : -Verbose te montre le VERBOSE: GET https://... dans la console
        # Invoke-RestMethod -Uri $manifestUrl -Headers $headers -UseBasicParsing -Verbose
        Invoke-RestMethod -Uri $manifestUrl -Headers $headers -UseBasicParsing

        # Si tu préfères assurer l’auth sur repo privé, remplace la ligne ci-dessus par :
        # Invoke-RestMethod -Uri $apiUrl -Headers $headers -UseBasicParsing -Verbose

    } catch {
        Write-Host "Impossible de recuperer le catalogue (en ligne)." -ForegroundColor Yellow
        # Show-WebError -Err $_
        Write-Host "Verification du cache local..." -ForegroundColor Yellow

        $cachedManifest = Join-Path $LocalCacheDir "manifest.json"
        if (Test-Path $cachedManifest) {
            Write-Host "Utilisation du cache local" -ForegroundColor Yellow
            return Get-Content $cachedManifest | ConvertFrom-Json
        }
        return $null
    }
}


# Fonction pour télécharger un firmware HMS
function Download-HMSFirmware {
    param(
        [string]$Version,
        [bool]$HasEbu
    )
    
    # Format: er-15-0s2-arm-ma_secure.ebus et er-15-0s2-arm-ma.ebu
    $versionForUrl = $Version -replace '\.', '-'  # 15.0s2 -> 15-0s2
    $baseUrl = "https://hmsnetworks.blob.core.windows.net/nlw/docs/default-source/products/ewon/monitored/firmware/source"
    
    # Structure simplifiée : firmware/version/fichiers
    $fwBaseDir = Join-Path $LocalCacheDir "firmware"
    $versionDir = Join-Path $fwBaseDir $Version
    
    # Vérifier si déjà téléchargé
    $ebusPath = Join-Path $versionDir "ewonfwr.ebus"
    if (Test-Path $ebusPath) {
        Write-Host "  Firmware $Version deja en cache" -ForegroundColor Gray
        return $true
    }
    
    Write-Host "  Telechargement firmware $Version..." -ForegroundColor Gray
    
    try {
        # Créer le dossier
        if (-not (Test-Path $versionDir)) {
            New-Item -ItemType Directory -Path $versionDir -Force | Out-Null
        }
        
        # Télécharger le .ebus (toujours nécessaire) - AVEC _secure
        $ebusUrl = "$baseUrl/er-$versionForUrl-arm-ma_secure.ebus"
        
        Write-Host "    Telechargement .ebus..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $ebusUrl -OutFile $ebusPath -UseBasicParsing
        
        # Télécharger le .ebu si nécessaire (pour migration 14.x -> 15.0.x) - SANS _secure
        if ($HasEbu) {
            $ebuUrl = "$baseUrl/er-$versionForUrl-arm-ma.ebu"
            $ebuPath = Join-Path $versionDir "ewonfwr.ebu"
            
            Write-Host "    Telechargement .ebu (pour migration 14.x)..." -ForegroundColor Gray
            try {
                Invoke-WebRequest -Uri $ebuUrl -OutFile $ebuPath -UseBasicParsing
            }
            catch {
                Write-Host "      Note: Fichier .ebu non disponible" -ForegroundColor Yellow
            }
        }
        
        Write-Host "    [OK] Firmware telecharge" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "    [ERREUR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour télécharger les configurations
function Download-Configuration {
    param(
        [string]$Type,
        [string]$LocalPath
    )
    
    $url = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/configurations/$Type/backup.tar"
    
    try {
        $dir = Split-Path $LocalPath
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        Write-Host "  Telechargement configuration $Type..." -ForegroundColor Gray
        
        # Headers pour repo privé
        $headers = @{
            Authorization = "token $GitHubToken"
            Accept = "application/vnd.github.v3.raw"
        }
        
        Invoke-WebRequest -Uri $url -Headers $headers -OutFile $LocalPath -UseBasicParsing
        Write-Host "    [OK]" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "    [ERREUR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour télécharger la clé T2M
function Download-T2MKey {
    param([string]$LocalPath)
    
    $url = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/t2m/T2M.txt"
    
    try {
        $dir = Split-Path $LocalPath
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        Write-Host "  Telechargement cle T2M..." -ForegroundColor Gray
        
        # Headers pour repo privé
        $headers = @{
            Authorization = "token $GitHubToken"
            Accept = "application/vnd.github.v3.raw"
        }
        
        Invoke-WebRequest -Uri $url -Headers $headers -OutFile $LocalPath -UseBasicParsing
        Write-Host "    [OK]" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "    [ERREUR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# FONCTIONS ORIGINALES DU SCRIPT
# ============================================================================

# Fonction pour parser les versions de firmware
function Parse-FirmwareVersion {
    param([string]$version)
    
    if ($version -match '^(\d+)\.(\d+)s(\d+)$') {
        return [PSCustomObject]@{
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Service = [int]$Matches[3]
            Full = $version
        }
    }
    return $null
}

# Fonction pour obtenir les firmwares disponibles
function Get-AvailableFirmwares {
    param(
        [string]$firmwarePath,
        $manifest
    )
    
    $firmwares = @()
    
    if ($manifest) {
        # Mode online : utiliser le manifest
        foreach ($fw in $manifest.firmwares) {
            $fwVersion = Parse-FirmwareVersion $fw.version
            if ($fwVersion) {
                $firmwares += $fwVersion
            }
        }
    }
    elseif (Test-Path $firmwarePath) {
        # Mode cache : scanner le dossier local
        Get-ChildItem -Path $firmwarePath -Directory | ForEach-Object {
            $fwVersion = Parse-FirmwareVersion $_.Name
            if ($fwVersion) {
                $firmwares += $fwVersion
            }
        }
    }
    
    return $firmwares | Sort-Object -Property Major, Minor, Service
}

# Fonction pour déterminer les firmwares compatibles
function Get-CompatibleFirmwares {
    param(
        [string]$currentFw,
        [array]$availableFirmwares
    )
    
    $compatibleFw = @()
    $currentMajor = if ($currentFw -eq "14.x") { 14 } else { 15 }
    
    if ($currentMajor -eq 14) {
        # Si firmware actuel est 14.x, on ne peut installer que les versions pivot (15.0.x)
        $compatibleFw = $availableFirmwares | Where-Object { 
            $_.Major -eq 15 -and $_.Minor -eq 0 
        }
        
        if ($compatibleFw.Count -eq 0) {
            Write-Host "ATTENTION: Aucun firmware pivot (15.0.x) disponible pour la migration depuis 14.x" -ForegroundColor Red
        }
    }
    else {
        # Si firmware actuel est 15.x, on peut installer n'importe quel firmware >= 15.x
        $compatibleFw = $availableFirmwares | Where-Object { 
            $_.Major -ge 15
        }
    }
    
    return $compatibleFw
}

# Fonction de menu
function Select-FromList { 
    param(
        [string]$Title,
        [string[]]$Options,
        [switch]$AllowNone
    )
    
    Write-Host ""; Write-Host $Title -ForegroundColor Cyan
    
    if ($Options.Count -eq 0) {
        if ($AllowNone) {
            Write-Host "  Aucune option disponible - pas de mise a jour necessaire" -ForegroundColor Yellow
            return $null
        } else {
            throw "Aucune option disponible"
        }
    }
    
    if ($AllowNone) {
        Write-Host "  [0] Pas de mise a jour firmware"
    }
    
    for($i=0;$i -lt $Options.Count;$i++){ 
        Write-Host ("  [{0}] {1}" -f ($i+1), $Options[$i]) 
    }
    
    do { 
        $maxChoice = $Options.Count
        if ($AllowNone) {
            $choice = Read-Host ("Choose 0-" + $maxChoice)
            if ($choice -eq "0") { return $null }
        } else {
            $choice = Read-Host ("Choose 1-" + $maxChoice)
        }
        
        if (-not ($choice -as [int]) -or ([int]$choice -lt 0 -and $AllowNone) -or ([int]$choice -lt 1 -and -not $AllowNone) -or [int]$choice -gt $maxChoice) {
            Write-Host "Choix invalide. Veuillez entrer un numero valide" -ForegroundColor Red
        }
    } while(-not ($choice -as [int]) -or ([int]$choice -lt 0 -and $AllowNone) -or ([int]$choice -lt 1 -and -not $AllowNone) -or [int]$choice -gt $Options.Count)
    
    return $Options[[int]$choice-1]
}

# ============================================================================
# PROGRAMME PRINCIPAL
# ============================================================================

try {
    # Header
    $headerBorder = "=" * 70
    Write-Host $headerBorder -ForegroundColor DarkCyan
    Write-Host "                  PREPARATION CARTE SD EWON FLEXY" -ForegroundColor Cyan
    Write-Host $headerBorder -ForegroundColor DarkCyan
    Write-Host ""
    
    # Choix du mode
    Write-Host "=== Mode de fonctionnement ===" -ForegroundColor Cyan
    Write-Host "  [1] Mode ONLINE - Telecharger les dernieres sources (Internet requis)"
    Write-Host "  [2] Mode CACHE - Utiliser les sources deja telechargees"
    Write-Host "  [3] Mode PREPARATION - Telecharger TOUS les firmwares pour usage futur"
    Write-Host ""
    $mode = Read-Host "Choisissez 1, 2 ou 3"
    
    $manifest = $null
    $SourceDir = $LocalCacheDir  # Toujours utiliser le cache
    
    if ($mode -eq "3") {
        # MODE PREPARATION - Télécharger tout et quitter
        Write-Host "`n=== Mode PREPARATION ===" -ForegroundColor Magenta
        Write-Host "Ce mode va telecharger TOUS les firmwares pour un usage ulterieur" -ForegroundColor Yellow
        
        $confirm = Read-Host "Continuer ? (O/N)"
        if ($confirm -ne "O" -and $confirm -ne "o") {
            Write-Host "Annule" -ForegroundColor Red
            exit
        }
        
        # Obtenir le manifest
        $manifest = Get-Manifest
        if (-not $manifest) {
            throw "Impossible de recuperer le catalogue en ligne"
        }
        
        # Créer le cache et sauvegarder le manifest
        if (-not (Test-Path $LocalCacheDir)) {
            New-Item -ItemType Directory -Path $LocalCacheDir -Force | Out-Null
        }
        $manifestCache = Join-Path $LocalCacheDir "manifest.json"
        $manifest | ConvertTo-Json -Depth 10 | Out-File $manifestCache -Encoding UTF8
        
        # Télécharger les configurations
        Write-Host "`nTelechargement des configurations..." -ForegroundColor Cyan
        Download-Configuration -Type "ethernet" -LocalPath "$LocalCacheDir\configurations\ethernet\backup.tar"
        Download-Configuration -Type "4g" -LocalPath "$LocalCacheDir\configurations\4g\backup.tar"
        Download-T2MKey -LocalPath "$LocalCacheDir\t2m\T2M.txt"
        
        # Télécharger TOUS les firmwares
        Write-Host "`nTelechargement de tous les firmwares..." -ForegroundColor Cyan
        foreach ($fw in $manifest.firmwares) {
            $hasEbu = [bool]$fw.hasEbu
            Download-HMSFirmware -Version $fw.version -HasEbu $hasEbu
        }
        
        Write-Host "`n=== PREPARATION TERMINEE ===" -ForegroundColor Green
        Write-Host "Cache cree dans: $LocalCacheDir" -ForegroundColor Green
        Write-Host "Vous pouvez maintenant utiliser le Mode CACHE sans Internet" -ForegroundColor Green
        Read-Host "`nAppuyez sur Entree pour fermer"
        exit
    }
    elseif ($mode -eq "1") {
        # MODE ONLINE
        Write-Host "`n=== Mode ONLINE selectionne ===" -ForegroundColor Green
        
        # Obtenir le manifest
        $manifest = Get-Manifest
        if (-not $manifest) {
            throw "Impossible de continuer sans acces au catalogue en ligne"
        }
        
        # Sauvegarder le manifest en cache
        if (-not (Test-Path $LocalCacheDir)) {
            New-Item -ItemType Directory -Path $LocalCacheDir -Force | Out-Null
        }
        $manifestCache = Join-Path $LocalCacheDir "manifest.json"
        $manifest | ConvertTo-Json -Depth 10 | Out-File $manifestCache -Encoding UTF8
        
        # Télécharger les configurations
        Write-Host "`nTelechargement des configurations..." -ForegroundColor Cyan
        Download-Configuration -Type "ethernet" -LocalPath "$LocalCacheDir\configurations\ethernet\backup.tar"
        Download-Configuration -Type "4g" -LocalPath "$LocalCacheDir\configurations\4g\backup.tar"
        Download-T2MKey -LocalPath "$LocalCacheDir\t2m\T2M.txt"
    }
    elseif ($mode -eq "2") {
        # MODE CACHE
        Write-Host "`n=== Mode CACHE selectionne ===" -ForegroundColor Yellow
        
        if (-not (Test-Path $LocalCacheDir)) {
            Write-Host "ERREUR: Aucun cache trouve dans $LocalCacheDir" -ForegroundColor Red
            Write-Host "Utilisez d'abord le mode ONLINE ou PREPARATION" -ForegroundColor Red
            throw "Cache non disponible"
        }
        
        # Charger le manifest depuis le cache
        $manifestCache = Join-Path $LocalCacheDir "manifest.json"
        if (Test-Path $manifestCache) {
            $manifest = Get-Content $manifestCache | ConvertFrom-Json
            Write-Host "Utilisation du cache local" -ForegroundColor Yellow
        } else {
            throw "Manifest non trouve dans le cache"
        }
    }
    else {
        throw "Choix invalide"
    }
    
    # Définir les chemins avec la nouvelle structure
    $CfgDir = Join-Path $SourceDir "configurations"
    $FwDir = Join-Path $SourceDir "firmware"
    $T2MDir = Join-Path $SourceDir "t2m"
    $CfgEthDir = Join-Path $CfgDir "ethernet"
    $Cfg4GDir = Join-Path $CfgDir "4g"
    
    # Vérifications pour le mode cache
    if ($mode -eq "2") {
        foreach($p in @($CfgEthDir,$Cfg4GDir,$FwDir,$T2MDir)){
            if(-not (Test-Path $p)){ 
                Write-Host "Cache incomplet. Dossier manquant: $p" -ForegroundColor Red
                throw "Utilisez le mode PREPARATION pour creer un cache complet"
            }
        }
    }
    
    # Afficher les prérequis
    Write-Host ""
    Write-Host "PRE-REQUIS:" -ForegroundColor Yellow
    Write-Host "- Ewon Flexy (firmware >= 14)" -ForegroundColor White
    Write-Host "- Carte SD formatee en FAT32, capacite maximale 128 Go" -ForegroundColor White
    Write-Host "- Acces Internet par reseau Ethernet (DHCP) ou 4G (APN Orange)" -ForegroundColor White
    Write-Host ""
    Write-Host $headerBorder -ForegroundColor DarkCyan
    Write-Host ""
    
    # Détecter les firmwares disponibles
    $availableFirmwares = Get-AvailableFirmwares -firmwarePath $FwDir -manifest $manifest
    
    if ($availableFirmwares.Count -eq 0) {
        Log "Aucun firmware disponible"
        throw "Aucun firmware trouve. Veuillez verifier votre configuration."
    }
    
    Write-Host "=== Firmwares disponibles ===" -ForegroundColor Cyan
    foreach ($fw in $availableFirmwares) {
        Write-Host "  - $($fw.Full)" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Configuration simplifiée - PLUS DE CHOIX DE MODELE
    Write-Host "=== Configuration de l'Ewon ===" -ForegroundColor Magenta
    Write-Host "Note: Les firmwares sont communs a tous les modeles Flexy" -ForegroundColor Gray
    Write-Host ""
    
    # Liste des firmwares actuels possibles
    $currentFwOptions = @("14.x")
    foreach ($fw in $availableFirmwares | Where-Object { $_.Major -eq 15 }) {
        $currentFwOptions += "$($fw.Major).x"
    }
    $currentFwOptions = $currentFwOptions | Select-Object -Unique
    
    # Message d'aide pour le firmware actuel
    Write-Host "=== AIDE POUR DETERMINER LE FIRMWARE ACTUEL ===" -ForegroundColor Yellow
    Write-Host "Si vous ne connaissez pas la version du firmware actuel :" -ForegroundColor White
    Write-Host "  1. Mettez l'Ewon sous tension SANS carte SD" -ForegroundColor Gray
    Write-Host "  2. Connectez-vous avec l'utilitaire eBuddy (disponible sur le site HMS)" -ForegroundColor Gray
    Write-Host "  3. La version du firmware s'affiche dans les informations de l'appareil" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Note (janvier 2025): Tous les Ewons neufs ou anciens sont generalement en firmware 14.x" -ForegroundColor Cyan
    Write-Host "                     Choisissez 14.x si vous n'etes pas certain" -ForegroundColor Cyan
    
    $currentFw = Select-FromList -Title "Firmware ACTUEL de l'Ewon" -Options $currentFwOptions
    
    # Déterminer les firmwares compatibles
    $compatibleFirmwares = Get-CompatibleFirmwares -currentFw $currentFw -availableFirmwares $availableFirmwares
    
    # Gestion de la sélection du firmware cible
    $targetFw = $null
    $skipFirmwareUpdate = $false
    
    if ($compatibleFirmwares.Count -eq 0) {
        Write-Host "`nAucun firmware compatible disponible pour la mise a jour" -ForegroundColor Yellow
        if ($currentFw -eq "14.x") {
            Write-Host "Pour migrer de 14.x vers 15.x, un firmware pivot (15.0.x) est necessaire" -ForegroundColor Yellow
        } else {
            Write-Host "Aucun firmware superieur disponible" -ForegroundColor Yellow
        }
        $skipFirmwareUpdate = $true
    }
    elseif ($compatibleFirmwares.Count -eq 1) {
        $targetFw = $compatibleFirmwares[0].Full
        Write-Host "`nFirmware cible selectionne automatiquement: $targetFw" -ForegroundColor Green
    }
    else {
        $fwOptions = $compatibleFirmwares | ForEach-Object { $_.Full }
        if ($currentFw -eq "14.x") {
            Write-Host "`nNote: Pour migrer de 14.x, seuls les firmwares pivot (15.0.x) sont disponibles" -ForegroundColor Yellow
        }
        $selectedFw = Select-FromList -Title "Firmware cible" -Options $fwOptions -AllowNone
        
        if ($selectedFw) {
            $targetFw = $selectedFw
        } else {
            $skipFirmwareUpdate = $true
            Write-Host "`nPas de mise a jour firmware selectionnee" -ForegroundColor Yellow
        }
    }
    
    # Télécharger le firmware si mode online et firmware sélectionné
    if ($mode -eq "1" -and -not $skipFirmwareUpdate) {
        Write-Host "`nPreparation du firmware..." -ForegroundColor Cyan
        $fwInfo = $manifest.firmwares | Where-Object { $_.version -eq $targetFw }
        $hasEbu = [bool]$fwInfo.hasEbu
        
        $success = Download-HMSFirmware -Version $targetFw -HasEbu $hasEbu
        
        if (-not $success) {
            throw "Impossible de telecharger le firmware"
        }
    }
    
    $profile = Select-FromList -Title "Internet" -Options @("Modem 4G","Ethernet")
    
    # Log des sélections
    if ($skipFirmwareUpdate) {
        Log "Selections -> currentFw=$currentFw targetFw=NONE Internet=$profile"
    } else {
        Log "Selections -> currentFw=$currentFw targetFw=$targetFw Internet=$profile"
    }
    
    # Sélection du lecteur SD
    Write-Host "`n=== Selection du lecteur de carte SD ===" -ForegroundColor Cyan
    Write-Host "Inserez votre carte SD et entrez sa lettre de lecteur" -ForegroundColor Yellow
    Write-Host "Exemples: E: ou F: ou G:" -ForegroundColor Gray
    $sdDrive = Read-Host "Lettre du lecteur SD"
    
    # Formater correctement
    if ($sdDrive -match '^[A-Za-z]$') {
        $sdDrive = "${sdDrive}:\"
    }
    elseif ($sdDrive -match '^[A-Za-z]:$') {
        $sdDrive = "${sdDrive}\"
    }
    elseif ($sdDrive -notmatch '^[A-Za-z]:\\') {
        Write-Host "Format invalide. Utilisez une lettre de lecteur (ex: E:)" -ForegroundColor Red
        throw "Format de lecteur invalide"
    }
    
    if(-not (Test-Path $sdDrive)){ 
        Log "Drive not found: $sdDrive"
        throw "Lecteur $sdDrive non trouve. Verifiez que la carte SD est bien inseree." 
    }
    
    Log "Drive=$sdDrive"
    
    # Fichiers à copier
    $filesToCopy = @()
    if($profile -eq "Ethernet"){ 
        $filesToCopy += Join-Path $CfgEthDir "backup.tar" 
    } else { 
        $filesToCopy += Join-Path $Cfg4GDir "backup.tar" 
    }
    $filesToCopy += Join-Path $T2MDir "T2M.txt"
    
    # Gestion des fichiers firmware
    $firmwareNote = ""
    
    if (-not $skipFirmwareUpdate) {
        # Structure simplifiée : firmware/version/fichiers
        $targetFwDir = Join-Path $FwDir $targetFw
        
        if (-not (Test-Path $targetFwDir)) {
            Log "Missing firmware folder: $targetFwDir"
            throw "Firmware non trouve pour version $targetFw"
        }
        
        Log "Looking for firmware in: $targetFwDir"
        
        $ebus = Join-Path $targetFwDir "ewonfwr.ebus"
        $ebu = Join-Path $targetFwDir "ewonfwr.ebu"
        
        if($currentFw -eq "14.x"){ 
            if (Test-Path $ebu) {
                $filesToCopy += @($ebus,$ebu)
                $firmwareNote = "Migration de 14.x vers ${targetFw}: ewonfwr.ebus ET ewonfwr.ebu necessaires"
            } else {
                $filesToCopy += $ebus
                $firmwareNote = "Migration de 14.x vers ${targetFw}: seul ewonfwr.ebus copie"
            }
        } else { 
            $filesToCopy += $ebus 
            $firmwareNote = "Mise a jour de $currentFw vers ${targetFw}: seul ewonfwr.ebus necessaire"
        }
    } else {
        $firmwareNote = "Pas de mise a jour firmware - configuration uniquement"
    }
    
    # Copie des fichiers
    Write-Host ""; Write-Host "=== Copie des fichiers vers $sdDrive ===" -ForegroundColor Green
    Write-Host $firmwareNote -ForegroundColor Yellow
    Write-Host ""
    
    $missing = @()
    foreach($src in $filesToCopy){
        $leaf = Split-Path $src -Leaf
        $dest = Join-Path $sdDrive $leaf
        if(Test-Path $src){ 
            Copy-Item -Path $src -Destination $dest -Force
            Write-Host " + $leaf" -ForegroundColor DarkGreen
            Log ("Copy: $src -> $dest") 
        }
        else { 
            Write-Host " ! Fichier manquant: $src" -ForegroundColor Red
            Log ("Missing file: $src")
            $missing += $src 
        }
    }
    
    # Vérification des fichiers
    Write-Host ""; Write-Host "=== Verification des fichiers ===" -ForegroundColor Yellow
    $allFilesPresent = $true
    
    $expectedFiles = @("backup.tar", "T2M.txt")
    
    if (-not $skipFirmwareUpdate) {
        $targetFwDir = Join-Path $FwDir $targetFw
        if($currentFw -eq "14.x" -and (Test-Path (Join-Path $targetFwDir "ewonfwr.ebu"))) {
            $expectedFiles += @("ewonfwr.ebus", "ewonfwr.ebu")
        } else {
            $expectedFiles += @("ewonfwr.ebus")
        }
    }
    
    foreach ($file in $expectedFiles) {
        $filePath = Join-Path $sdDrive $file
        if (Test-Path $filePath) {
            Write-Host " [OK] $file" -ForegroundColor Green
        } else {
            Write-Host " [MANQUANT] $file" -ForegroundColor Red
            $allFilesPresent = $false
        }
    }
    
    if ($allFilesPresent) {
        Write-Host "`nTous les fichiers necessaires sont presents sur la carte SD." -ForegroundColor Green
    } else {
        Write-Host "`nATTENTION: Certains fichiers sont manquants!" -ForegroundColor Red
        throw "Files missing on SD card"
    }
    
    # Génération de la procédure
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
    Start-Process notepad.exe $procPath | Out-Null
    Log "Procedure file created: $procPath"
    
    # Conclusion
    Write-Host ""
    Write-Host "=== PREPARATION TERMINEE AVEC SUCCES ===" -ForegroundColor Green
    Write-Host ""
    
    if ($skipFirmwareUpdate) {
        Write-Host "MODE: Configuration uniquement (pas de mise a jour firmware)" -ForegroundColor Cyan
    } else {
        Write-Host "MODE: Mise a jour firmware ($currentFw -> $targetFw) + Configuration" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "IMPORTANT:" -ForegroundColor Yellow
    Write-Host "1. Lisez la procedure dans Notepad" -ForegroundColor Yellow
    Write-Host "2. Ejectez la carte SD avant de la retirer" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Un fichier 'Procedure_Ewon.txt' a ete cree sur votre Bureau" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Appuyez sur Entree pour fermer ce programme"
    
    Log "Script completed successfully"
}
catch {
    Write-Host "`nUne erreur est survenue:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nDetails de l'erreur:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    
    Log "Error: $_"
    Log "StackTrace: $($_.ScriptStackTrace)"
    
    Write-Host "`n" -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour fermer"
}