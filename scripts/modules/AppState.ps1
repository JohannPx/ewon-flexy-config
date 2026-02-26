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
