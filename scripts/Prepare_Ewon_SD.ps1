# PowerShell Script: Prepare Ewon Flexy SD card with online sources
# Version: 2.1.0
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
$GitHubRepo = "JohannPx/ewon-config-tool"
$GitHubBranch = "main"
$LocalCacheDir = Join-Path $env:APPDATA "EwonFlexConfig"

function Log { param([string]$msg) $ts = (Get-Date).ToString('s'); Write-Host ("$ts | $msg") }

# ============================================================================
# FONCTIONS POUR TELECHARGEMENT DES SOURCES
# ============================================================================

# Fonction pour télécharger le manifest
function Get-Manifest {
    $manifestUrl = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/manifest.json"
    try {
        Write-Host "Recuperation du catalogue des firmwares..." -ForegroundColor Gray
        $manifest = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing
        return $manifest
    }
    catch {
        Write-Host "Impossible de recuperer le catalogue. Verification du cache local..." -ForegroundColor Yellow
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
        [string]$Model,
        [bool]$HasEbu
    )
    
    # Les firmwares sont communs à tous les modèles
    # Format: er-15-0s2-arm-ma.ebus et er-15-0s2-arm-ma.ebu
    $versionForUrl = $Version -replace '\.', '-'  # 15.0s2 -> 15-0s2
    $baseUrl = "https://hmsnetworks.blob.core.windows.net/nlw/docs/default-source/products/ewon/monitored/firmware/source"
    
    # Chemins locaux - Créer le dossier avec le nom du modèle pour compatibilité
    $localFwDir = Join-Path $LocalCacheDir "Firmware" $Version "Flexy $Model"
    
    # Vérifier si déjà téléchargé
    $ebusPath = Join-Path $localFwDir "ewonfwr.ebus"
    if (Test-Path $ebusPath) {
        Write-Host "  Firmware $Version pour Flexy $Model deja en cache" -ForegroundColor Gray
        return $true
    }
    
    Write-Host "  Telechargement firmware $Version pour Flexy $Model..." -ForegroundColor Gray
    
    try {
        # Créer le dossier
        if (-not (Test-Path $localFwDir)) {
            New-Item -ItemType Directory -Path $localFwDir -Force | Out-Null
        }
        
        # Télécharger le .ebus (toujours nécessaire)
        $ebusUrl = "$baseUrl/er-$versionForUrl-arm-ma.ebus"
        $ebusLocalPath = Join-Path $localFwDir "ewonfwr.ebus"
        
        Write-Host "    Telechargement .ebus..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $ebusUrl -OutFile $ebusLocalPath -UseBasicParsing
        
        # Télécharger le .ebu si nécessaire (pour migration 14.x -> 15.0.x)
        if ($HasEbu) {
            $ebuUrl = "$baseUrl/er-$versionForUrl-arm-ma.ebu"
            $ebuLocalPath = Join-Path $localFwDir "ewonfwr.ebu"
            
            Write-Host "    Telechargement .ebu (pour migration 14.x)..." -ForegroundColor Gray
            try {
                Invoke-WebRequest -Uri $ebuUrl -OutFile $ebuLocalPath -UseBasicParsing
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
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing
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
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing
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
        # Mode offline : scanner le dossier local
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
    Write-Host "  [2] Mode OFFLINE - Utiliser les sources locales sur la carte SD"
    Write-Host ""
    $mode = Read-Host "Choisissez 1 ou 2"
    
    $manifest = $null
    $SourceDir = ""
    
    if ($mode -eq "1") {
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
        
        Write-Host "Catalogue des firmwares recupere (version $($manifest.version))" -ForegroundColor Green
        
        # Télécharger les configurations de base
        Write-Host "`nTelechargement des configurations..." -ForegroundColor Cyan
        $configEthPath = Join-Path $LocalCacheDir "Configuration" "Internet par Ethernet" "backup.tar"
        $config4GPath = Join-Path $LocalCacheDir "Configuration" "Internet par modem 4G" "backup.tar"
        $t2mPath = Join-Path $LocalCacheDir "T2M Global Registration Key" "T2M.txt"
        
        Download-Configuration -Type "ethernet" -LocalPath $configEthPath
        Download-Configuration -Type "4g" -LocalPath $config4GPath
        Download-T2MKey -LocalPath $t2mPath
        
        $SourceDir = $LocalCacheDir
    }
    else {
        # MODE OFFLINE
        Write-Host "`n=== Mode OFFLINE selectionne ===" -ForegroundColor Yellow
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        $SourceDir = $ScriptDir
    }
    
    # Définir les chemins
    $RootDir = if ($mode -eq "1") { [Environment]::GetFolderPath('Desktop') } else { Split-Path -Parent $SourceDir }
    $CfgDir = Join-Path $SourceDir "Configuration"
    $FwDir = Join-Path $SourceDir "Firmware"
    $T2MDir = Join-Path $SourceDir "T2M Global Registration Key"
    $CfgEthDir = Join-Path $CfgDir "Internet par Ethernet"
    $Cfg4GDir = Join-Path $CfgDir "Internet par modem 4G"
    
    # Vérifications de base (mode offline uniquement)
    if ($mode -ne "1") {
        foreach($p in @($SourceDir,$CfgEthDir,$Cfg4GDir,$FwDir,$T2MDir)){
            if(-not (Test-Path $p)){ 
                Log "Missing folder: $p"
                throw "Missing folder: $p" 
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
    
    # Configuration de l'Ewon
    Write-Host "=== Configuration de l'Ewon ===" -ForegroundColor Magenta
    $model = Select-FromList -Title "Modele Ewon" -Options @("202","203","205")
    
    # Liste des firmwares actuels possibles
    $currentFwOptions = @("14.x")
    foreach ($fw in $availableFirmwares | Where-Object { $_.Major -eq 15 }) {
        $currentFwOptions += "$($fw.Major).x"
    }
    $currentFwOptions = $currentFwOptions | Select-Object -Unique
    
    # Message d'aide pour le firmware actuel
    Write-Host ""
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
        $hasEbu = if ($fwInfo.hasEbu) { $fwInfo.hasEbu } else { $false }
        
        # Note: Les firmwares sont maintenant communs à tous les modèles
        $success = Download-HMSFirmware -Version $targetFw -Model $model -HasEbu $hasEbu
        
        if (-not $success) {
            throw "Impossible de telecharger le firmware"
        }
    }
    
    $profile = Select-FromList -Title "Internet" -Options @("Modem 4G","Ethernet")
    
    # Log des sélections
    if ($skipFirmwareUpdate) {
        Log "Selections -> model=$model currentFw=$currentFw targetFw=NONE Internet=$profile"
    } else {
        Log "Selections -> model=$model currentFw=$currentFw targetFw=$targetFw Internet=$profile"
    }
    
    # Sélection du lecteur SD
    $defaultDrive = $RootDir
    Write-Host "`nLettre de lecteur SD (ex: E:) [defaut: $defaultDrive]" -ForegroundColor Cyan
    $sdDrive = Read-Host
    if([string]::IsNullOrWhiteSpace($sdDrive)){ $sdDrive = $defaultDrive }
    if(-not (Test-Path $sdDrive)){ 
        Log "Drive not found: $sdDrive"
        throw "Drive not found" 
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
        $targetFwDir = Join-Path $FwDir $targetFw
        $fwModelDirName = switch ($model) { 
            "202" {"Flexy 202"}
            "203" {"Flexy 203"}
            "205" {"Flexy 205"} 
        }
        $fwModelDir = Join-Path $targetFwDir $fwModelDirName
        
        Log "Looking for model firmware in: $fwModelDir"
        
        if(-not (Test-Path $fwModelDir)){ 
            Log "Missing firmware model folder: $fwModelDir"
            throw "Missing firmware files for model $model in version $targetFw" 
        }
        
        $ebus = Join-Path $fwModelDir "ewonfwr.ebus"
        $ebu = Join-Path $fwModelDir "ewonfwr.ebu"
        
        if($currentFw -eq "14.x"){ 
            if (Test-Path $ebu) {
                $filesToCopy += @($ebus,$ebu)
                $firmwareNote = "Migration de 14.x vers ${targetFw}: ewonfwr.ebus ET ewonfwr.ebu sont necessaires"
            } else {
                $filesToCopy += $ebus
                $firmwareNote = "Migration de 14.x vers ${targetFw}: seul ewonfwr.ebus est copie (pas de .ebu disponible)"
            }
        } else { 
            $filesToCopy += $ebus 
            $firmwareNote = "Mise a jour de $currentFw vers ${targetFw}: seul ewonfwr.ebus est necessaire"
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
        if($currentFw -eq "14.x"){
            $targetFwDir = Join-Path $FwDir $targetFw
            $fwModelDirName = switch ($model) { 
                "202" {"Flexy 202"}
                "203" {"Flexy 203"}
                "205" {"Flexy 205"} 
            }
            $fwModelDir = Join-Path $targetFwDir $fwModelDirName
            $ebu = Join-Path $fwModelDir "ewonfwr.ebu"
            
            if (Test-Path $ebu) {
                $expectedFiles += @("ewonfwr.ebus", "ewonfwr.ebu")
            } else {
                $expectedFiles += @("ewonfwr.ebus")
            }
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
- Numero de serie de l Ewon (visible sur l etiquette de l appareil)
- Information carte SIM (numero MODEM Clauger)
- Identifiant IFS du site client
- Nom souhaite pour l Ewon
- Plan des equipements a connecter

CONCLUSION
Votre Ewon Flexy est maintenant configure et pret pour la telemaintenance.
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
- Numero de serie de l Ewon (visible sur l etiquette de l appareil)
- Information carte SIM (numero MODEM Clauger)
- Identifiant IFS du site client
- Nom souhaite pour l Ewon
- Plan des equipements a connecter

CONCLUSION
Votre Ewon Flexy est maintenant configure et pret pour la telemaintenance.
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
