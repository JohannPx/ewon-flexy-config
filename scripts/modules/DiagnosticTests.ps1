# DiagnosticTests.ps1 - Tests lancés par l'Ewon (connexion TCP, SFTP, HTTPS) pendant une capture, et lecture de leur résultat
#
# Le serveur web de l'Ewon est bloqué pendant toute la capture : le test est donc programmé AVANT de la lancer,
# par un minuteur BASIC qui le déclenche quelques secondes plus tard. Les secrets passent par des variables BASIC
# (jamais dans le texte de la commande programmée), vidées au nettoyage.

$Script:DiagTestKind = [ordered]@{
    CaptureOnly = "CaptureOnly"
    Tcp         = "Tcp"
    Sftp        = "Sftp"
    Https       = "Https"
}

$Script:DiagProtocol = @{ Tcp = "Tcp"; Ssh = "Ssh"; Tls = "Tls" }

# Libellés des actions dans le journal des actions planifiées de l'Ewon ($dtSS).
$Script:EwonActionType = @{
    Tcp   = "TCP/IP Connect"
    Sftp  = "SFTP Put"
    Https = "HTTP Request"
}
$Script:EwonActionSeparator = ";"

# Journal temps réel : « époque  horloge  source  numéro  message ». Il recopie aussi les commandes BASIC en erreur,
# secrets compris : seules les lignes du module SFTP en sont extraites, jamais le journal brut.
$Script:EwonLogLinePattern  = '^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s(.*)$'
$Script:EwonLogSourceSftp   = 14
$Script:EwonLogUnsafePattern = '[@$"=]'

$Script:DiagTimerNumber         = 4
$Script:DiagTestDelaySeconds    = 3
$Script:DiagTcpFileNumber       = 8
$Script:DiagResultFileNumber    = 7
$Script:DiagResultFilePath      = "/usr/ewondiag_result.txt"
$Script:DiagTcpTimeoutSeconds   = 10
$Script:DiagTestCaptureSeconds  = 30
# Noms longs pour ne pas écraser les variables du programme BASIC du client.
$Script:DiagVariable            = @{ Credentials = 'ewondiagcred$'; Headers = 'ewondiaghdr$'; Result = 'ewondiagres$' }

$Script:SftpDefaultPort         = 22
$Script:HttpsDefaultUrl         = "https://push.myclauger.com/csv.php"
$Script:SftpPasswordMinLength   = 8
$Script:SftpTestFilePrefix      = "ewondiag_"
$Script:SftpTestFileExtension   = ".txt"
$Script:SftpTestContent         = "Ewon network diagnostic"
$Script:PortMin                 = 1
$Script:PortMax                 = 65535
$Script:HostNamePattern         = '^[A-Za-z0-9.-]{1,253}$'
$Script:RemoteDirPattern        = '^[A-Za-z0-9._/-]*$'
$Script:HttpsUrlPattern         = '^https://[^\s"'']+$'
# Les valeurs sont insérées dans des chaînes BASIC : aucun guillemet n'y est toléré.
$Script:BasicQuotePattern       = '["'']'
# L'Ewon lit les commandes en Latin-1 : on s'en tient à l'ASCII imprimable pour que les identifiants arrivent intacts.
$Script:PrintableAsciiPattern   = '^[\x20-\x7E]*$'
# Séparateurs de « utilisateur:motdepasse@hôte » dans les commandes SFTP de l'Ewon.
$Script:SftpCredentialPattern   = '[@:]'
$Script:HttpSuccessRange        = @{ Min = 200; Max = 399 }
$Script:HttpAuthRejectedCodes   = @(401, 403)

function New-DiagParamDef {
    param([string]$Param, [string]$Description, [string]$Type, [string]$Default = "")
    # Même forme que les définitions de Config.ps1, attendue par New-ParamFieldRow (UIHelpers).
    return @{ Param = $Param; Description = $Description; Type = $Type; Default = $Default; Condition = $null }
}

# Paramètres demandés par test.
$Script:DiagTestParameters = @{
    CaptureOnly = @()
    Tcp         = @(
        New-DiagParamDef "DiagHost" "DiagParam_Host" "Text"
        New-DiagParamDef "DiagPort" "DiagParam_Port" "Integer"
    )
    Sftp        = @(
        New-DiagParamDef "DiagHost" "DiagParam_Host" "Text"
        New-DiagParamDef "DiagPort" "DiagParam_Port" "Integer" "$Script:SftpDefaultPort"
        New-DiagParamDef "DiagUser" "DiagParam_User" "Text"
        New-DiagParamDef "DiagSecret" "DiagParam_Password" "Password"
        New-DiagParamDef "DiagRemoteDir" "DiagParam_RemoteDir" "Text"
    )
    Https       = @(
        New-DiagParamDef "DiagUrl" "DiagParam_Url" "Text" $Script:HttpsDefaultUrl
        New-DiagParamDef "DiagUser" "DiagParam_UserOptional" "Text"
        New-DiagParamDef "DiagSecret" "DiagParam_PasswordOptional" "Password"
    )
}

function New-ValidationError {
    param([string]$Param, [string]$MessageKey)
    return @{ Param = $Param; MessageKey = $MessageKey }
}

function Test-DiagHostAndPort {
    param([hashtable]$Values)
    if ($Values.DiagHost -notmatch $Script:HostNamePattern) { return New-ValidationError "DiagHost" "DiagValHost" }
    $port = if ($Values.DiagPort -match '^\d{1,5}$') { [int]$Values.DiagPort } else { 0 }
    if ($port -lt $Script:PortMin -or $port -gt $Script:PortMax) { return New-ValidationError "DiagPort" "DiagValPort" }
    return $null
}

function Test-DiagTestParameters {
    param([Parameter(Mandatory)][string]$Kind, [hashtable]$Values)
    # Renvoie la première erreur (paramètre + clé de message), ou $null si les valeurs sont utilisables.
    foreach ($entry in $Values.GetEnumerator()) {
        if ($entry.Value -match $Script:BasicQuotePattern) { return New-ValidationError $entry.Key "DiagValQuotes" }
        if ($entry.Value -notmatch $Script:PrintableAsciiPattern) { return New-ValidationError $entry.Key "DiagValAscii" }
    }
    switch ($Kind) {
        $Script:DiagTestKind.Tcp { return Test-DiagHostAndPort $Values }
        $Script:DiagTestKind.Sftp {
            $hostError = Test-DiagHostAndPort $Values
            if ($hostError) { return $hostError }
            if (-not (Test-NotEmpty $Values.DiagUser) -or $Values.DiagUser -match $Script:SftpCredentialPattern) {
                return New-ValidationError "DiagUser" "DiagValSftpUser"
            }
            if ($Values.DiagSecret.Length -lt $Script:SftpPasswordMinLength -or $Values.DiagSecret -match $Script:SftpCredentialPattern) {
                return New-ValidationError "DiagSecret" "DiagValSftpPassword"
            }
            if ($Values.DiagRemoteDir -notmatch $Script:RemoteDirPattern) { return New-ValidationError "DiagRemoteDir" "DiagValRemoteDir" }
        }
        $Script:DiagTestKind.Https {
            if ($Values.DiagUrl -notmatch $Script:HttpsUrlPattern -or -not ([Uri]::IsWellFormedUriString($Values.DiagUrl, [UriKind]::Absolute))) {
                return New-ValidationError "DiagUrl" "DiagValUrl"
            }
            if ((Test-NotEmpty $Values.DiagUser) -ne (Test-NotEmpty $Values.DiagSecret) -or $Values.DiagUser -match ":") {
                return New-ValidationError "DiagUser" "DiagValHttpsCredentials"
            }
        }
    }
    return $null
}

function Get-DiagTestTarget {
    param([Parameter(Mandatory)][string]$Kind, [hashtable]$Values)
    switch ($Kind) {
        $Script:DiagTestKind.Tcp  { return @{ Host = $Values.DiagHost; Port = [int]$Values.DiagPort; Protocol = $Script:DiagProtocol.Tcp } }
        $Script:DiagTestKind.Sftp { return @{ Host = $Values.DiagHost; Port = [int]$Values.DiagPort; Protocol = $Script:DiagProtocol.Ssh } }
        $Script:DiagTestKind.Https {
            $uri = [Uri]$Values.DiagUrl
            return @{ Host = $uri.Host; Port = $uri.Port; Protocol = $Script:DiagProtocol.Tls }
        }
    }
    return $null
}

function Get-DiagTestScript {
    param([Parameter(Mandatory)][string]$Kind, [hashtable]$Values, [Parameter(Mandatory)][string]$SerialNumber)
    # Setup : variables (secrets compris) ; Action : commande programmée, sans secret ; Cleanup : remise à zéro.
    $credentials = $Script:DiagVariable.Credentials
    $headers = $Script:DiagVariable.Headers
    switch ($Kind) {
        $Script:DiagTestKind.Tcp {
            return @{
                Setup   = @()
                Action  = "OPEN 'tcp:$($Values.DiagHost):$($Values.DiagPort),$Script:DiagTcpTimeoutSeconds' FOR BINARY OUTPUT AS $Script:DiagTcpFileNumber"
                Cleanup = @("CLOSE $Script:DiagTcpFileNumber")
            }
        }
        $Script:DiagTestKind.Sftp {
            $directory = $Values.DiagRemoteDir.Trim("/")
            $fileName = "$Script:SftpTestFilePrefix$SerialNumber$Script:SftpTestFileExtension"
            $remotePath = if ($directory) { "$directory/$fileName" } else { $fileName }
            return @{
                Setup   = @("$credentials=`"$($Values.DiagUser):$($Values.DiagSecret)@$($Values.DiagHost):$($Values.DiagPort)`"")
                Action  = "PUTSFTP '$remotePath','$Script:SftpTestContent',$credentials"
                Cleanup = @("$credentials=`"`"")
            }
        }
        $Script:DiagTestKind.Https {
            $header = ""
            if (Test-NotEmpty $Values.DiagUser) {
                $token = [Convert]::ToBase64String($Script:EwonTextEncoding.GetBytes("$($Values.DiagUser):$($Values.DiagSecret)"))
                $header = "Authorization=Basic $token"
            }
            return @{
                Setup   = @("$headers=`"$header`"")
                Action  = "REQUESTHTTPX '$($Values.DiagUrl)','GET',$headers"
                Cleanup = @("$headers=`"`"")
            }
        }
    }
    throw "Unsupported diagnostic test '$Kind'"
}

function Get-EwonActions {
    param([Parameter(Mandatory)][hashtable]$Session)
    # Lignes « Id;"Type";Code;"Texte";"Début";"Fin" » ; l'en-tête et les lignes vides sont ignorés.
    $actions = @()
    foreach ($line in (Get-EwonExport -Session $Session -Ebd $Script:EwonExport.ScheduledActions) -split "`r?`n") {
        $fields = @($line.Split($Script:EwonActionSeparator) | ForEach-Object { $_.Trim('"') })
        if ($fields.Count -lt 4 -or $fields[0] -notmatch '^\d+$' -or $fields[2] -notmatch '^-?\d+$') { continue }
        $actions += @{ Id = [int]$fields[0]; Type = $fields[1]; Code = [int]$fields[2]; Text = $fields[3] }
    }
    return $actions
}

function Get-EwonLogEntries {
    param([Parameter(Mandatory)][hashtable]$Session)
    $entries = @()
    foreach ($line in (Get-EwonExport -Session $Session -Ebd $Script:EwonExport.RealtimeLog) -split "`r?`n") {
        if ($line -notmatch $Script:EwonLogLinePattern) { continue }
        $entries += @{ Key = "$($Matches[1]) $($Matches[2]) $($Matches[3]) $($Matches[4])"; Source = [int]$Matches[3]; Message = $Matches[5].Trim() }
    }
    return $entries
}

function Get-EwonSftpMessages {
    param([Parameter(Mandatory)][hashtable]$Session, [string[]]$KnownKeys)
    # Nouvelles lignes du module SFTP depuis le lancement du test ; toute ligne au contenu suspect est écartée.
    return @(Get-EwonLogEntries -Session $Session | Where-Object {
            $_.Source -eq $Script:EwonLogSourceSftp -and $_.Key -notin $KnownKeys -and $_.Message -notmatch $Script:EwonLogUnsafePattern
        } | ForEach-Object { $_.Message })
}

function Get-EwonHttpStatusCode {
    param([Parameter(Mandatory)][hashtable]$Session, [Parameter(Mandatory)][int]$ActionId)
    # Le code HTTP n'est lisible qu'en BASIC : on l'écrit dans un fichier /usr que l'on télécharge.
    $variable = $Script:DiagVariable.Result
    $file = $Script:DiagResultFileNumber
    try {
        Invoke-EwonScript -Session $Session -Command "SETSYS PRG,`"ACTIONID`",$ActionId"
        Invoke-EwonScript -Session $Session -Command "$variable=RESPONSEHTTPX `"STATUSCODE`""
        Invoke-EwonScript -Session $Session -Command "OPEN `"file:$Script:DiagResultFilePath`" FOR TEXT OUTPUT AS $file"
        Invoke-EwonScript -Session $Session -Command "PUT $file,$variable"
        Invoke-EwonScript -Session $Session -Command "CLOSE $file"
        $text = $Session.Encoding.GetString((Receive-EwonFile -Session $Session -Path $Script:DiagResultFilePath)).Trim().Trim('"')
        if ($text -match '^\d{3}$') { return [int]$text }
        return $null
    } finally {
        # Un fichier BASIC resté ouvert bloquerait l'effacement et les lectures suivantes jusqu'au redémarrage du BASIC.
        try { Invoke-EwonScript -Session $Session -Command "CLOSE $file" } catch {}
        try { Remove-EwonFile -Session $Session -Path $Script:DiagResultFilePath } catch {}
        try { Invoke-EwonScript -Session $Session -Command "$variable=`"`"" } catch {}
    }
}

function Invoke-DiagTestCleanup {
    param([Parameter(Mandatory)][hashtable]$Session, [string[]]$Commands)
    # Toujours exécuté, même après un échec : renvoie $false si une remise à zéro n'a pas pu être envoyée.
    $cleaned = $true
    $timerCommands = @("TSET $Script:DiagTimerNumber,0", "ONTIMER $Script:DiagTimerNumber,`"`"")
    foreach ($command in $timerCommands + $Commands) {
        try { Invoke-EwonScript -Session $Session -Command $command } catch { $cleaned = $false }
    }
    return $cleaned
}

function Start-DiagnosticRun {
    param(
        [Parameter(Mandatory)][hashtable]$Session,
        [Parameter(Mandatory)][string]$Kind,
        [hashtable]$Values,
        [Parameter(Mandatory)][hashtable]$NetworkProfile,
        [Parameter(Mandatory)][string]$Interface,
        [Parameter(Mandatory)][int]$DurationSeconds
    )
    $run = @{ Kind = $Kind; Interface = $Interface; Target = $null; Script = $null; LastActionId = 0; KnownLogKeys = @(); Capture = $null }
    # Runspace prêt avant d'armer le minuteur : il ne restera qu'à envoyer la requête TCPDump.
    $capture = New-EwonCapture -Session $Session -Interface $Interface -DurationSeconds $DurationSeconds
    try {
        if ($Kind -ne $Script:DiagTestKind.CaptureOnly) {
            $run.Target = Get-DiagTestTarget -Kind $Kind -Values $Values
            $run.Script = Get-DiagTestScript -Kind $Kind -Values $Values -SerialNumber $NetworkProfile.SerialNumber
            if ($Kind -eq $Script:DiagTestKind.Sftp) { $run.KnownLogKeys = @(Get-EwonLogEntries -Session $Session | ForEach-Object { $_.Key }) }
            foreach ($command in $run.Script.Setup) { Invoke-EwonScript -Session $Session -Command $command }
            # Le résultat du test sera la première action de son type apparue après celle-ci (relevée au dernier moment).
            $actionIds = @(Get-EwonActions -Session $Session | ForEach-Object { $_.Id })
            if ($actionIds.Count -gt 0) { $run.LastActionId = [int]($actionIds | Measure-Object -Maximum).Maximum }
            Invoke-EwonScript -Session $Session -Command "ONTIMER $Script:DiagTimerNumber,`"TSET $Script:DiagTimerNumber,0:$($run.Script.Action)`""
            Invoke-EwonScript -Session $Session -Command "TSET $Script:DiagTimerNumber,$Script:DiagTestDelaySeconds"
        }
        Start-EwonCapture -Capture $capture
    } catch {
        if ($run.Script) { $null = Invoke-DiagTestCleanup -Session $Session -Commands $run.Script.Cleanup }
        Stop-EwonCapture -Capture $capture
        throw
    }
    $run.Capture = $capture
    return $run
}

function Read-DiagTestOutcome {
    param([hashtable]$Session, [hashtable]$Run, [hashtable]$Result)
    $expectedType = $Script:EwonActionType[$Run.Kind]
    $matching = @(Get-EwonActions -Session $Session | Where-Object { $_.Id -gt $Run.LastActionId -and $_.Type -eq $expectedType })
    $Result.ActionCount = $matching.Count
    $Result.Action = $matching | Select-Object -First 1
    if ($Run.Kind -eq $Script:DiagTestKind.Https -and $Result.Action -and $Result.Action.Code -eq 0) {
        $Result.HttpStatus = Get-EwonHttpStatusCode -Session $Session -ActionId $Result.Action.Id
    }
    if ($Run.Kind -eq $Script:DiagTestKind.Sftp) {
        $Result.EwonMessages = Get-EwonSftpMessages -Session $Session -KnownKeys $Run.KnownLogKeys
    }
}

function Complete-DiagnosticRun {
    param([Parameter(Mandatory)][hashtable]$Session, [Parameter(Mandatory)][hashtable]$Run, [scriptblock]$OnStep = {})

    $result = @{
        Bytes = $null; Capture = $null; AnalysisError = $null
        Action = $null; ActionCount = 0; HttpStatus = $null; EwonMessages = @(); EwonResultError = $null
        Cleaned = $true
    }
    try {
        $result.Bytes = Complete-EwonCapture -Session $Session -Capture $Run.Capture
    } finally {
        if ($Run.Script) { $result.Cleaned = Invoke-DiagTestCleanup -Session $Session -Commands $Run.Script.Cleanup }
    }
    & $OnStep
    # Les octets sont rapatriés : l'Ewon n'a plus à garder la capture.
    $result.Cleaned = (Clear-EwonCapture -Session $Session) -and $result.Cleaned
    & $OnStep

    # Une fois la capture en main, aucune étape suivante ne doit la faire perdre : chaque échec devient un constat.
    try { $result.Capture = Read-PcapCapture -Bytes $result.Bytes } catch { $result.AnalysisError = $_.Exception }
    & $OnStep
    if ($Run.Script) {
        try { Read-DiagTestOutcome -Session $Session -Run $Run -Result $result } catch { $result.EwonResultError = $_.Exception }
    }
    return $result
}
