# EwonClient.ps1 - Accès HTTP à un Ewon Flexy par son LAN (exports, BASIC, TCPDump, fichiers /usr)

$Script:EwonHttpPort              = 80
$Script:EwonHttpTimeoutMs         = 10000
# Au-delà de ~255 caractères, une chaîne littérale dans une commande BASIC fait redémarrer l'Ewon.
$Script:EwonBasicLiteralMaxLength = 200
# L'Ewon décode le texte en Latin-1, comme l'outil HMS d'origine.
$Script:EwonTextEncoding          = [System.Text.Encoding]::GetEncoding(28591)

$Script:EwonErrorKind = @{
    Unreachable    = "Unreachable"
    AuthRejected   = "AuthRejected"
    NotFound       = "NotFound"
    HttpError      = "HttpError"
    ScriptRejected = "ScriptRejected"
}

$Script:EwonExport = @{
    Status = '$dtES$ftT'
}

function New-EwonException {
    param([Parameter(Mandatory)][string]$Kind, [string]$Detail = "")
    # La catégorie voyage dans Data : l'interface la traduit, le détail reste brut.
    $exception = [System.Exception]::new($Detail)
    $exception.Data["EwonErrorKind"] = $Kind
    return $exception
}

function New-EwonSession {
    param(
        [Parameter(Mandatory)][string]$Ip,
        [Parameter(Mandatory)][string]$User,
        [Parameter(Mandatory)][string]$Password
    )
    $token = [Convert]::ToBase64String($Script:EwonTextEncoding.GetBytes("${User}:$Password"))
    return @{ Ip = $Ip; Port = $Script:EwonHttpPort; Encoding = $Script:EwonTextEncoding; Authorization = "Basic $token" }
}

function Find-WebException {
    param([System.Exception]$Exception)
    # Les appels .NET arrivent enveloppés (MethodInvocationException) : on cherche la WebException d'origine.
    for ($current = $Exception; $current; $current = $current.InnerException) {
        if ($current -is [System.Net.WebException]) { return $current }
    }
    return $null
}

function Invoke-EwonRequest {
    param(
        [Parameter(Mandatory)][hashtable]$Session,
        [Parameter(Mandatory)][string]$PathAndQuery
    )
    $request = [System.Net.HttpWebRequest]::Create("http://$($Session.Ip):$($Session.Port)$PathAndQuery")
    $request.Headers["Authorization"] = $Session.Authorization
    $request.Timeout = $Script:EwonHttpTimeoutMs
    $request.ReadWriteTimeout = $Script:EwonHttpTimeoutMs

    try {
        $response = $request.GetResponse()
    } catch {
        $webError = Find-WebException $_.Exception
        if (-not $webError) { throw }
        $httpResponse = $webError.Response -as [System.Net.HttpWebResponse]
        if (-not $httpResponse) {
            throw (New-EwonException -Kind $Script:EwonErrorKind.Unreachable -Detail $webError.Message)
        }
        # La réponse d'erreur garde sa connexion tant qu'elle n'est pas fermée (2 connexions max par hôte).
        try { $statusCode = [int]$httpResponse.StatusCode } finally { $httpResponse.Close() }
        switch ($statusCode) {
            401     { throw (New-EwonException -Kind $Script:EwonErrorKind.AuthRejected) }
            404     { throw (New-EwonException -Kind $Script:EwonErrorKind.NotFound -Detail $PathAndQuery) }
            default { throw (New-EwonException -Kind $Script:EwonErrorKind.HttpError -Detail $webError.Message) }
        }
    }

    try {
        $body = New-Object System.IO.MemoryStream
        $response.GetResponseStream().CopyTo($body)
        return , $body.ToArray()
    } finally {
        $response.Close()
    }
}

function Get-EwonExport {
    param([Parameter(Mandatory)][hashtable]$Session, [Parameter(Mandatory)][string]$Ebd)
    $bytes = Invoke-EwonRequest -Session $Session -PathAndQuery ("/rcgi.bin/ParamForm?AST_Param=" + [Uri]::EscapeDataString($Ebd))
    return $Session.Encoding.GetString($bytes)
}

function Get-EwonStatus {
    param([Parameter(Mandatory)][hashtable]$Session)
    # Lignes « Clé:Valeur » ; certaines clés sont répétées, la première occurrence fait foi.
    $status = @{}
    foreach ($line in (Get-EwonExport -Session $Session -Ebd $Script:EwonExport.Status) -split "`r?`n") {
        $separator = $line.IndexOf(":")
        if ($separator -le 0) { continue }
        $key = $line.Substring(0, $separator)
        if (-not $status.ContainsKey($key)) { $status[$key] = $line.Substring($separator + 1).Trim() }
    }
    return $status
}

function Assert-EwonScriptSafe {
    param([Parameter(Mandatory)][string]$Command)
    foreach ($literal in [regex]::Matches($Command, '"[^"]*"|''[^'']*''')) {
        if ($literal.Length - 2 -gt $Script:EwonBasicLiteralMaxLength) {
            throw (New-EwonException -Kind $Script:EwonErrorKind.ScriptRejected -Detail "literal > $($Script:EwonBasicLiteralMaxLength)")
        }
    }
}

function Invoke-EwonScript {
    param([Parameter(Mandatory)][hashtable]$Session, [Parameter(Mandatory)][string]$Command)
    Assert-EwonScriptSafe -Command $Command
    # Double encodage obligatoire : en simple encodage, « # », « & » et « + » tronquent la commande.
    $encoded = [Uri]::EscapeDataString([Uri]::EscapeDataString($Command))
    $null = Invoke-EwonRequest -Session $Session -PathAndQuery "/rcgi.bin/ExeScriptForm?Command=$encoded"
}

function Receive-EwonFile {
    param([Parameter(Mandatory)][hashtable]$Session, [Parameter(Mandatory)][string]$Path)
    return , (Invoke-EwonRequest -Session $Session -PathAndQuery $Path)
}

function Remove-EwonFile {
    param([Parameter(Mandatory)][hashtable]$Session, [Parameter(Mandatory)][string]$Path)
    Invoke-EwonScript -Session $Session -Command "ERASE `"$Path`""
}

function Invoke-EwonTcpDump {
    param(
        [Parameter(Mandatory)][hashtable]$Session,
        [Parameter(Mandatory)][string]$Interface,
        [Parameter(Mandatory)][int]$DurationSeconds,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][int]$ReplyMarginSeconds
    )
    # Autonome (aucune variable de script) : exécutée dans un runspace d'arrière-plan.
    # TCPDump ne répond pas en HTTP valide, d'où le socket brut ; « -i » doit être collé au nom d'interface.
    $query = "/rcgi.bin/TCPDump?Args=-i$Interface&Timeout=$DurationSeconds&Output=$OutputPath"
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $client.Connect($Session.Ip, $Session.Port)
        $client.ReceiveTimeout = ($DurationSeconds + $ReplyMarginSeconds) * 1000
        $stream = $client.GetStream()
        $request = "GET $query HTTP/1.1`r`nHost: $($Session.Ip)`r`nAuthorization: $($Session.Authorization)`r`nConnection: close`r`n`r`n"
        $requestBytes = [System.Text.Encoding]::ASCII.GetBytes($request)
        $stream.Write($requestBytes, 0, $requestBytes.Length)

        $reply = New-Object System.IO.MemoryStream
        $buffer = New-Object byte[] 4096
        try {
            while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) { $reply.Write($buffer, 0, $read) }
        } catch [System.IO.IOException] {
            # Délai de lecture dépassé : on juge sur ce qui a été reçu.
        }
        return @{
            Reply          = $Session.Encoding.GetString($reply.ToArray())
            ElapsedSeconds = $watch.Elapsed.TotalSeconds
        }
    } finally {
        $client.Close()
    }
}
