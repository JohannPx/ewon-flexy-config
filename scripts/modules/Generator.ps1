# Generator.ps1 - Template processing, tar creation, T2M, procedure generation

function New-TarArchive {
    param(
        [Parameter(Mandatory)][string[]]$Files,
        [Parameter(Mandatory)][string]$OutputPath
    )

    try {
        # Prepare temp directory with copies of the files
        $tempDir = Join-Path $env:TEMP ("ewon_tar_" + (Get-Date -Format "yyyyMMddHHmmss"))
        New-Dir $tempDir | Out-Null

        foreach ($file in $Files) {
            Copy-Item -Path $file -Destination $tempDir -Force
        }

        $tarOk = $false
        $tarExe = Get-Command tar -ErrorAction SilentlyContinue
        if ($tarExe) {
            # Use -C to avoid Push-Location/glob issues; redirect stderr to prevent
            # $ErrorActionPreference='Stop' from throwing on tar warnings
            $fileNames = @(Get-ChildItem $tempDir -File | ForEach-Object { $_.Name })
            $tarArgs = @("-cf", $OutputPath, "-C", $tempDir) + $fileNames
            $null = & tar @tarArgs 2>&1
            if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputPath)) {
                $tarOk = $true
            }
        }

        if (-not $tarOk) {
            # Fallback: manual tar creation with proper POSIX headers
            $stream = [System.IO.FileStream]::new($OutputPath, [System.IO.FileMode]::Create)
            $writer = [System.IO.BinaryWriter]::new($stream)

            foreach ($file in (Get-ChildItem $tempDir -File)) {
                $fileName = $file.Name
                $fileSize = $file.Length
                $fileContent = [System.IO.File]::ReadAllBytes($file.FullName)

                # Build 512-byte tar header
                $header = New-Object byte[] 512

                # Name (offset 0, 100 bytes)
                $nameBytes = [System.Text.Encoding]::ASCII.GetBytes($fileName)
                [Array]::Copy($nameBytes, 0, $header, 0, [Math]::Min($nameBytes.Length, 100))

                # Mode (offset 100, 8 bytes) - "0100644\0"
                $modeStr = "0100644" + [char]0
                $modeBytes = [System.Text.Encoding]::ASCII.GetBytes($modeStr)
                [Array]::Copy($modeBytes, 0, $header, 100, [Math]::Min($modeBytes.Length, 8))

                # UID (offset 108, 8 bytes) - "0000000\0"
                $uidStr = "0000000" + [char]0
                $uidBytes = [System.Text.Encoding]::ASCII.GetBytes($uidStr)
                [Array]::Copy($uidBytes, 0, $header, 108, [Math]::Min($uidBytes.Length, 8))

                # GID (offset 116, 8 bytes) - "0000000\0"
                [Array]::Copy($uidBytes, 0, $header, 116, [Math]::Min($uidBytes.Length, 8))

                # Size (offset 124, 12 bytes) - octal, null-terminated
                $sizeOctal = [Convert]::ToString($fileSize, 8).PadLeft(11, '0') + [char]0
                $sizeBytes = [System.Text.Encoding]::ASCII.GetBytes($sizeOctal)
                [Array]::Copy($sizeBytes, 0, $header, 124, [Math]::Min($sizeBytes.Length, 12))

                # Mtime (offset 136, 12 bytes) - seconds since epoch
                $epoch = [DateTimeOffset]::new($file.LastWriteTimeUtc).ToUnixTimeSeconds()
                $mtimeOctal = [Convert]::ToString($epoch, 8).PadLeft(11, '0') + [char]0
                $mtimeBytes = [System.Text.Encoding]::ASCII.GetBytes($mtimeOctal)
                [Array]::Copy($mtimeBytes, 0, $header, 136, [Math]::Min($mtimeBytes.Length, 12))

                # Typeflag (offset 156, 1 byte) - '0' = regular file
                $header[156] = [byte][char]'0'

                # Checksum (offset 148, 8 bytes) - compute with spaces in checksum field
                # Fill checksum field with spaces for computation
                for ($i = 148; $i -lt 156; $i++) { $header[$i] = 32 }
                $checksum = 0
                for ($i = 0; $i -lt 512; $i++) { $checksum += $header[$i] }
                $chkStr = [Convert]::ToString($checksum, 8).PadLeft(6, '0') + [char]0 + " "
                $chkBytes = [System.Text.Encoding]::ASCII.GetBytes($chkStr)
                [Array]::Copy($chkBytes, 0, $header, 148, [Math]::Min($chkBytes.Length, 8))

                $writer.Write($header)
                $writer.Write($fileContent)

                # Pad to 512-byte boundary
                $remainder = $fileSize % 512
                if ($remainder -ne 0) {
                    $writer.Write((New-Object byte[] (512 - $remainder)))
                }
            }

            # End-of-archive marker: two 512-byte zero blocks
            $writer.Write((New-Object byte[] 1024))
            $writer.Close()
            $stream.Close()
        }

        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        return (Test-Path $OutputPath)
    } catch {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
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
        & $OnLog ((T "GenProcessing") -f $templateFile)

        $templatePath = Join-Path $TemplatesDir $templateFile
        if (-not (Test-Path $templatePath)) {
            throw ((T "GenTemplateMissing") -f $templatePath)
        }

        $lines = Get-Content $templatePath
        $processedLines = @()

        foreach ($line in $lines) {
            $skipLine = $false

            foreach ($unusedParam in $unusedParams) {
                if ($line -match [regex]::Escape("{$unusedParam}")) {
                    $skipLine = $true
                    & $OnLog ((T "GenRemoving") -f $unusedParam)
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

    $sb = New-Object System.Text.StringBuilder

    # Title
    [void]$sb.AppendLine((T "Proc_Title"))
    [void]$sb.AppendLine((T "Proc_Separator"))

    if ($skipFirmwareUpdate) {
        [void]$sb.AppendLine((T "Proc_NoFwUpdate"))
    }
    [void]$sb.AppendLine("")

    # Parameter list (no passwords)
    [void]$sb.AppendLine((T "Proc_Intro"))
    foreach ($key in ($collectedParams.Keys | Sort-Object)) {
        if ($key -notin @("Password", "PPPClPassword1", "AccountAuthorization", "WANPxyPass")) {
            [void]$sb.AppendLine("- $key : $($collectedParams[$key])")
        }
    }
    [void]$sb.AppendLine("")

    # Step 1: Preparation (always)
    [void]$sb.AppendLine((T "Proc_Step1Title"))
    [void]$sb.AppendLine((T "Proc_Step1_1"))
    [void]$sb.AppendLine((T "Proc_Step1_2"))
    [void]$sb.AppendLine((T "Proc_Step1_3"))
    [void]$sb.AppendLine("")

    if ($skipFirmwareUpdate) {
        # No firmware update: single insertion
        [void]$sb.AppendLine((T "Proc_Step2NoFwTitle"))
        [void]$sb.AppendLine((T "Proc_Step2NoFw_1"))
        [void]$sb.AppendLine((T "Proc_Step2NoFw_2"))
        [void]$sb.AppendLine((T "Proc_Step2NoFw_3"))
        [void]$sb.AppendLine((T "Proc_Step2NoFw_4"))
        [void]$sb.AppendLine((T "Proc_Step2NoFw_5"))
        [void]$sb.AppendLine("")

        # Remote access or Datalogger verification
        if ($connectionType -eq "Datalogger") {
            [void]$sb.AppendLine(("{0}3 : {1}" -f (T "Proc_Step1Title").Split(" ")[0], (T "Proc_DLTitle")))
            [void]$sb.AppendLine((T "Proc_DLText"))
        } else {
            [void]$sb.AppendLine(("{0}3 : {1}" -f (T "Proc_Step1Title").Split(" ")[0], (T "Proc_RemoteTitle")))
            [void]$sb.AppendLine((T "Proc_Remote_Intro"))
            [void]$sb.AppendLine((T "Proc_Remote_1"))
            [void]$sb.AppendLine((T "Proc_Remote_2"))
            [void]$sb.AppendLine((T "Proc_Remote_3"))
            [void]$sb.AppendLine((T "Proc_Remote_4"))
        }
    } else {
        # With firmware update: two insertions
        [void]$sb.AppendLine((T "Proc_Step2FwTitle"))
        [void]$sb.AppendLine((T "Proc_Step2Fw_1"))
        [void]$sb.AppendLine((T "Proc_Step2Fw_2"))
        [void]$sb.AppendLine((T "Proc_Step2Fw_3"))
        [void]$sb.AppendLine((T "Proc_Step2Fw_4"))
        [void]$sb.AppendLine((T "Proc_Step2Fw_5"))
        [void]$sb.AppendLine("")

        [void]$sb.AppendLine((T "Proc_Step3FwTitle"))
        [void]$sb.AppendLine((T "Proc_Step3Fw_1"))
        [void]$sb.AppendLine((T "Proc_Step3Fw_2"))
        [void]$sb.AppendLine((T "Proc_Step3Fw_3"))
        [void]$sb.AppendLine((T "Proc_Step3Fw_4"))
        [void]$sb.AppendLine((T "Proc_Step3Fw_5"))
        [void]$sb.AppendLine("")

        # Remote access or Datalogger verification
        if ($connectionType -eq "Datalogger") {
            [void]$sb.AppendLine(("{0}4 : {1}" -f (T "Proc_Step1Title").Split(" ")[0], (T "Proc_DLTitle")))
            [void]$sb.AppendLine((T "Proc_DLText"))
        } else {
            [void]$sb.AppendLine(("{0}4 : {1}" -f (T "Proc_Step1Title").Split(" ")[0], (T "Proc_RemoteTitle")))
            [void]$sb.AppendLine((T "Proc_Remote_Intro"))
            [void]$sb.AppendLine((T "Proc_Remote_1"))
            [void]$sb.AppendLine((T "Proc_Remote_2"))
            [void]$sb.AppendLine((T "Proc_Remote_3"))
            [void]$sb.AppendLine((T "Proc_Remote_4"))
        }
    }

    [void]$sb.AppendLine("")
    [void]$sb.AppendLine((T "Proc_Conclusion"))
    if ($skipFirmwareUpdate) {
        [void]$sb.AppendLine((T "Proc_ConclusionNoFw"))
    } else {
        [void]$sb.AppendLine((T "Proc_ConclusionFw"))
    }

    $proc = $sb.ToString()

    $procPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "Procedure_Ewon.txt"
    $proc | Out-File -FilePath $procPath -Encoding UTF8
    return @{ Path = $procPath; Text = $proc }
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
    & $OnProgress 5 (T "GenAutoParams")
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
        & $OnProgress 10 ((T "FwDownloading") -f $State.TargetFirmware)
        $fwInfo = $State.Manifest.firmwares | Where-Object { $_.version -eq $State.TargetFirmware }
        $hasEbu = [bool]$fwInfo.hasEbu
        $ok = Download-HMSFirmware -Version $State.TargetFirmware -HasEbu $hasEbu -OnLog $OnLog
        if (-not $ok) { throw (T "GenFwDownloadFail") }
    }

    # Process templates
    & $OnProgress 30 ((T "GenProcessing") -f "templates")
    $tempDir = Join-Path $env:TEMP ("ewon_config_" + (Get-Date -Format "yyyyMMddHHmmss"))
    New-Dir $tempDir | Out-Null

    try {
        Invoke-TemplateProcessing -TemplatesDir $templatesDir `
            -ConnectionType $State.ConnectionType `
            -CollectedParams $State.CollectedParams `
            -OutputDir $tempDir -OnLog $OnLog

        # Create backup.tar
        & $OnProgress 50 ((T "GenProcessing") -f "backup.tar")
        $backupTarPath = Join-Path $sdRoot "backup.tar"
        $filesToTar = Get-ChildItem $tempDir -File | Select-Object -ExpandProperty FullName
        $ok = New-TarArchive -Files $filesToTar -OutputPath $backupTarPath
        if (-not $ok) { throw (T "GenTarFail") }
        & $OnLog (T "GenTarOk")
    } finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }

    # Handle T2M for Datalogger (remove if exists)
    if ($State.ConnectionType -eq "Datalogger") {
        & $OnProgress 60 (T "GenT2MCleanup")
        Remove-T2MFile -SdRoot $sdRoot
    }

    # Copy firmware
    if (-not $State.SkipFirmwareUpdate -and $State.TargetFirmware) {
        & $OnProgress 70 (T "GenFwCopy")
        Copy-FirmwareToSD -SdRoot $sdRoot -TargetFw $State.TargetFirmware `
            -CurrentFw $State.CurrentFirmware -Manifest $State.Manifest -OnLog $OnLog
    }

    # Write T2M
    if ($State.Mode -ne "Preparation" -and $State.ConnectionType -ne "Datalogger") {
        & $OnProgress 80 (T "GenT2MWrite")
        Write-T2MFile -SdRoot $sdRoot -T2MKey $State.T2MKey -T2MNote $State.T2MNote
        & $OnLog (T "GenT2MOk")
    }

    # Verify
    & $OnProgress 90 (T "GenVerify")
    $verification = Test-SDContents -SdRoot $sdRoot -State $State
    foreach ($f in $verification.Files) {
        $status = if ($f.Found) { T "GenFileOk" } else { T "GenFileMissing" }
        & $OnLog "$status $($f.File)"
    }
    if (-not $verification.AllOk) { throw (T "GenFilesMissing") }

    # Generate procedure
    & $OnProgress 95 (T "GenProcGen")
    $procResult = New-ProcedureDocument -State $State
    & $OnLog ((T "GenProcSaved") -f $procResult.Path)
    Set-AppStateValue -Key "ProcedureText" -Value $procResult.Text

    & $OnProgress 100 (T "GenDone")
}
