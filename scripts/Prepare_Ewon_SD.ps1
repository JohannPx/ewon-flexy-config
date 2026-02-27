# PowerShell Script: Prepare Ewon Flexy SD card with dynamic backup.tar generation
# Version: 5.0.0 - WPF GUI
# Author: JPR
# Date: 2025-09-22

# =================== GENERAL SETTINGS ===================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Console UTF-8
try { chcp 65001 > $null } catch {}
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# STA check (WPF requires STA thread)
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process powershell.exe -ArgumentList "-Sta -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -NoNewWindow -Wait
    exit
}

# Show startup message before hiding console
Write-Host ""
Write-Host "  Ewon Flexy SD Card Preparation Tool" -ForegroundColor Cyan
Write-Host "  Loading GUI, please wait..." -ForegroundColor Gray
Write-Host ""

# Brief pause so the user can read the startup message
Start-Sleep -Seconds 2

# Hide the console window (only the WPF GUI will be visible)
Add-Type -Name Win32 -Namespace Native -MemberDefinition @'
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
$consoleHwnd = [Native.Win32]::GetConsoleWindow()
if ($consoleHwnd -ne [IntPtr]::Zero) {
    [Native.Win32]::ShowWindow($consoleHwnd, 0) | Out-Null  # 0 = SW_HIDE
}

# =================== MODULE LOADING ===================
# In development mode, modules are in a subfolder.
# In release mode (concatenated), functions are already defined above this point.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesDir = Join-Path $ScriptDir "modules"

if (Test-Path $modulesDir) {
    $moduleOrder = @(
        "AppState.ps1"
        "Localization.ps1"
        "Validation.ps1"
        "Config.ps1"
        "Network.ps1"
        "Firmware.ps1"
        "Generator.ps1"
        "UIHelpers.ps1"
        "UI.ps1"
    )
    foreach ($mod in $moduleOrder) {
        $modPath = Join-Path $modulesDir $mod
        if (Test-Path $modPath) {
            . $modPath
        }
    }
}

# =================== LOAD WPF ASSEMBLIES ===================
# PresentationFramework is loaded by Initialize-MainWindow

# =================== LAUNCH ===================
try {
    $window = Initialize-MainWindow
    Show-WizardStep -StepIndex 0
    $window.ShowDialog() | Out-Null
} catch {
    $errMsg = $_.Exception.Message
    $inner = $_.Exception.InnerException
    while ($inner) {
        $errMsg += "`n-> $($inner.Message)"
        $inner = $inner.InnerException
    }
    try {
        [System.Windows.MessageBox]::Show(
            "$((T 'DlgError')): $errMsg`n`n$($_.ScriptStackTrace)",
            (T "DlgError"), "OK", "Error")
    } catch {
        Write-Host "$((T 'DlgError')): $errMsg" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace
    }
}
