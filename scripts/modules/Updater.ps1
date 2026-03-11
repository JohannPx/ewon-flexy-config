# Updater.ps1 - Auto-install in AppData + silent self-update from GitHub Releases

$Script:InstallDir   = Join-Path $env:LOCALAPPDATA "EwonFlexySdPrep"
$Script:VersionFile  = Join-Path $Script:InstallDir "version.json"
$Script:ExeName      = "EwonFlexySdPrep.exe"
$Script:AppName      = "Ewon Flexy SD Preparator"
$Script:GitHubApiUrl = "https://api.github.com/repos/JohannPx/ewon-flexy-config/releases/latest"

function Get-AppVersion {
    if (Test-Path $Script:VersionFile) {
        try {
            $json = Get-Content $Script:VersionFile -Raw | ConvertFrom-Json
            return $json.version
        } catch {}
    }
    return $null
}

function Save-AppVersion([string]$Version) {
    $obj = @{ version = $Version; date = (Get-Date -Format "yyyy-MM-dd") }
    $obj | ConvertTo-Json | Out-File $Script:VersionFile -Encoding UTF8
}

function Install-AppIfNeeded {
    # Only applies when running as a compiled exe
    $currentExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if ($currentExe -notlike "*.exe") { return }

    $installedExe = Join-Path $Script:InstallDir $Script:ExeName

    # Already running from install dir
    if ($currentExe -eq $installedExe) { return }

    # First launch: copy to AppData, create shortcuts, relaunch
    if (-not (Test-Path $Script:InstallDir)) {
        New-Item -ItemType Directory -Path $Script:InstallDir -Force | Out-Null
    }
    Copy-Item -Path $currentExe -Destination $installedExe -Force

    # Create Desktop shortcut
    try {
        $shell = New-Object -ComObject WScript.Shell
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $lnk = $shell.CreateShortcut((Join-Path $desktopPath "$Script:AppName.lnk"))
        $lnk.TargetPath = $installedExe
        $lnk.WorkingDirectory = $Script:InstallDir
        $lnk.Description = $Script:AppName
        $lnk.Save()
    } catch {}

    # Create Start Menu shortcut
    try {
        $startMenu = Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs"
        if (-not (Test-Path $startMenu)) { New-Item -ItemType Directory -Path $startMenu -Force | Out-Null }
        $lnk = $shell.CreateShortcut((Join-Path $startMenu "$Script:AppName.lnk"))
        $lnk.TargetPath = $installedExe
        $lnk.WorkingDirectory = $Script:InstallDir
        $lnk.Description = $Script:AppName
        $lnk.Save()
    } catch {}

    # Initialize version.json if not present
    if (-not (Test-Path $Script:VersionFile)) {
        Save-AppVersion "0.0.0"
    }

    # Relaunch from install dir and exit
    Start-Process -FilePath $installedExe
    exit
}

function Update-AppSilently {
    # Only applies when running as a compiled exe from install dir
    $currentExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $installedExe = Join-Path $Script:InstallDir $Script:ExeName
    if ($currentExe -ne $installedExe) { return }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } catch {}

    $localVersion = Get-AppVersion
    if (-not $localVersion) { $localVersion = "0.0.0" }

    # Check GitHub for latest release
    try {
        $release = Invoke-RestMethod -Uri $Script:GitHubApiUrl -UseBasicParsing -TimeoutSec 10 `
            -Headers @{ "User-Agent" = "EwonFlexySdPrep" }
    } catch {
        # No internet or API error — continue with current version
        return
    }

    # Extract version from tag (strip leading 'v')
    $remoteTag = $release.tag_name
    $remoteVersion = $remoteTag -replace '^v', ''

    # Compare versions
    if ($remoteVersion -eq $localVersion) { return }

    # Find the .exe asset
    $exeAsset = $release.assets | Where-Object { $_.name -like "*.exe" } | Select-Object -First 1
    if (-not $exeAsset) { return }

    # Download new exe to temp
    $tempExe = Join-Path $env:TEMP "EwonFlexySdPrep_update.exe"
    try {
        Invoke-WebRequest -Uri $exeAsset.browser_download_url -OutFile $tempExe -UseBasicParsing
    } catch {
        return
    }

    # Save new version before restarting
    Save-AppVersion $remoteVersion

    # Write a batch script to replace the exe and relaunch
    $batchPath = Join-Path $env:TEMP "ewon_update.cmd"
    $batchContent = @"
@echo off
timeout /t 2 /nobreak >nul
copy /y "$tempExe" "$installedExe" >nul
start "" "$installedExe"
del "$tempExe" >nul 2>&1
del "%~f0" >nul 2>&1
"@
    [System.IO.File]::WriteAllText($batchPath, $batchContent, [System.Text.Encoding]::ASCII)

    # Launch the batch hidden and exit
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchPath`"" -WindowStyle Hidden
    exit
}
