# AppState.ps1 - Central state management
# Single source of truth for all application data

$Script:AppState = @{
    # Mode
    Mode                = "Online"       # "Online" | "Cache" | "Preparation"

    # Firmware
    CurrentFirmware     = $null
    TargetFirmware      = $null
    SkipFirmwareUpdate  = $false
    AvailableFirmwares  = @()
    CompatibleFirmwares = @()

    # Connection
    ConnectionType      = "Ethernet"     # "4G" | "Ethernet" | "Datalogger"

    # Parameters (collected from user)
    CollectedParams     = @{}

    # T2M
    T2MKey              = ""
    T2MNote             = ""

    # SD
    SdDrive             = $null

    # Manifest
    Manifest            = $null

    # Runtime
    CurrentStep         = 0
    IsGenerating        = $false
    Errors              = @()
}

function Get-AppState { return $Script:AppState }

function Set-AppStateValue {
    param([string]$Key, $Value)
    $Script:AppState[$Key] = $Value
}

function Get-CollectedParam {
    param([string]$Name)
    return $Script:AppState.CollectedParams[$Name]
}

function Set-CollectedParam {
    param([string]$Name, $Value)
    $Script:AppState.CollectedParams[$Name] = $Value
}

function Reset-CollectedParams {
    $Script:AppState.CollectedParams = @{}
}

function Get-AppVersion {
    # Production: read version.json maintained by the C# wrapper after install/update
    $versionFile = Join-Path $env:LOCALAPPDATA "EwonFlexySdPrep\version.json"
    if (Test-Path $versionFile) {
        try {
            $v = (Get-Content $versionFile -Raw | ConvertFrom-Json).version
            if ($v -and $v -ne "0.0.0") { return $v }
        } catch {}
    }

    # Dev / fallback: read manifest.json at repo root (script lives in scripts/modules/)
    $candidates = @(
        (Join-Path $PSScriptRoot "..\..\manifest.json"),
        (Join-Path $PSScriptRoot "..\manifest.json"),
        (Join-Path $PSScriptRoot "manifest.json")
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) {
            try {
                $v = (Get-Content $p -Raw | ConvertFrom-Json).version
                if ($v) { return $v }
            } catch {}
        }
    }

    return "dev"
}
