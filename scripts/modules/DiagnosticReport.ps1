# DiagnosticReport.ps1 - Règles du diagnostic : des faits décodés de la capture (PcapAnalyzer) et du résultat
# renvoyé par l'Ewon (DiagnosticTests), elles tirent des constats. Chaque constat est une clé de traduction
# et ses arguments : l'interface se contente de les mettre en forme.

$Script:FindingLevel = @{ Ok = "Ok"; Info = "Info"; Warning = "Warning"; Error = "Error" }
$Script:ReportTopFlowCount = 10
# Avec un chiffrement authentifié (AEAD), la liste MAC du même sens n'est pas utilisée.
$Script:SshAeadCiphers = @("chacha20-poly1305@openssh.com", "aes128-gcm@openssh.com", "aes256-gcm@openssh.com")
$Script:SshMacForEncryption = [ordered]@{ EncryptionC2S = "MacC2S"; EncryptionS2C = "MacS2C" }
# Dernière étape SSH atteinte : au-delà de NEWKEYS, tout est chiffré.
$Script:SshStage = @{ Banner = "Banner"; KeyExchange = "KeyExchange"; Encrypted = "Encrypted" }

function New-Finding {
    param([string]$Level, [string]$Key, [object[]]$Arguments = @())
    return @{ Level = $Level; Key = $Key; Arguments = $Arguments }
}

function New-TextArgument {
    param([string]$Key)
    # Argument à traduire lui-même (partie, étape, catégorie) plutôt qu'à afficher tel quel.
    return @{ TextKey = $Key }
}

function Get-PartyArgument {
    param([string]$By)
    if ($By -eq [EwonDiagnostics.TcpDecoder]::Client) { return New-TextArgument "DiagParty_Client" }
    return New-TextArgument "DiagParty_Server"
}

function Get-EwonResultFindings {
    param([hashtable]$Result)
    $findings = @()
    # Une lecture en échec n'efface pas ce qui a déjà été lu (l'action peut l'être, pas le code HTTP).
    if ($Result.EwonResultError) {
        $findings += New-Finding $Script:FindingLevel.Warning "DiagF_EwonResultUnavailable" @($Result.EwonResultError)
    }
    if (-not $Result.Action) {
        if (-not $Result.EwonResultError) { $findings += New-Finding $Script:FindingLevel.Warning "DiagF_ActionMissing" }
    } elseif ($Result.Action.Code -eq 0) {
        $findings += New-Finding $Script:FindingLevel.Ok "DiagF_ActionOk" @($Result.Action.Type)
    } else {
        # Le texte d'action vient de l'Ewon : masqué s'il pouvait contenir un identifiant.
        $text = if ($Result.Action.Text -match $Script:EwonLogUnsafePattern) { New-TextArgument "DiagMaskedText" } else { $Result.Action.Text }
        $findings += New-Finding $Script:FindingLevel.Error "DiagF_ActionFailed" @($Result.Action.Code, $text)
    }
    if ($Result.ActionCount -gt 1) {
        # Le programme BASIC de l'Ewon a lancé la même action pendant le test : le résultat retenu peut être le sien.
        $findings += New-Finding $Script:FindingLevel.Warning "DiagF_ActionAmbiguous" @($Result.ActionCount)
    }

    foreach ($message in $Result.EwonMessages) {
        $findings += New-Finding $Script:FindingLevel.Info "DiagF_EwonLog" @($message)
    }

    $status = $Result.HttpStatus
    if ($null -ne $status) {
        if ($status -ge $Script:HttpSuccessRange.Min -and $status -le $Script:HttpSuccessRange.Max) {
            $findings += New-Finding $Script:FindingLevel.Ok "DiagF_HttpStatus" @($status)
        } elseif ($status -in $Script:HttpAuthRejectedCodes) {
            $findings += New-Finding $Script:FindingLevel.Error "DiagF_HttpAuthRejected" @($status)
        } else {
            $findings += New-Finding $Script:FindingLevel.Warning "DiagF_HttpError" @($status)
        }
    }
    return $findings
}

function Get-DnsFindings {
    param([string]$HostName, [hashtable]$Resolution)
    switch ($Resolution.Status) {
        $Script:DnsResolution.Resolved  { return New-Finding $Script:FindingLevel.Ok "DiagF_DnsResolved" @($HostName, ($Resolution.Addresses -join ", ")) }
        $Script:DnsResolution.NxDomain  { return New-Finding $Script:FindingLevel.Error "DiagF_DnsNotFound" @($HostName) }
        $Script:DnsResolution.NoAnswer  { return New-Finding $Script:FindingLevel.Error "DiagF_DnsNoAnswer" @($HostName) }
        $Script:DnsResolution.NoAddress { return New-Finding $Script:FindingLevel.Error "DiagF_DnsNoAddress" @($HostName) }
    }
    return New-Finding $Script:FindingLevel.Info "DiagF_DnsNotSeen" @($HostName)
}

function Get-SshCommonAlgorithms {
    param([Parameter(Mandatory)]$ClientKexInit, [Parameter(Mandatory)]$ServerKexInit)
    # Règle SSH : le premier algorithme de la liste du client que le serveur propose aussi.
    $common = [ordered]@{}
    foreach ($category in [EwonDiagnostics.SshDecoder]::Categories) {
        $common[$category] = $ClientKexInit[$category] | Where-Object { $_ -in $ServerKexInit[$category] } | Select-Object -First 1
    }
    return $common
}

function Get-SshStage {
    param([Parameter(Mandatory)]$Client, [Parameter(Mandatory)]$Server)
    if (-not $Server.Banner -or -not $Client.Banner) { return $Script:SshStage.Banner }
    if (-not ($Client.NewKeys -and $Server.NewKeys)) { return $Script:SshStage.KeyExchange }
    return $Script:SshStage.Encrypted
}

function Get-SshFindings {
    param($Connection)
    $client = [EwonDiagnostics.SshDecoder]::Parse($Connection.ClientStream)
    $server = [EwonDiagnostics.SshDecoder]::Parse($Connection.ServerStream)
    $findings = @()

    if ($server.Banner) {
        $findings += New-Finding $Script:FindingLevel.Info "DiagF_SshBanners" @($client.Banner, $server.Banner)
    } else {
        $findings += New-Finding $Script:FindingLevel.Error "DiagF_SshNoServerBanner"
    }

    if ($client.KexInit -and $server.KexInit) {
        $common = Get-SshCommonAlgorithms -ClientKexInit $client.KexInit -ServerKexInit $server.KexInit
        $missing = @($common.Keys | Where-Object { -not $common[$_] })
        foreach ($encryption in $Script:SshMacForEncryption.Keys) {
            if ($common[$encryption] -in $Script:SshAeadCiphers) { $missing = @($missing | Where-Object { $_ -ne $Script:SshMacForEncryption[$encryption] }) }
        }
        foreach ($category in $missing) {
            $findings += New-Finding $Script:FindingLevel.Error "DiagF_SshNoCommon" @(
                (New-TextArgument "DiagSshCategory_$category"), ($client.KexInit[$category] -join ", "), ($server.KexInit[$category] -join ", "))
        }
        if ($missing.Count -eq 0) {
            $findings += New-Finding $Script:FindingLevel.Ok "DiagF_SshNegotiated" @($common.Kex, $common.HostKey, $common.EncryptionC2S)
        }
    }

    foreach ($side in @(@{ Handshake = $client; By = [EwonDiagnostics.TcpDecoder]::Client }, @{ Handshake = $server; By = [EwonDiagnostics.TcpDecoder]::Server })) {
        if ($null -ne $side.Handshake.DisconnectCode) {
            $findings += New-Finding $Script:FindingLevel.Error "DiagF_SshDisconnect" @(
                (Get-PartyArgument $side.By), $side.Handshake.DisconnectDescription, $side.Handshake.DisconnectCode)
        }
    }

    $stage = Get-SshStage -Client $client -Server $server
    if ($stage -eq $Script:SshStage.Encrypted) {
        $findings += New-Finding $Script:FindingLevel.Ok "DiagF_SshEncrypted"
    } elseif ($Connection.Close) {
        $findings += New-Finding $Script:FindingLevel.Error "DiagF_SshClosedDuringNegotiation" @((Get-PartyArgument $Connection.Close.By), (New-TextArgument "DiagSshStage_$stage"))
    }
    return @{ Findings = $findings; Stage = $stage }
}

function Get-TlsFindings {
    param($Connection)
    $client = [EwonDiagnostics.TlsDecoder]::Parse($Connection.ClientStream, $true)
    $server = [EwonDiagnostics.TlsDecoder]::Parse($Connection.ServerStream, $false)
    $findings = @()

    if ($null -ne $client.HelloVersion) {
        $maxVersion = if ($client.SupportedVersions.Count -gt 0) { ($client.SupportedVersions | Measure-Object -Maximum).Maximum } else { $client.HelloVersion }
        $findings += New-Finding $Script:FindingLevel.Info "DiagF_TlsClientHello" @((Get-TlsVersionName $maxVersion), $client.ServerName)
    }
    if ($null -ne $server.HelloVersion) {
        $version = if ($server.SupportedVersions.Count -gt 0) { $server.SupportedVersions[0] } else { $server.HelloVersion }
        $findings += New-Finding $Script:FindingLevel.Ok "DiagF_TlsServerHello" @((Get-TlsVersionName $version), ("0x{0:X4}" -f $server.Suite))
    } elseif ($null -ne $client.HelloVersion) {
        $findings += New-Finding $Script:FindingLevel.Error "DiagF_TlsNoServerHello"
    }

    foreach ($side in @(@{ Handshake = $client; By = [EwonDiagnostics.TcpDecoder]::Client }, @{ Handshake = $server; By = [EwonDiagnostics.TcpDecoder]::Server })) {
        $alert = $side.Handshake.AlertDescription
        if ($null -ne $alert -and $alert -ne $Script:TlsAlertCloseNotify) {
            $findings += New-Finding $Script:FindingLevel.Error "DiagF_TlsAlert" @((Get-PartyArgument $side.By), (Get-TlsAlertName $alert))
        }
    }
    if ($client.ApplicationData -and $server.ChangeCipherSpec) {
        $findings += New-Finding $Script:FindingLevel.Ok "DiagF_TlsEncrypted"
    }
    return $findings
}

function Get-ConnectionFindings {
    param([hashtable]$Run, [object[]]$Connections)
    $findings = @()
    $stages = @()
    $index = 0
    foreach ($connection in $Connections) {
        $index++
        $findings += New-Finding $Script:FindingLevel.Info "DiagF_Connection" @($index, $connection.Client, $connection.ClientPort, $connection.Server, $connection.ServerPort)
        if (-not $connection.SynAcked) {
            if ($connection.Close -and $connection.Close.By -eq [EwonDiagnostics.TcpDecoder]::Server) {
                $findings += New-Finding $Script:FindingLevel.Error "DiagF_TcpRefused"
            } else {
                $findings += New-Finding $Script:FindingLevel.Error "DiagF_TcpNoAnswer" @($connection.SynCount)
            }
            $stages += $null
            continue
        }
        $findings += New-Finding $Script:FindingLevel.Ok "DiagF_TcpEstablished"

        switch ($Run.Target.Protocol) {
            $Script:DiagProtocol.Ssh {
                $ssh = Get-SshFindings -Connection $connection
                $findings += $ssh.Findings
                $stages += $ssh.Stage
            }
            $Script:DiagProtocol.Tls { $findings += Get-TlsFindings -Connection $connection }
        }
        if ($connection.Close) {
            $findings += New-Finding $Script:FindingLevel.Info "DiagF_ClosedBy" @(
                (Get-PartyArgument $connection.Close.By), $connection.Close.Kind, $connection.Close.ElapsedSeconds)
        }
    }

    # L'Ewon ouvre deux connexions SSH par transfert et ferme lui-même la première une fois la négociation faite :
    # vu du serveur, cela ressemble à « il se connecte puis se déconnecte » sans être une erreur.
    $first = $Connections | Select-Object -First 1
    if ($Run.Target.Protocol -eq $Script:DiagProtocol.Ssh -and $Connections.Count -ge 2 -and
        $stages[0] -eq $Script:SshStage.Encrypted -and $first.Close -and $first.Close.By -eq [EwonDiagnostics.TcpDecoder]::Client) {
        $findings += New-Finding $Script:FindingLevel.Info "DiagF_SshFirstConnection"
    }
    return $findings
}

function Get-CaptureSummaryFindings {
    param($Capture)
    $findings = @()
    foreach ($flow in [EwonDiagnostics.CaptureSummary]::TopFlows($Capture.Packets, $Script:ReportTopFlowCount)) {
        $findings += New-Finding $Script:FindingLevel.Info "DiagF_TopFlow" @($flow.Packets, $flow.Flow)
    }
    $names = @([EwonDiagnostics.DnsDecoder]::Parse($Capture.Packets) | Where-Object { -not $_.IsResponse } | ForEach-Object { $_.Name } | Select-Object -Unique)
    if ($names.Count -gt 0) { $findings += New-Finding $Script:FindingLevel.Info "DiagF_DnsNames" @($names -join ", ") }
    return $findings
}

function Get-DiagnosticFindings {
    param([Parameter(Mandatory)][hashtable]$Run, [Parameter(Mandatory)][hashtable]$Result)
    $capture = $Result.Capture
    $findings = @()
    if ($capture) {
        $findings += New-Finding $Script:FindingLevel.Info "DiagF_Capture" @($capture.FrameCount, $Run.Interface, $capture.DurationSeconds)
    } else {
        $findings += New-Finding $Script:FindingLevel.Warning "DiagF_AnalysisUnavailable" @($Result.AnalysisError)
    }
    if ($Run.Target) { $findings += Get-EwonResultFindings -Result $Result }
    if ($capture -and $Run.Target) {
        $findings += Get-TargetFindings -Run $Run -Capture $capture
    } elseif ($capture) {
        $findings += Get-CaptureSummaryFindings -Capture $capture
    }
    # Une règle sans constat renvoie $null : on ne garde que les constats réels.
    return @($findings | Where-Object { $_ })
}

function Get-TargetFindings {
    param([hashtable]$Run, $Capture)
    $target = $Run.Target
    $findings = @()
    if (Test-IPv4 $target.Host) {
        $addresses = @($target.Host)
    } else {
        $resolution = Get-DnsResolution -Messages ([EwonDiagnostics.DnsDecoder]::Parse($Capture.Packets)) -HostName $target.Host
        $findings += Get-DnsFindings -HostName $target.Host -Resolution $resolution
        $addresses = $resolution.Addresses
    }

    $connections = @([EwonDiagnostics.TcpDecoder]::GetConnections($Capture.Packets, $target.Port, [string[]]$addresses))
    if ($addresses.Count -eq 0 -and $target.Protocol -eq $Script:DiagProtocol.Tls) {
        # Adresse inconnue (DNS en cache) : pour TLS, le nom de serveur annoncé par l'Ewon désigne les connexions du test,
        # sans confondre avec un autre flux 443 (Talk2M, équipements du LAN).
        $connections = @($connections | Where-Object { [EwonDiagnostics.TlsDecoder]::Parse($_.ClientStream, $true).ServerName -eq $target.Host })
    }
    if ($connections.Count -eq 0) {
        return $findings + (New-Finding $Script:FindingLevel.Error "DiagF_NoConnection" @($target.Host, $target.Port))
    }
    return $findings + (Get-ConnectionFindings -Run $Run -Connections $connections)
}
