# PowerShell Script: Prepare Ewon Flexy SD card with dynamic backup.tar generation
# Version: 4.0.0
# Author: JPR
# Date: 2025-09-22

# =================== GENERAL SETTINGS ===================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Console UTF-8 si dispo; tout le texte est en ASCII pour compatibilite EXE
try { chcp 65001 > $null } catch {}
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# TLS 1.2
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$Host.UI.RawUI.WindowTitle = "Preparation Carte SD Ewon Flexy - Generation Dynamique"

# ======= GITHUB CONFIG (PUBLIC REPO - NO TOKEN) =======
$GitHubRepo   = "JohannPx/ewon-flexy-config"   # owner/repo
$GitHubBranch = "main"

# Local cache folder (manifest, templates, firmwares ONLY)
$LocalCacheDir = Join-Path $env:APPDATA "EwonFlexConfig"

# =================== PARAMETER DEFINITIONS ===================
# Based on the Excel template, defining all parameters and their properties
$ParameterDefinitions = @(
    # Common parameters (always asked)
    @{File="comcfg.txt"; Param="EthIP"; Default="192.168.253.254"; Description="LAN IP address"; Type="IPv4"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="EthMask"; Default="255.255.255.0"; Description="LAN Subnet mask"; Type="IPv4"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="config.txt"; Param="Identification"; Default="Clauger auto registered Ewon"; Description="Ewon Identification"; Type="Text"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="config.txt"; Param="NtpServerAddr"; Default="ntp.talk2m.com"; Description="NTP Server Address"; Type="Text"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="config.txt"; Param="NtpServerPort"; Default="123"; Description="The port of the remote NTP server"; Type="Integer"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="config.txt"; Param="Timezone"; Default="Europe/Paris"; Description="The configuration of the Ewon timezone"; Type="Text"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="config.txt"; Param="Password"; Default="adm"; Description="User Password (max 24 chars)"; Type="Password"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="program.bas"; Param="AccountName"; Default=""; Description="Data account name"; Type="Text"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="program.bas"; Param="AccountAuthorization"; Default=""; Description="Data authorization"; Type="Password"; AlwaysAsk=$true; ConnectionType=$null; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    
    # Connection type specific (automatic values)
    @{File="comcfg.txt"; Param="WANCnx"; Default=$null; Description=$null; Value4G="1"; ValueEthernet="2"; ValueDatalogger="0"; Type="Auto"; AlwaysAsk=$false; ConnectionType=$null; Condition=$null; Choices=$null},
    @{File="comcfg.txt"; Param="WANItfProt"; Default=$null; Description=$null; Value4G="1"; ValueEthernet="3"; ValueDatalogger="0"; Type="Auto"; AlwaysAsk=$false; ConnectionType=$null; Condition=$null; Choices=$null},
    @{File="comcfg.txt"; Param="WANPermCnx"; Default=$null; Description=$null; Value4G="1"; ValueEthernet="1"; ValueDatalogger="0"; Type="Auto"; AlwaysAsk=$false; ConnectionType=$null; Condition=$null; Choices=$null},
    @{File="comcfg.txt"; Param="LANWANConfig"; Default=$null; Description=$null; Value4G="8"; ValueEthernet="8"; ValueDatalogger="0"; Type="Auto"; AlwaysAsk=$false; ConnectionType=$null; Condition=$null; Choices=$null},
    
    # Ethernet specific
    @{File="comcfg.txt"; Param="UseBOOTP2"; Default="2"; Description="WAN IP Address Allocation (0=Static, 2=DHCP)"; Type="Choice"; Choices=@("0","2"); ConnectionType="Ethernet"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null},
    @{File="comcfg.txt"; Param="EthIpAddr2"; Default=""; Description="WAN IP address"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="EthIpMask2"; Default="255.255.255.0"; Description="WAN Subnet mask"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="EthGW"; Default=""; Description="Default WAN gateway"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="EthDns1"; Default="8.8.8.8"; Description="Ethernet DNS 1 IP address"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="EthDns2"; Default="1.1.1.1"; Description="Ethernet DNS 2 IP address"; Type="IPv4"; ConnectionType="Ethernet"; AlwaysAsk=$false; Condition="UseBOOTP2=0"; Value4G=$null; ValueEthernet=$null; Choices=$null},
    
    # 4G specific
    @{File="comcfg.txt"; Param="PIN"; Default="0000"; Description="Modem PIN Code (4 digits)"; Type="PIN"; ConnectionType="4G"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="PdpApn"; Default="orange"; Description="GPRS PDP: Access Point Name"; Type="Text"; ConnectionType="4G"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="PPPClUserName1"; Default="orange"; Description="APN Username"; Type="Text"; ConnectionType="4G"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="PPPClPassword1"; Default="orange"; Description="APN Password"; Type="Password"; ConnectionType="4G"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},

    # Datalogger specific (LAN only - no WAN, Gateway and DNS via LAN interface)
    @{File="comcfg.txt"; Param="EthGW"; Default=""; Description="Default gateway (via LAN)"; Type="IPv4"; ConnectionType="Datalogger"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="EthDns1"; Default="8.8.8.8"; Description="DNS 1 IP address"; Type="IPv4"; ConnectionType="Datalogger"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null},
    @{File="comcfg.txt"; Param="EthDns2"; Default="1.1.1.1"; Description="DNS 2 IP address"; Type="IPv4"; ConnectionType="Datalogger"; AlwaysAsk=$false; Condition=$null; Value4G=$null; ValueEthernet=$null; Choices=$null}
)

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

# =================== TEMPLATE DOWNLOADS ===================
function Download-Template {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][string]$LocalPath
    )
    
    $url = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch/templates/$FileName"
    try {
        New-Dir (Split-Path $LocalPath) | Out-Null
        Write-Host "Telechargement template $FileName..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing
        Write-Host "  [OK]" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  [ERREUR] $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# =================== PARAMETER COLLECTION ===================
function Validate-IPv4 {
    param([string]$ip)
    return $ip -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
}

function Validate-PIN {
    param([string]$pin)
    return $pin -match '^\d{4}$'
}

function Prompt-Parameter {
    param(
        [Parameter(Mandatory)]$ParamDef,
        [hashtable]$CollectedParams = @{}
    )
    
    # Check condition if exists
    if ($ParamDef.Condition) {
        $condParts = $ParamDef.Condition -split '='
        if ($condParts.Count -eq 2) {
            $condParam = $condParts[0]
            $condValue = $condParts[1]
            if ($CollectedParams[$condParam] -ne $condValue) {
                # Condition not met, use default
                return $ParamDef.Default
            }
        }
    }
    
    $prompt = "$($ParamDef.Description)"
    if ($ParamDef.Default) {
        $prompt += " [defaut: $($ParamDef.Default)]"
    }
    
    do {
        $valid = $true
        
        switch ($ParamDef.Type) {
            "Password" {
                # Double saisie uniquement pour le mot de passe administrateur
                if ($ParamDef.Param -eq "Password") {
                    do {
                        # Première saisie
                        do {
                            $sec1 = Read-Host "$prompt" -AsSecureString
                            if (-not $sec1 -or $sec1.Length -eq 0) {
                                if ($ParamDef.Default) {
                                    Write-Host "Utilisation de la valeur par defaut." -ForegroundColor Yellow
                                    return $ParamDef.Default
                                }
                                Write-Host "Valeur obligatoire." -ForegroundColor Red
                            }
                        } until ($sec1 -and $sec1.Length -gt 0)
                        
                        # Deuxième saisie (confirmation)
                        $sec2 = Read-Host "Confirmez le mot de passe" -AsSecureString
                        
                        # Conversion et comparaison
                        $pwd1 = Convert-SecureToPlain -Secure $sec1
                        $pwd2 = Convert-SecureToPlain -Secure $sec2
                        
                        if ($pwd1 -ne $pwd2) {
                            Write-Host "Les mots de passe ne correspondent pas. Veuillez reessayer." -ForegroundColor Red
                            $passwordsMatch = $false
                        } else {
                            $passwordsMatch = $true
                            $value = $pwd1
                        }
                    } until ($passwordsMatch)
                } else {
                    # Saisie simple pour AccountAuthorization et PPPClPassword1
                    $sec = Read-Host $prompt -AsSecureString
                    if (-not $sec -or $sec.Length -eq 0) { 
                        if ($ParamDef.Default) {
                            return $ParamDef.Default
                        } else {
                            # Retourner vide si aucune valeur (optionnel)
                            return ""
                        }
                    }
                    $value = if ($sec -and $sec.Length -gt 0) { Convert-SecureToPlain -Secure $sec } else { "" }
                }
            }
            
            "Choice" {
                Write-Host $prompt -ForegroundColor Cyan
                if ($ParamDef.Choices -and $ParamDef.Choices.Count -gt 0) {
                    for ($i = 0; $i -lt $ParamDef.Choices.Count; $i++) {
                        $desc = if ($ParamDef.Choices[$i] -eq "0") { "Static" } elseif ($ParamDef.Choices[$i] -eq "2") { "DHCP" } else { $ParamDef.Choices[$i] }
                        Write-Host "  [$($i+1)] $desc"
                    }
                    do {
                        $choice = Read-Host "Choix (1-$($ParamDef.Choices.Count))"
                    } while (-not ($choice -as [int]) -or [int]$choice -lt 1 -or [int]$choice -gt $ParamDef.Choices.Count)
                    $value = $ParamDef.Choices[[int]$choice - 1]
                } else {
                    # Fallback if no choices defined
                    $value = Read-Host $prompt
                    if (-not $value -and $ParamDef.Default) {
                        $value = $ParamDef.Default
                    }
                }
            }
            
            "IPv4" {
                $value = Read-Host $prompt
                if (-not $value -and $ParamDef.Default) {
                    $value = $ParamDef.Default
                } elseif ($value) {
                    if (-not (Validate-IPv4 $value)) {
                        Write-Host "Adresse IP invalide. Format: xxx.xxx.xxx.xxx" -ForegroundColor Red
                        $valid = $false
                    }
                }
            }
            
            "PIN" {
                $value = Read-Host $prompt
                if (-not $value -and $ParamDef.Default) {
                    $value = $ParamDef.Default
                } elseif ($value) {
                    if (-not (Validate-PIN $value)) {
                        Write-Host "Code PIN invalide. 4 chiffres requis." -ForegroundColor Red
                        $valid = $false
                    }
                }
            }
            
            "Integer" {
                $value = Read-Host $prompt
                if (-not $value -and $ParamDef.Default) {
                    $value = $ParamDef.Default
                } elseif ($value) {
                    if (-not ($value -as [int])) {
                        Write-Host "Entier requis." -ForegroundColor Red
                        $valid = $false
                    }
                }
            }
            
            default {
                $value = Read-Host $prompt
                if (-not $value -and $ParamDef.Default) {
                    $value = $ParamDef.Default
                }
            }
        }
        
    } while (-not $valid)
    
    return $value
}

# =================== TAR CREATION ===================
function Create-TarArchive {
    param(
        [Parameter(Mandatory)][string[]]$Files,
        [Parameter(Mandatory)][string]$OutputPath
    )
    
    try {
        # Use built-in tar if available (Windows 10+)
        $tarExe = Get-Command tar -ErrorAction SilentlyContinue
        if ($tarExe) {
            # Create tar using Windows tar
            $tempDir = Join-Path $env:TEMP ("ewon_tar_" + (Get-Date -Format "yyyyMMddHHmmss"))
            New-Dir $tempDir | Out-Null
            
            # Copy files to temp dir with correct names
            foreach ($file in $Files) {
                Copy-Item -Path $file -Destination $tempDir -Force
            }
            
            Push-Location $tempDir
            & tar -cf $OutputPath *
            Pop-Location
            
            Remove-Item $tempDir -Recurse -Force
            return $true
        } else {
            # Fallback: Create simple tar format manually
            Write-Host "Windows tar non disponible, creation manuelle..." -ForegroundColor Yellow
            
            $stream = [System.IO.FileStream]::new($OutputPath, [System.IO.FileMode]::Create)
            $writer = [System.IO.BinaryWriter]::new($stream)
            
            foreach ($file in $Files) {
                $fileInfo = Get-Item $file
                $fileName = $fileInfo.Name
                $fileSize = $fileInfo.Length
                $fileContent = [System.IO.File]::ReadAllBytes($file)
                
                # Create TAR header (simplified)
                $header = New-Object byte[] 512
                
                # File name (max 100 bytes)
                $nameBytes = [System.Text.Encoding]::ASCII.GetBytes($fileName)
                [Array]::Copy($nameBytes, 0, $header, 0, [Math]::Min($nameBytes.Length, 100))
                
                # File mode (100644 in octal = 33188 decimal)
                $modeBytes = [System.Text.Encoding]::ASCII.GetBytes("100644 ")
                [Array]::Copy($modeBytes, 0, $header, 100, $modeBytes.Length)
                
                # File size in octal
                $sizeOctal = [Convert]::ToString($fileSize, 8).PadLeft(11, '0') + ' '
                $sizeBytes = [System.Text.Encoding]::ASCII.GetBytes($sizeOctal)
                [Array]::Copy($sizeBytes, 0, $header, 124, $sizeBytes.Length)
                
                # Write header and file content
                $writer.Write($header)
                $writer.Write($fileContent)
                
                # Padding to 512 bytes
                $padding = 512 - ($fileSize % 512)
                if ($padding -ne 512) {
                    $writer.Write((New-Object byte[] $padding))
                }
            }
            
            # Write end of archive (2 blocks of 512 zeros)
            $writer.Write((New-Object byte[] 1024))
            
            $writer.Close()
            $stream.Close()
            return $true
        }
    } catch {
        Write-Host "Erreur lors de la creation du TAR: $_" -ForegroundColor Red
        return $false
    }
}

# =================== T2M (ASK JUST BEFORE SD, NO CACHE) ===================
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

# =================== FIRMWARE HMS (PUBLIC HMS SITE) ===================
function Parse-FirmwareVersion {
    param([string]$version)
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
        $ebusUrl = "$baseUrl/er-$versionForUrl-arm-ma_secure.ebus"
        Invoke-WebRequest -Uri $ebusUrl -OutFile $ebusPath -UseBasicParsing

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
    Write-Host "         PREPARATION CARTE SD EWON FLEXY - GENERATION DYNAMIQUE" -ForegroundColor Cyan
    Write-Host $headerBorder -ForegroundColor DarkCyan
    Write-Host ""

    # Mode selection
    Write-Host "=== Mode de fonctionnement ===" -ForegroundColor Cyan
    Write-Host "  [1] ONLINE       - Telecharger manifest + templates (Internet requis)"
    Write-Host "  [2] CACHE        - Utiliser cache local existant"
    Write-Host "  [3] PREPARATION  - Telecharger TOUT pour usage offline (manifest, templates, firmwares)"
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

        # Templates
        Write-Host "`nTelechargement des templates..." -ForegroundColor Cyan
        $templatesDir = New-Dir (Join-Path $LocalCacheDir "templates")
        Download-Template -FileName "program.bas" -LocalPath (Join-Path $templatesDir "program.bas") | Out-Null
        Download-Template -FileName "comcfg.txt" -LocalPath (Join-Path $templatesDir "comcfg.txt") | Out-Null
        Download-Template -FileName "config.txt" -LocalPath (Join-Path $templatesDir "config.txt") | Out-Null

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
        # ONLINE: manifest + templates
        Write-Host "`n=== Mode ONLINE ===" -ForegroundColor Green
        $null = New-Dir $LocalCacheDir

        $manifest = Get-Manifest
        if (-not $manifest) { throw "Impossible de continuer: manifest indisponible." }

        ($manifest | ConvertTo-Json -Depth 10) | Out-File (Join-Path $LocalCacheDir "manifest.json") -Encoding UTF8

        Write-Host "`nTelechargement des templates..." -ForegroundColor Cyan
        $templatesDir = New-Dir (Join-Path $LocalCacheDir "templates")
        Download-Template -FileName "program.bas" -LocalPath (Join-Path $templatesDir "program.bas") | Out-Null
        Download-Template -FileName "comcfg.txt" -LocalPath (Join-Path $templatesDir "comcfg.txt") | Out-Null
        Download-Template -FileName "config.txt" -LocalPath (Join-Path $templatesDir "config.txt") | Out-Null
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

        # Check templates
        $templatesDir = Join-Path $LocalCacheDir "templates"
        if (-not (Test-Path $templatesDir)) {
            throw "Templates absents du cache. Utilisez ONLINE ou PREPARATION d'abord."
        }
    }
    else {
        throw "Choix invalide"
    }

    # Working dirs
    $TemplatesDir = Join-Path $LocalCacheDir "templates"
    $FwDir = Join-Path $LocalCacheDir "firmware"

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
    $profile = Select-FromList -Title "Mode connexion" -Options @("Modem 4G","Ethernet","Datalogger (LAN uniquement)")
    $ConnectionType = switch ($profile) {
        "Modem 4G" { "4G" }
        "Ethernet" { "Ethernet" }
        "Datalogger (LAN uniquement)" { "Datalogger" }
    }

    # =================== COLLECT PARAMETERS FROM USER ===================
    Write-Host ""
    Write-Host "=== Configuration des parametres ===" -ForegroundColor Cyan
    Write-Host "Entrez les valeurs ou appuyez sur Entree pour utiliser la valeur par defaut." -ForegroundColor Gray
    Write-Host ""

    $CollectedParams = @{}

    # Modifier la valeur par défaut de NtpServerAddr selon le mode de connexion
    # En mode Datalogger, pas de Talk2M donc utiliser un serveur NTP public
    if ($ConnectionType -eq "Datalogger") {
        $ntpParam = $ParameterDefinitions | Where-Object { $_.Param -eq "NtpServerAddr" -and $_.AlwaysAsk -eq $true }
        if ($ntpParam) {
            $ntpParam.Default = "fr.pool.ntp.org"
        }
    }

    # First collect always-ask parameters
    Write-Host "--- Parametres communs ---" -ForegroundColor Yellow
    foreach ($paramDef in $ParameterDefinitions | Where-Object { $_.AlwaysAsk -eq $true }) {
        $value = Prompt-Parameter -ParamDef $paramDef -CollectedParams $CollectedParams
        $CollectedParams[$paramDef.Param] = $value
        
        # Masquer l'affichage des mots de passe et données sensibles
        if ($paramDef.Type -eq "Password") {
            Write-Host "  $($paramDef.Param) = ********" -ForegroundColor DarkGray
        } else {
            Write-Host "  $($paramDef.Param) = $value" -ForegroundColor DarkGray
        }
    }
    
    # Then collect connection-specific parameters
    Write-Host ""
    Write-Host "--- Parametres $ConnectionType ---" -ForegroundColor Yellow
    foreach ($paramDef in $ParameterDefinitions | Where-Object { $_.ConnectionType -eq $ConnectionType }) {
        $value = Prompt-Parameter -ParamDef $paramDef -CollectedParams $CollectedParams
        $CollectedParams[$paramDef.Param] = $value
        
        # Masquer l'affichage des mots de passe et données sensibles
        if ($paramDef.Type -eq "Password") {
            Write-Host "  $($paramDef.Param) = ********" -ForegroundColor DarkGray
        } else {
            Write-Host "  $($paramDef.Param) = $value" -ForegroundColor DarkGray
        }
    }
    
    # Add automatic parameters based on connection type
    foreach ($paramDef in $ParameterDefinitions | Where-Object { $_.Type -eq "Auto" }) {
        if ($ConnectionType -eq "4G" -and $null -ne $paramDef.Value4G) {
            $CollectedParams[$paramDef.Param] = $paramDef.Value4G
        } elseif ($ConnectionType -eq "Ethernet" -and $null -ne $paramDef.ValueEthernet) {
            $CollectedParams[$paramDef.Param] = $paramDef.ValueEthernet
        } elseif ($ConnectionType -eq "Datalogger" -and $null -ne $paramDef.ValueDatalogger) {
            $CollectedParams[$paramDef.Param] = $paramDef.ValueDatalogger
        }
    }

    # ======================================================
    # Ajustement dynamique de PrgAutorun
    # ======================================================
    if ([string]::IsNullOrWhiteSpace($CollectedParams["AccountAuthorization"])) {
        $CollectedParams["PrgAutorun"] = "0"
    } else {
        $CollectedParams["PrgAutorun"] = "1"
    }

    # --- T2M ASK NOW (JUSTE AVANT LA SELECTION DU LECTEUR), MODES 1 & 2 SEULEMENT ---
    # En mode Datalogger, pas de Talk2M (communication via LAN uniquement)
    $T2M = $null
    if ($mode -ne "3" -and $ConnectionType -ne "Datalogger") {
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
    
# =================== GENERATE BACKUP.TAR ===================
    Write-Host ""
    Write-Host "=== Generation du backup.tar ===" -ForegroundColor Cyan
    
    # Create temp directory for modified files
    $tempDir = Join-Path $env:TEMP ("ewon_config_" + (Get-Date -Format "yyyyMMddHHmmss"))
    New-Dir $tempDir | Out-Null
    
    # Define unused parameters based on connection type
    $UnusedParams = @()
    if ($ConnectionType -eq "4G") {
        # If 4G, Ethernet parameters are unused
        $UnusedParams = @("UseBOOTP2", "EthIpAddr2", "EthIpMask2", "EthGW", "EthDns1", "EthDns2")
    } elseif ($ConnectionType -eq "Datalogger") {
        # If Datalogger (LAN only), 4G and WAN Ethernet parameters are unused (keep EthGW, EthDns1, EthDns2)
        $UnusedParams = @("PIN", "PdpApn", "PPPClUserName1", "PPPClPassword1", "UseBOOTP2", "EthIpAddr2", "EthIpMask2")
    } else {
        # If Ethernet, 4G parameters are unused
        $UnusedParams = @("PIN", "PdpApn", "PPPClUserName1", "PPPClPassword1")

        # Vérifier la valeur choisie pour UseBOOTP2
        if ($CollectedParams["UseBOOTP2"] -eq "2") {
            # Si DHCP, supprimer aussi les IP/DNS statiques
            $UnusedParams += @("EthIpAddr2", "EthIpMask2", "EthGW", "EthDns1", "EthDns2")
        }
    }
    
    try {
        # Process each template file
        foreach ($templateFile in @("program.bas", "comcfg.txt", "config.txt")) {
            Write-Host "  Traitement de $templateFile..." -ForegroundColor Gray
            
            $templatePath = Join-Path $TemplatesDir $templateFile
            if (-not (Test-Path $templatePath)) {
                throw "Template manquant: $templatePath"
            }
            
            # Read template content line by line
            $lines = Get-Content $templatePath
            $processedLines = @()
            
            foreach ($line in $lines) {
                $skipLine = $false
                
                # Check if this line contains an unused parameter
                foreach ($unusedParam in $UnusedParams) {
                    if ($line -match [regex]::Escape("{$unusedParam}")) {
                        $skipLine = $true
                        Write-Host "    Suppression ligne: $unusedParam" -ForegroundColor DarkGray
                        break
                    }
                }
                
                if (-not $skipLine) {
                    # Replace placeholders in this line
                    $processedLine = $line
                    foreach ($key in $CollectedParams.Keys) {
                        $placeholder = "{$key}"
                        $newLine = $processedLine -replace [regex]::Escape($placeholder), $CollectedParams[$key]
                        if ($newLine -ne $processedLine) {
                            # Remplacement effectué silencieusement pour la sécurité
                            $processedLine = $newLine
                        }
                    }
                    $processedLines += $processedLine
                }
            }
            
            # Save modified file
            $outputPath = Join-Path $tempDir $templateFile
            $processedLines | Out-File -FilePath $outputPath -Encoding ASCII -Force
        }
        
        # Create backup.tar
        $backupTarPath = Join-Path $sdDrive "backup.tar"
        Write-Host "  Creation de backup.tar..." -ForegroundColor Gray
        
        $filesToTar = Get-ChildItem $tempDir -File | Select-Object -ExpandProperty FullName
        if (Create-TarArchive -Files $filesToTar -OutputPath $backupTarPath) {
            Write-Host "  [OK] backup.tar cree" -ForegroundColor Green
        } else {
            throw "Echec de la creation de backup.tar"
        }
        
    } finally {
        # Clean up temp directory
        if (Test-Path $tempDir) {
            Remove-Item $tempDir -Recurse -Force
        }
    }

    # Copy firmware files to SD
    $filesToCopy = @()
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

    # Copy firmware files
    if ($filesToCopy.Count -gt 0) {
        Write-Host ""; Write-Host ("=== Copie des firmwares vers {0} ===" -f $sdDrive) -ForegroundColor Green
        Write-Host $firmwareNote -ForegroundColor Yellow
        Write-Host ""

        foreach($src in $filesToCopy){
            $leaf = Split-Path $src -Leaf
            $dest = Join-Path $sdDrive $leaf
            if(Test-Path $src){
                Copy-Item -Path $src -Destination $dest -Force
                Write-Host (" + {0}" -f $leaf) -ForegroundColor DarkGreen
                Log ("Copy: {0} -> {1}" -f $src, $dest)
            } else {
                Write-Host (" ! Fichier manquant: {0}" -f $src) -ForegroundColor Red
            }
        }
    }

    # ---- T2M written ONLY on SD (not in cache), modes 1 & 2, NOT for Datalogger ----
    if ($mode -ne "3" -and $ConnectionType -ne "Datalogger") {
        Write-Host ""
        Write-Host "Creation du T2M.txt directement sur la SD..." -ForegroundColor Cyan
        [void](Write-T2MDirect -SdRoot $sdDrive -T2MKey $T2M.Key -T2MNote $T2M.Note)
    }

    # Verify
    Write-Host ""; Write-Host "=== Verification des fichiers ===" -ForegroundColor Yellow
    $expected = @("backup.tar")
    if ($mode -ne "3" -and $ConnectionType -ne "Datalogger") { $expected += "T2M.txt" }
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

    # Procedure detaillee
    $procPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "Procedure_Ewon.txt"
    if ($skipFirmwareUpdate) {
$proc = @'
PROCEDURE DETAILLEE APRES PREPARATION DE LA CARTE SD
--------------------------------------------------
CONFIGURATION SANS MISE A JOUR FIRMWARE

Configuration generee dynamiquement avec les parametres suivants:
'@
        $proc += "`n"
        foreach ($key in $CollectedParams.Keys | Sort-Object) {
            if ($key -ne "Password" -and $key -ne "PPPClPassword1" -and $key -ne "AccountAuthorization") {
                $proc += "- $key : $($CollectedParams[$key])`n"
            }
        }
        $proc += @'

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
- Information carte SIM (si 4G)
- Identifiant IFS du site client
- Nom souhaite pour l Ewon

CONCLUSION
Votre Ewon Flexy est maintenant configure.
'@
        # Pour le mode Datalogger, remplacer l'etape d'acces a distance
        if ($ConnectionType -eq "Datalogger") {
            $proc = $proc -replace "ETAPE 3 : DEMANDE D ACCES A DISTANCE[\s\S]*?CONCLUSION", @"
ETAPE 3 : VERIFICATION DE LA COMMUNICATION
L'Ewon communique via son interface LAN uniquement (pas de Talk2M).
Verifiez que l'Ewon peut atteindre le serveur push.myclauger.com via le reseau local.

CONCLUSION
"@
        }
    } else {
$proc = @'
PROCEDURE DETAILLEE APRES PREPARATION DE LA CARTE SD
--------------------------------------------------

Configuration generee dynamiquement avec les parametres suivants:
'@
        $proc += "`n"
        foreach ($key in $CollectedParams.Keys | Sort-Object) {
            if ($key -ne "Password" -and $key -ne "PPPClPassword1" -and $key -ne "AccountAuthorization") {
                $proc += "- $key : $($CollectedParams[$key])`n"
            }
        }
        $proc += @'

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
- Information carte SIM (si 4G)
- Identifiant IFS du site client
- Nom souhaite pour l Ewon

CONCLUSION
Votre Ewon Flexy est maintenant configure et a jour.
'@
        # Pour le mode Datalogger, remplacer l'etape d'acces a distance
        if ($ConnectionType -eq "Datalogger") {
            $proc = $proc -replace "ETAPE 4 : DEMANDE D ACCES A DISTANCE[\s\S]*?CONCLUSION", @"
ETAPE 4 : VERIFICATION DE LA COMMUNICATION
L'Ewon communique via son interface LAN uniquement (pas de Talk2M).
Verifiez que l'Ewon peut atteindre le serveur push.myclauger.com via le reseau local.

CONCLUSION
"@
        }
    }
    $proc | Out-File -FilePath $procPath -Encoding ASCII
    try { Start-Process notepad.exe $procPath | Out-Null } catch {}

    # End
    Write-Host ""
    Write-Host "=== PREPARATION TERMINEE AVEC SUCCES ===" -ForegroundColor Green
    Write-Host ("MODE: {0}" -f ($(if($skipFirmwareUpdate){"Configuration uniquement"}else{"MAJ firmware + Configuration"}))) -ForegroundColor Cyan
    Write-Host ("Type de connexion: {0}" -f $ConnectionType) -ForegroundColor Cyan
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