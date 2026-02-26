# Generator.ps1 - Template processing, tar creation, T2M, procedure generation

function New-TarArchive {
    param(
        [Parameter(Mandatory)][string[]]$Files,
        [Parameter(Mandatory)][string]$OutputPath
    )

    try {
        $tarExe = Get-Command tar -ErrorAction SilentlyContinue
        if ($tarExe) {
            $tempDir = Join-Path $env:TEMP ("ewon_tar_" + (Get-Date -Format "yyyyMMddHHmmss"))
            New-Dir $tempDir | Out-Null

            foreach ($file in $Files) {
                Copy-Item -Path $file -Destination $tempDir -Force
            }

            Push-Location $tempDir
            & tar -cf $OutputPath *
            Pop-Location

            Remove-Item $tempDir -Recurse -Force
            return $true
        } else {
            # Fallback: manual tar creation
            $stream = [System.IO.FileStream]::new($OutputPath, [System.IO.FileMode]::Create)
            $writer = [System.IO.BinaryWriter]::new($stream)

            foreach ($file in $Files) {
                $fileInfo = Get-Item $file
                $fileName = $fileInfo.Name
                $fileSize = $fileInfo.Length
                $fileContent = [System.IO.File]::ReadAllBytes($file)

                $header = New-Object byte[] 512
                $nameBytes = [System.Text.Encoding]::ASCII.GetBytes($fileName)
                [Array]::Copy($nameBytes, 0, $header, 0, [Math]::Min($nameBytes.Length, 100))

                $modeBytes = [System.Text.Encoding]::ASCII.GetBytes("100644 ")
                [Array]::Copy($modeBytes, 0, $header, 100, $modeBytes.Length)

                $sizeOctal = [Convert]::ToString($fileSize, 8).PadLeft(11, '0') + ' '
                $sizeBytes = [System.Text.Encoding]::ASCII.GetBytes($sizeOctal)
                [Array]::Copy($sizeBytes, 0, $header, 124, $sizeBytes.Length)

                $writer.Write($header)
                $writer.Write($fileContent)

                $padding = 512 - ($fileSize % 512)
                if ($padding -ne 512) {
                    $writer.Write((New-Object byte[] $padding))
                }
            }

            $writer.Write((New-Object byte[] 1024))
            $writer.Close()
            $stream.Close()
            return $true
        }
    } catch {
        return $false
    }
}

function Invoke-TemplateProcessing {
    param(
        [Parameter(Mandatory)][string]$TemplatesDir,
        [Parameter(Mandatory)][string]$ConnectionType,
        [Parameter(Mandatory)][hashtable]$CollectedParams,
        [Parameter(Mandatory)][string]$OutputDir,
        [scriptblock]$OnLog = { param($msg) }
    )

    $unusedParams = Get-UnusedParams -ConnectionType $ConnectionType -CollectedParams $CollectedParams

    foreach ($templateFile in @("program.bas", "comcfg.txt", "config.txt")) {
        & $OnLog "Traitement de $templateFile..."

        $templatePath = Join-Path $TemplatesDir $templateFile
        if (-not (Test-Path $templatePath)) {
            throw "Template manquant: $templatePath"
        }

        $lines = Get-Content $templatePath
        $processedLines = @()

        foreach ($line in $lines) {
            $skipLine = $false

            foreach ($unusedParam in $unusedParams) {
                if ($line -match [regex]::Escape("{$unusedParam}")) {
                    $skipLine = $true
                    & $OnLog "  Suppression: $unusedParam"
                    break
                }
            }

            if (-not $skipLine) {
                $processedLine = $line
                foreach ($key in $CollectedParams.Keys) {
                    $placeholder = "{$key}"
                    $processedLine = $processedLine -replace [regex]::Escape($placeholder), $CollectedParams[$key]
                }
                $processedLines += $processedLine
            }
        }

        $outputPath = Join-Path $OutputDir $templateFile
        $processedLines | Out-File -FilePath $outputPath -Encoding ASCII -Force
    }
}

function Write-T2MFile {
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
    return $dest
}

function Remove-T2MFile {
    param([Parameter(Mandatory)][string]$SdRoot)
    $t2mPath = Join-Path $SdRoot "T2M.txt"
    if (Test-Path $t2mPath) {
        Remove-Item $t2mPath -Force
    }
}

function Test-SDContents {
    param(
        [Parameter(Mandatory)][string]$SdRoot,
        [Parameter(Mandatory)][hashtable]$State
    )

    $expected = @("backup.tar")
    if ($State.Mode -ne "Preparation" -and $State.ConnectionType -ne "Datalogger") {
        $expected += "T2M.txt"
    }
    if (-not $State.SkipFirmwareUpdate -and $State.TargetFirmware) {
        $cacheDir = Get-LocalCacheDir
        $targetFwDir = Join-Path (Join-Path $cacheDir "firmware") $State.TargetFirmware
        if ($State.CurrentFirmware -eq "14.x" -and (Test-Path (Join-Path $targetFwDir "ewonfwr.ebu"))) {
            $expected += @("ewonfwr.ebus", "ewonfwr.ebu")
        } else {
            $expected += "ewonfwr.ebus"
        }
    }

    $results = @()
    $allOk = $true
    foreach ($f in $expected) {
        $p = Join-Path $SdRoot $f
        $ok = Test-Path $p
        if (-not $ok) { $allOk = $false }
        $results += @{ File = $f; Found = $ok }
    }

    return @{ AllOk = $allOk; Files = $results }
}

function New-ProcedureDocument {
    param([Parameter(Mandatory)][hashtable]$State)

    $collectedParams = $State.CollectedParams
    $connectionType = $State.ConnectionType
    $skipFirmwareUpdate = $State.SkipFirmwareUpdate

    # Build parameter list (no passwords)
    $paramLines = ""
    foreach ($key in ($collectedParams.Keys | Sort-Object)) {
        if ($key -notin @("Password", "PPPClPassword1", "AccountAuthorization", "WANPxyPass")) {
            $paramLines += "- $key : $($collectedParams[$key])`n"
        }
    }

    if ($skipFirmwareUpdate) {
        $proc = @"
PROCEDURE DETAILLEE APRES PREPARATION DE LA CARTE SD
--------------------------------------------------
CONFIGURATION SANS MISE A JOUR FIRMWARE

Configuration generee dynamiquement avec les parametres suivants:
$paramLines
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
"@
    } else {
        $proc = @"
PROCEDURE DETAILLEE APRES PREPARATION DE LA CARTE SD
--------------------------------------------------

Configuration generee dynamiquement avec les parametres suivants:
$paramLines
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
"@
    }

    # Datalogger: replace remote access step
    if ($connectionType -eq "Datalogger") {
        $stepPattern = if ($skipFirmwareUpdate) { "ETAPE 3" } else { "ETAPE 4" }
        $proc = $proc -replace "$stepPattern : DEMANDE D ACCES A DISTANCE[\s\S]*?CONCLUSION", @"
$stepPattern : VERIFICATION DE LA COMMUNICATION
L'Ewon communique via son interface LAN uniquement (pas de Talk2M).
Verifiez que l'Ewon peut atteindre le serveur push.myclauger.com via le reseau local.

CONCLUSION
"@
    }

    $procPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "Procedure_Ewon.txt"
    $proc | Out-File -FilePath $procPath -Encoding ASCII
    return $procPath
}

function Invoke-Generation {
    param(
        [Parameter(Mandatory)][hashtable]$State,
        [scriptblock]$OnProgress = { param($Percent, $Message) },
        [scriptblock]$OnLog = { param($Message) }
    )

    $cacheDir = Get-LocalCacheDir
    $templatesDir = Join-Path $cacheDir "templates"
    $sdRoot = $State.SdDrive

    # Inject auto parameters
    & $OnProgress 5 "Calcul des parametres automatiques..."
    $autoParams = Get-AutoParamValues -ConnectionType $State.ConnectionType
    foreach ($key in $autoParams.Keys) {
        $State.CollectedParams[$key] = $autoParams[$key]
    }

    # PrgAutorun logic
    if ([string]::IsNullOrWhiteSpace($State.CollectedParams["AccountAuthorization"])) {
        $State.CollectedParams["PrgAutorun"] = "0"
    } else {
        $State.CollectedParams["PrgAutorun"] = "1"
    }

    # Download firmware if Online mode
    if ($State.Mode -eq "Online" -and -not $State.SkipFirmwareUpdate -and $State.TargetFirmware -and $State.Manifest) {
        & $OnProgress 10 "Telechargement firmware..."
        $fwInfo = $State.Manifest.firmwares | Where-Object { $_.version -eq $State.TargetFirmware }
        $hasEbu = [bool]$fwInfo.hasEbu
        $ok = Download-HMSFirmware -Version $State.TargetFirmware -HasEbu $hasEbu -OnLog $OnLog
        if (-not $ok) { throw "Telechargement firmware echoue." }
    }

    # Process templates
    & $OnProgress 30 "Traitement des templates..."
    $tempDir = Join-Path $env:TEMP ("ewon_config_" + (Get-Date -Format "yyyyMMddHHmmss"))
    New-Dir $tempDir | Out-Null

    try {
        Invoke-TemplateProcessing -TemplatesDir $templatesDir `
            -ConnectionType $State.ConnectionType `
            -CollectedParams $State.CollectedParams `
            -OutputDir $tempDir -OnLog $OnLog

        # Create backup.tar
        & $OnProgress 50 "Creation de backup.tar..."
        $backupTarPath = Join-Path $sdRoot "backup.tar"
        $filesToTar = Get-ChildItem $tempDir -File | Select-Object -ExpandProperty FullName
        $ok = New-TarArchive -Files $filesToTar -OutputPath $backupTarPath
        if (-not $ok) { throw "Echec de la creation de backup.tar" }
        & $OnLog "[OK] backup.tar cree"
    } finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }

    # Handle T2M for Datalogger (remove if exists)
    if ($State.ConnectionType -eq "Datalogger") {
        & $OnProgress 60 "Nettoyage T2M..."
        Remove-T2MFile -SdRoot $sdRoot
    }

    # Copy firmware
    if (-not $State.SkipFirmwareUpdate -and $State.TargetFirmware) {
        & $OnProgress 70 "Copie des firmwares..."
        Copy-FirmwareToSD -SdRoot $sdRoot -TargetFw $State.TargetFirmware `
            -CurrentFw $State.CurrentFirmware -Manifest $State.Manifest -OnLog $OnLog
    }

    # Write T2M
    if ($State.Mode -ne "Preparation" -and $State.ConnectionType -ne "Datalogger") {
        & $OnProgress 80 "Ecriture T2M.txt..."
        Write-T2MFile -SdRoot $sdRoot -T2MKey $State.T2MKey -T2MNote $State.T2MNote
        & $OnLog "[OK] T2M.txt ecrit"
    }

    # Verify
    & $OnProgress 90 "Verification des fichiers..."
    $verification = Test-SDContents -SdRoot $sdRoot -State $State
    foreach ($f in $verification.Files) {
        $status = if ($f.Found) { "[OK]" } else { "[MANQUANT]" }
        & $OnLog "$status $($f.File)"
    }
    if (-not $verification.AllOk) { throw "Fichiers manquants sur la SD." }

    # Generate procedure
    & $OnProgress 95 "Generation de la procedure..."
    $procPath = New-ProcedureDocument -State $State
    & $OnLog "[OK] Procedure: $procPath"
    try { Start-Process notepad.exe $procPath | Out-Null } catch {}

    & $OnProgress 100 "Termine !"
}
