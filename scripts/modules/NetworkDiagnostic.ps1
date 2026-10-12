# NetworkDiagnostic.ps1 - Règles du diagnostic réseau : profil de l'Ewon, choix d'interface, capture tcpdump

$Script:CaptureOutputPath              = "/usr/ewondiag.pcap"
$Script:CaptureMinSeconds              = 10
$Script:CaptureMaxSeconds              = 120
$Script:CaptureDefaultSeconds          = 60
# Marge laissée à l'Ewon pour répondre une fois la durée de capture écoulée.
$Script:CaptureReplyMarginSeconds      = 30
# Une interface inexistante rend la main en ~1 s, sans erreur, en laissant l'ancien fichier en place.
$Script:CaptureMissingInterfaceSeconds = 5
$Script:CaptureFinishedMarker          = "Finished"
$Script:TcpDumpMinFirmware             = [version]"12.2"
$Script:UnsetIpAddress                 = "0.0.0.0"
# Cartes mères sans switch intégré (même liste que l'outil HMS) ; les autres modèles (ex. Flexy 205) passent par des VLAN.
$Script:ModelsWithoutSwitch            = @("101", "102", "103", "201", "202", "203")
# En-têtes pcap acceptés : microsecondes ou nanosecondes, dans les deux boutismes.
$Script:PcapMagicHeaders               = @("D4-C3-B2-A1", "A1-B2-C3-D4", "4D-3C-B2-A1", "A1-B2-3C-4D")
$Script:PcapMagicLength                = 4
$Script:PcapGlobalHeaderLength         = 24

$Script:CaptureSide = @{
    Lan = "Lan"
    Wan = "Wan"
    All = "All"
}

$Script:WanKind = @{
    None     = "None"
    Ethernet = "Ethernet"
    Cellular = "Cellular"
    Wifi     = "Wifi"
}

$Script:CaptureInterface = @{
    Lan            = "eth0"
    LanSwitch      = "eth0.10"
    WanEthernet    = "eth1"
    WanSwitch      = "eth0.20"
    Cellular       = "ppp0"
    Wifi           = "wlan0"
    All            = "any"
}

$Script:DiagnosticErrorKind = @{
    InterfaceMissing    = "InterfaceMissing"
    CaptureRejected     = "CaptureRejected"
    CaptureInvalid      = "CaptureInvalid"
    CaptureFailed       = "CaptureFailed"
}

function Test-IpAssigned {
    param([string]$Ip)
    return (-not [string]::IsNullOrWhiteSpace($Ip)) -and $Ip -ne $Script:UnsetIpAddress
}

function Get-EwonNetworkProfile {
    param([Parameter(Mandatory)][hashtable]$Status)

    $model = if ($Status["MbPartNum"] -match '^FLEXY(\d{3})') { $Matches[1] } else { $null }

    $wanKind = $Script:WanKind.None
    if (Test-IpAssigned $Status["PppIp"]) {
        $wanKind = $Script:WanKind.Cellular
    } elseif (Test-IpAssigned $Status["WanIp"]) {
        $wanKind = if ([string]::IsNullOrWhiteSpace($Status["WifiSSIDName"])) { $Script:WanKind.Ethernet } else { $Script:WanKind.Wifi }
    }

    $firmware = [version]::new([int]$Status["FwrVerHi"], [int]$Status["FwrVerLo"])
    return @{
        PartNumber        = $Status["MbPartNum"]
        SerialNumber      = $Status["SerNum"]
        Firmware          = $Status["CodeName"]
        FirmwareSupported = $firmware -ge $Script:TcpDumpMinFirmware
        HasSwitch         = $model -notin $Script:ModelsWithoutSwitch
        WanKind           = $wanKind
    }
}

function Get-CaptureSides {
    param([Parameter(Mandatory)][hashtable]$NetworkProfile)
    if ($NetworkProfile.WanKind -eq $Script:WanKind.None) { return @($Script:CaptureSide.Lan, $Script:CaptureSide.All) }
    return @($Script:CaptureSide.Lan, $Script:CaptureSide.Wan, $Script:CaptureSide.All)
}

function Resolve-CaptureInterface {
    param([Parameter(Mandatory)][hashtable]$NetworkProfile, [Parameter(Mandatory)][string]$Side)

    switch ($Side) {
        $Script:CaptureSide.All { return $Script:CaptureInterface.All }
        $Script:CaptureSide.Lan {
            if ($NetworkProfile.HasSwitch) { return $Script:CaptureInterface.LanSwitch }
            return $Script:CaptureInterface.Lan
        }
        $Script:CaptureSide.Wan {
            switch ($NetworkProfile.WanKind) {
                $Script:WanKind.Cellular { return $Script:CaptureInterface.Cellular }
                $Script:WanKind.Wifi     { return $Script:CaptureInterface.Wifi }
                $Script:WanKind.Ethernet {
                    if ($NetworkProfile.HasSwitch) { return $Script:CaptureInterface.WanSwitch }
                    return $Script:CaptureInterface.WanEthernet
                }
            }
        }
    }
    throw "Unsupported capture side '$Side' for WAN kind '$($NetworkProfile.WanKind)'"
}

function Test-CaptureDuration {
    param([string]$Value)
    # Entier strict : « 10.6 », « 0x20 » ou « 1e2 » seraient sinon convertis silencieusement.
    if ($Value -notmatch '^\d{1,4}$') { return $false }
    $seconds = [int]$Value
    return $seconds -ge $Script:CaptureMinSeconds -and $seconds -le $Script:CaptureMaxSeconds
}

function Get-TcpDumpMinFirmwareLabel {
    return "$($Script:TcpDumpMinFirmware)s0"
}

function New-EwonCapture {
    param(
        [Parameter(Mandatory)][hashtable]$Session,
        [Parameter(Mandatory)][string]$Interface,
        [Parameter(Mandatory)][int]$DurationSeconds
    )
    # Le serveur web de l'Ewon reste bloqué pendant toute la capture : l'attente se fait dans un runspace
    # pour ne pas figer l'interface, qui suit l'avancement par la table partagée State.
    # Préparé à part (runspace ouvert) pour que Start-EwonCapture n'ait plus qu'à envoyer la requête :
    # un test programmé juste avant ne doit pas partir avant tcpdump.
    $state = [hashtable]::Synchronized(@{ Done = $false; Result = $null; Error = $null })

    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $sessionState.Commands.Add([System.Management.Automation.Runspaces.SessionStateFunctionEntry]::new(
        "Invoke-EwonTcpDump", ${function:Invoke-EwonTcpDump}.ToString()))
    $runspace = [runspacefactory]::CreateRunspace($sessionState)
    $runspace.Open()

    $shell = [powershell]::Create()
    $shell.Runspace = $runspace
    $null = $shell.AddScript({
        param($Session, $Interface, $DurationSeconds, $OutputPath, $ReplyMarginSeconds, $State)
        try {
            $State.Result = Invoke-EwonTcpDump -Session $Session -Interface $Interface -DurationSeconds $DurationSeconds `
                -OutputPath $OutputPath -ReplyMarginSeconds $ReplyMarginSeconds
        } catch {
            $State.Error = $_.Exception.Message
        } finally {
            $State.Done = $true
        }
    }).AddArgument($Session).AddArgument($Interface).AddArgument($DurationSeconds).AddArgument(
        $Script:CaptureOutputPath).AddArgument($Script:CaptureReplyMarginSeconds).AddArgument($state)

    return @{
        Shell           = $shell
        Handle          = $null
        State           = $state
        Interface       = $Interface
        DurationSeconds = $DurationSeconds
        StartedAt       = $null
    }
}

function Start-EwonCapture {
    param([Parameter(Mandatory)][hashtable]$Capture)
    $Capture.Handle = $Capture.Shell.BeginInvoke()
    $Capture.StartedAt = Get-Date
}

function Stop-EwonCapture {
    param([Parameter(Mandatory)][hashtable]$Capture)
    if ($Capture.Handle) {
        try { $Capture.Shell.EndInvoke($Capture.Handle) } catch {}
    }
    $Capture.Shell.Runspace.Close()
    $Capture.Shell.Dispose()
}

function Complete-EwonCapture {
    param([Parameter(Mandatory)][hashtable]$Session, [Parameter(Mandatory)][hashtable]$Capture)

    $state = $Capture.State
    Stop-EwonCapture -Capture $Capture

    if ($state.Error) {
        throw (New-EwonException -Kind $Script:DiagnosticErrorKind.CaptureFailed -Detail $state.Error)
    }
    if ($state.Result.Reply -notmatch $Script:CaptureFinishedMarker) {
        throw (New-EwonException -Kind $Script:DiagnosticErrorKind.CaptureRejected -Detail $state.Result.Reply.Trim())
    }
    if ($state.Result.ElapsedSeconds -lt $Script:CaptureMissingInterfaceSeconds) {
        throw (New-EwonException -Kind $Script:DiagnosticErrorKind.InterfaceMissing -Detail $Capture.Interface)
    }

    $bytes = Receive-EwonFile -Session $Session -Path $Script:CaptureOutputPath
    if ($bytes.Length -lt $Script:PcapGlobalHeaderLength -or [BitConverter]::ToString($bytes, 0, $Script:PcapMagicLength) -notin $Script:PcapMagicHeaders) {
        throw (New-EwonException -Kind $Script:DiagnosticErrorKind.CaptureInvalid)
    }
    return , $bytes
}

function Clear-EwonCapture {
    param([Parameter(Mandatory)][hashtable]$Session)
    # À n'appeler qu'une fois la capture rapatriée sur le poste : l'Ewon en garde sinon la seule copie.
    try {
        Remove-EwonFile -Session $Session -Path $Script:CaptureOutputPath
        return $true
    } catch {
        return $false
    }
}

function Get-CaptureFileName {
    param([Parameter(Mandatory)][hashtable]$NetworkProfile, [Parameter(Mandatory)][string]$Interface)
    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    return "ewontrace_$($Interface)_$($NetworkProfile.SerialNumber)_$timestamp.pcap"
}
