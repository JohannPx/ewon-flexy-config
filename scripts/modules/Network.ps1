# Network.ps1 - Downloads, cache management, TLS setup

$Script:GitHubRepo   = "JohannPx/ewon-flexy-config"
$Script:GitHubBranch  = "main"
$Script:LocalCacheDir = Join-Path $env:APPDATA "EwonFlexConfig"

function Initialize-Network {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
}

function Get-LocalCacheDir { return $Script:LocalCacheDir }

function New-Dir([string]$Path) {
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    return $Path
}

function Download-Template {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][string]$LocalPath,
        [scriptblock]$OnLog = { param($msg) }
    )

    $url = "https://raw.githubusercontent.com/$Script:GitHubRepo/$Script:GitHubBranch/templates/$FileName"
    try {
        New-Dir (Split-Path $LocalPath) | Out-Null
        & $OnLog "Telechargement template $FileName..."
        Invoke-WebRequest -Uri $url -OutFile $LocalPath -UseBasicParsing
        & $OnLog "  [OK] $FileName"
        return $true
    } catch {
        & $OnLog "[ERREUR] $($_.Exception.Message)"
        return $false
    }
}

function Get-Manifest {
    param([scriptblock]$OnLog = { param($msg) })

    $manifestUrl = "https://raw.githubusercontent.com/$Script:GitHubRepo/$Script:GitHubBranch/manifest.json"
    try {
        & $OnLog "Recuperation du manifest..."
        $json = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing
        return $json
    } catch {
        & $OnLog "Manifest indisponible en ligne. Recherche en cache..."
        $cached = Join-Path $Script:LocalCacheDir "manifest.json"
        if (Test-Path $cached) { return Get-Content $cached | ConvertFrom-Json }
        return $null
    }
}

function Save-ManifestToCache {
    param($Manifest)
    $null = New-Dir $Script:LocalCacheDir
    ($Manifest | ConvertTo-Json -Depth 10) | Out-File (Join-Path $Script:LocalCacheDir "manifest.json") -Encoding UTF8
}

function Test-CacheAvailable {
    $templatesDir = Join-Path $Script:LocalCacheDir "templates"
    return (Test-Path $templatesDir)
}

function Get-CachedManifest {
    $cached = Join-Path $Script:LocalCacheDir "manifest.json"
    if (Test-Path $cached) { return Get-Content $cached | ConvertFrom-Json }
    return $null
}

function Download-AllTemplates {
    param([scriptblock]$OnLog = { param($msg) })

    $templatesDir = New-Dir (Join-Path $Script:LocalCacheDir "templates")
    $ok = $true
    foreach ($file in @("program.bas", "comcfg.txt", "config.txt")) {
        $result = Download-Template -FileName $file -LocalPath (Join-Path $templatesDir $file) -OnLog $OnLog
        if (-not $result) { $ok = $false }
    }
    return $ok
}
