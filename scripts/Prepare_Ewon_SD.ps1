# Configuration GitHub
$GitHubRepo = "votre-username/ewon-config-tool"
$GitHubBranch = "main"
$LocalCacheDir = Join-Path $env:APPDATA "EwonFlexConfig"

# Fonction pour télécharger le manifest
function Get-Manifest {
    $manifestUrl = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/manifest.json"
    try {
        Write-Host "Recuperation du catalogue des firmwares..." -ForegroundColor Gray
        $manifest = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing
        return $manifest
    }
    catch {
        Write-Host "Impossible de recuperer le catalogue. Mode hors ligne." -ForegroundColor Yellow
        # Utiliser le manifest en cache s'il existe
        $cachedManifest = Join-Path $LocalCacheDir "manifest.json"
        if (Test-Path $cachedManifest) {
            return Get-Content $cachedManifest | ConvertFrom-Json
        }
        return $null
    }
}

# Fonction pour télécharger un firmware HMS
function Download-HMSFirmware {
    param(
        [string]$Version,    # ex: "15.0s1"
        [string]$ProductCode, # "21" ou "24"
        [string]$LocalPath
    )
    
    # Construire l'URL selon le pattern HMS
    $versionForUrl = $Version -replace '\.', '_' # 15.0s1 -> 15_0s1
    $filename = "er${versionForUrl}p${ProductCode}_ma.edf"
    $url = "https://hmsnetworks.blob.core.windows.net/nlw/docs/default-source/products/ewon/monitored/firmware/source/$filename"
    
    Write-Host "Telechargement firmware $Version (product code $ProductCode)..." -ForegroundColor Gray
    try {
        # Créer le dossier si nécessaire
        $dir = Split-Path $LocalPath
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        # Télécharger
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing
        
        # Extraire le .edf pour obtenir .ebus (et .ebu si présent)
        # Note: HMS fournit des .edf qui sont des archives
        Extract-EDFFile -Path $LocalPath -Destination $dir
        
        Write-Host "  [OK] Firmware telecharge" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  [ERREUR] Impossible de telecharger le firmware" -ForegroundColor Red
        return $false
    }
}

# Fonction pour extraire un fichier EDF
function Extract-EDFFile {
    param(
        [string]$Path,
        [string]$Destination
    )
    
    # Les .edf sont des archives ZIP renommées
    $tempZip = [System.IO.Path]::ChangeExtension($Path, ".zip")
    Copy-Item $Path $tempZip -Force
    
    try {
        Expand-Archive -Path $tempZip -DestinationPath $Destination -Force
        Remove-Item $tempZip -Force
        Remove-Item $Path -Force # Supprimer le .edf après extraction
    }
    catch {
        Write-Host "Erreur extraction firmware" -ForegroundColor Red
    }
}

# Fonction pour télécharger les configurations depuis GitHub
function Download-Configuration {
    param(
        [string]$Type, # "ethernet" ou "4g"
        [string]$LocalPath
    )
    
    $url = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/configurations/$Type/backup.tar"
    
    try {
        $dir = Split-Path $LocalPath
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing
        return $true
    }
    catch {
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
        
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing
        return $true
    }
    catch {
        return $false
    }
}

# Fonction principale de préparation des sources
function Prepare-Sources {
    Write-Host "=== Preparation des sources ===" -ForegroundColor Cyan
    
    # Obtenir le manifest
    $manifest = Get-Manifest
    if (-not $manifest) {
        throw "Impossible de continuer sans manifest"
    }
    
    # Sauvegarder le manifest en cache
    $manifestCache = Join-Path $LocalCacheDir "manifest.json"
    $manifest | ConvertTo-Json -Depth 10 | Out-File $manifestCache -Encoding UTF8
    
    # Préparer la structure locale
    $firmwareDir = Join-Path $LocalCacheDir "Firmware"
    $configDir = Join-Path $LocalCacheDir "Configuration"
    $t2mDir = Join-Path $LocalCacheDir "T2M"
    
    # Télécharger les configurations (léger, toujours télécharger)
    Write-Host "Telechargement des configurations..." -ForegroundColor Gray
    Download-Configuration -Type "ethernet" -LocalPath (Join-Path $configDir "ethernet\backup.tar")
    Download-Configuration -Type "4g" -LocalPath (Join-Path $configDir "4g\backup.tar")
    
    # Télécharger la clé T2M
    Write-Host "Telechargement de la cle T2M..." -ForegroundColor Gray
    Download-T2MKey -LocalPath (Join-Path $t2mDir "T2M.txt")
    
    Write-Host "Sources preparees dans: $LocalCacheDir" -ForegroundColor Green
    return $LocalCacheDir
}
