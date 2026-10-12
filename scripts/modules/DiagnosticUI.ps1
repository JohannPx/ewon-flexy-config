# DiagnosticUI.ps1 - Fenêtre de diagnostic réseau : connexion à l'Ewon par son LAN, test lancé par l'Ewon
# pendant une capture, rapport de diagnostic et enregistrement du pcap

$Script:DiagDefaultIp      = "192.168.253.254"
$Script:DiagDefaultUser    = "adm"
$Script:DiagPollIntervalMs = 500
$Script:FindingSymbol      = @{ Ok = "[OK]"; Info = "[i] "; Warning = "[!] "; Error = "[X] " }
$Script:Diag               = $null

$Script:DiagXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="1040" Height="800" MinWidth="900" MinHeight="600"
        WindowStartupLocation="CenterOwner" ShowInTaskbar="False"
        UseLayoutRounding="True" SnapsToDevicePixels="True" Background="#FAFAFA">
  <Window.Resources>
    <Style x:Key="SectionHeader" TargetType="TextBlock">
      <Setter Property="FontSize" Value="15"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Margin" Value="0,4,0,8"/>
      <Setter Property="Foreground" Value="#1A5276"/>
    </Style>
    <Style x:Key="FieldLabel" TargetType="TextBlock">
      <Setter Property="VerticalAlignment" Value="Center"/>
      <Setter Property="FontSize" Value="12"/>
    </Style>
    <Style x:Key="ActionBtn" TargetType="Button">
      <Setter Property="MinWidth" Value="160"/>
      <Setter Property="Height" Value="30"/>
      <Setter Property="Padding" Value="10,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="HorizontalAlignment" Value="Left"/>
    </Style>
  </Window.Resources>

  <DockPanel Margin="16">
    <DockPanel DockPanel.Dock="Bottom" Margin="0,10,0,0">
      <Button x:Name="btnDiagClose" DockPanel.Dock="Right" MinWidth="110" Height="32" Cursor="Hand"/>
      <Control/>
    </DockPanel>

    <Grid>
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="380"/>
        <ColumnDefinition Width="20"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <ScrollViewer Grid.Column="0" VerticalScrollBarVisibility="Auto">
        <StackPanel>
          <TextBlock x:Name="txtDiagEwonSection" Style="{StaticResource SectionHeader}"/>
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="140"/>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="30"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
              <RowDefinition Height="36"/>
              <RowDefinition Height="36"/>
              <RowDefinition Height="36"/>
            </Grid.RowDefinitions>
            <TextBlock x:Name="txtDiagIpLabel" Style="{StaticResource FieldLabel}" Grid.Row="0"/>
            <TextBox x:Name="tbDiagIp" Grid.Row="0" Grid.Column="1" Height="28" Margin="5,0" VerticalContentAlignment="Center"/>
            <TextBlock x:Name="txtDiagUserLabel" Style="{StaticResource FieldLabel}" Grid.Row="1"/>
            <TextBox x:Name="tbDiagUser" Grid.Row="1" Grid.Column="1" Height="28" Margin="5,0" VerticalContentAlignment="Center"/>
            <TextBlock x:Name="txtDiagPasswordLabel" Style="{StaticResource FieldLabel}" Grid.Row="2"/>
            <PasswordBox x:Name="pbDiagPassword" Grid.Row="2" Grid.Column="1" Height="28" Margin="5,0" VerticalContentAlignment="Center"/>
          </Grid>
          <Button x:Name="btnDiagConnect" Style="{StaticResource ActionBtn}" Margin="0,8,0,0"
                  Background="#1A5276" Foreground="White"/>
          <TextBlock x:Name="txtDiagEwonInfo" FontSize="12" Margin="0,8,0,0" TextWrapping="Wrap" Foreground="#333"/>

          <Separator Margin="0,12"/>

          <StackPanel x:Name="pnlDiagRun" IsEnabled="False">
            <TextBlock x:Name="txtDiagRunSection" Style="{StaticResource SectionHeader}"/>
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="140"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="30"/>
              </Grid.ColumnDefinitions>
              <Grid.RowDefinitions>
                <RowDefinition Height="36"/>
                <RowDefinition Height="36"/>
                <RowDefinition Height="36"/>
              </Grid.RowDefinitions>
              <TextBlock x:Name="txtDiagTestLabel" Style="{StaticResource FieldLabel}" Grid.Row="0"/>
              <ComboBox x:Name="cbDiagTest" Grid.Row="0" Grid.Column="1" Height="28" Margin="5,0"/>
              <TextBlock x:Name="txtDiagInterfaceLabel" Style="{StaticResource FieldLabel}" Grid.Row="1"/>
              <ComboBox x:Name="cbDiagInterface" Grid.Row="1" Grid.Column="1" Height="28" Margin="5,0"/>
              <TextBlock x:Name="txtDiagDurationLabel" Style="{StaticResource FieldLabel}" Grid.Row="2"/>
              <TextBox x:Name="tbDiagDuration" Grid.Row="2" Grid.Column="1" Height="28" Margin="5,0" VerticalContentAlignment="Center"/>
            </Grid>
            <StackPanel x:Name="pnlDiagTestParams"/>
            <TextBlock x:Name="txtDiagHint" FontSize="11" Foreground="#666" Margin="0,6,0,0" TextWrapping="Wrap"/>
            <Button x:Name="btnDiagStart" Style="{StaticResource ActionBtn}" Margin="0,10,0,0"
                    Background="#1A5276" Foreground="White"/>
          </StackPanel>
          <ProgressBar x:Name="pbDiagCapture" Height="16" Margin="0,12,0,0" Foreground="#27AE60" Minimum="0" Maximum="100"/>
          <TextBlock x:Name="txtDiagCaptureStatus" FontSize="12" Margin="0,4,0,0" TextWrapping="Wrap"/>
        </StackPanel>
      </ScrollViewer>

      <Grid Grid.Column="2">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="120"/>
        </Grid.RowDefinitions>
        <DockPanel Grid.Row="0">
          <Button x:Name="btnDiagSaveCapture" DockPanel.Dock="Right" Height="28" Padding="10,0" Cursor="Hand" IsEnabled="False"/>
          <TextBlock x:Name="txtDiagReportTitle" Style="{StaticResource SectionHeader}"/>
        </DockPanel>
        <TextBox x:Name="tbDiagReport" Grid.Row="1" IsReadOnly="True" TextWrapping="Wrap"
                 VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11.5" Padding="6"/>
        <ListBox x:Name="lbDiagLog" Grid.Row="2" FontFamily="Consolas" FontSize="11" Margin="0,8,0,0"
                 Background="#1E1E1E" Foreground="#D4D4D4" BorderThickness="0"/>
      </Grid>
    </Grid>
  </DockPanel>
</Window>
'@

function Show-NetworkDiagnosticWindow {
    param([Parameter(Mandatory)][System.Windows.Window]$Owner)

    [xml]$xaml = $Script:DiagXaml
    $window = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
    $window.Owner = $Owner
    $window.Icon = $Owner.Icon

    $Script:Diag = @{
        Window = $window; Session = $null; NetworkProfile = $null; Run = $null; TestFields = @{}
        CaptureBytes = $null; CaptureFileName = $null; CaptureSaved = $false
    }
    foreach ($name in @(
            "btnDiagClose", "txtDiagEwonSection", "txtDiagIpLabel", "tbDiagIp", "txtDiagUserLabel", "tbDiagUser",
            "txtDiagPasswordLabel", "pbDiagPassword", "btnDiagConnect", "txtDiagEwonInfo", "pnlDiagRun",
            "txtDiagRunSection", "txtDiagTestLabel", "cbDiagTest", "txtDiagInterfaceLabel", "cbDiagInterface",
            "txtDiagDurationLabel", "tbDiagDuration", "pnlDiagTestParams", "txtDiagHint", "btnDiagStart",
            "pbDiagCapture", "txtDiagCaptureStatus", "btnDiagSaveCapture", "txtDiagReportTitle", "tbDiagReport", "lbDiagLog")) {
        $Script:Diag[$name] = $window.FindName($name)
    }

    Set-DiagnosticTexts
    $Script:Diag.tbDiagIp.Text = $Script:DiagDefaultIp
    $Script:Diag.tbDiagUser.Text = $Script:DiagDefaultUser
    foreach ($kind in $Script:DiagTestKind.Values) {
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = T "DiagTest_$kind"
        $item.Tag = $kind
        $Script:Diag.cbDiagTest.Items.Add($item) | Out-Null
    }

    $Script:Diag.cbDiagTest.Add_SelectionChanged({ Update-DiagnosticTestFields })
    $Script:Diag.btnDiagConnect.Add_Click({ Connect-DiagnosticEwon })
    $Script:Diag.btnDiagStart.Add_Click({ Start-DiagnosticAction })
    $Script:Diag.btnDiagSaveCapture.Add_Click({ Save-DiagnosticCaptureFile })
    $Script:Diag.btnDiagClose.Add_Click({ $Script:Diag.Window.Close() })
    $window.Add_Closing({
        param($sender, $e)
        if ($Script:Diag.Run) {
            [System.Windows.MessageBox]::Show((T "DiagCaptureBusy"), (T "DlgConfirm"), "OK", "Warning") | Out-Null
            $e.Cancel = $true
        } elseif ($Script:Diag.CaptureBytes -and -not $Script:Diag.CaptureSaved) {
            $answer = [System.Windows.MessageBox]::Show((T "DiagUnsavedCapture"), (T "DlgConfirm"), "YesNo", "Question")
            if ($answer -eq "No") { $e.Cancel = $true }
        }
    })
    $Script:Diag.cbDiagTest.SelectedIndex = 0

    try {
        $window.ShowDialog() | Out-Null
    } finally {
        # Les identifiants (Ewon, serveurs testés) ne survivent pas à la fenêtre, même sur exception.
        $Script:Diag = $null
    }
}

function Set-DiagnosticTexts {
    $Script:Diag.Window.Title = T "DiagWindowTitle"
    $Script:Diag.btnDiagClose.Content = T "BtnClose"
    $Script:Diag.txtDiagEwonSection.Text = T "DiagEwonSection"
    $Script:Diag.txtDiagIpLabel.Text = T "DiagIpLabel"
    $Script:Diag.txtDiagUserLabel.Text = T "DiagUserLabel"
    $Script:Diag.txtDiagPasswordLabel.Text = T "DiagPasswordLabel"
    $Script:Diag.btnDiagConnect.Content = T "DiagConnect"
    $Script:Diag.txtDiagRunSection.Text = T "DiagRunSection"
    $Script:Diag.txtDiagTestLabel.Text = T "DiagTestLabel"
    $Script:Diag.txtDiagInterfaceLabel.Text = T "DiagInterfaceLabel"
    $Script:Diag.txtDiagDurationLabel.Text = T "DiagDurationLabel"
    $Script:Diag.btnDiagStart.Content = T "DiagStart"
    $Script:Diag.btnDiagSaveCapture.Content = T "DiagSaveCapture"
    $Script:Diag.txtDiagReportTitle.Text = T "DiagReportTitle"
}

function Add-DiagLog {
    param([string]$Message)
    Add-ListBoxLogEntry -ListBox $Script:Diag.lbDiagLog -Message $Message
}

function Format-DiagError {
    param([System.Exception]$Exception)
    $kind = $Exception.Data["EwonErrorKind"]
    if ($kind) { return (T "DiagErr_$kind") -f $Exception.Message }
    return "$(T 'ErrorPrefix') $($Exception.Message)"
}

function Get-WanKindLabel {
    param([string]$WanKind)
    return T "DiagWan_$WanKind"
}

function Get-SelectedDiagTest {
    return $Script:Diag.cbDiagTest.SelectedItem.Tag
}

function Get-DefaultCaptureSide {
    param([string]$Kind)
    # Un test peut sortir par le WAN ou par le LAN (Ewon en datalogger) : toutes les interfaces par défaut.
    if ($Kind -eq $Script:DiagTestKind.CaptureOnly) { return $Script:CaptureSide.Lan }
    return $Script:CaptureSide.All
}

function Select-DiagnosticCaptureSide {
    param([string]$Side)
    # Avant la connexion à l'Ewon, la liste des interfaces est vide.
    if ($Script:Diag.cbDiagInterface.Items.Count -eq 0) { return }
    foreach ($item in $Script:Diag.cbDiagInterface.Items) {
        if ($item.Tag -eq $Side) { $Script:Diag.cbDiagInterface.SelectedItem = $item; return }
    }
    $Script:Diag.cbDiagInterface.SelectedIndex = 0
}

function Update-DiagnosticTestFields {
    $kind = Get-SelectedDiagTest
    $panel = $Script:Diag.pnlDiagTestParams
    $panel.Children.Clear()
    $Script:Diag.TestFields = @{}
    foreach ($definition in $Script:DiagTestParameters[$kind]) {
        $row = New-ParamFieldRow -ParamDef $definition -NamePrefix "diag"
        $panel.Children.Add($row.Container) | Out-Null
        $Script:Diag.TestFields[$definition.Param] = $row
    }

    $isCaptureOnly = $kind -eq $Script:DiagTestKind.CaptureOnly
    $Script:Diag.tbDiagDuration.Text = if ($isCaptureOnly) { $Script:CaptureDefaultSeconds } else { $Script:DiagTestCaptureSeconds }
    $Script:Diag.txtDiagHint.Text = if ($isCaptureOnly) {
        (T "DiagDurationHint") -f $Script:CaptureMinSeconds, $Script:CaptureMaxSeconds
    } else {
        (T "DiagTestHint") -f $Script:DiagTestDelaySeconds
    }
    Select-DiagnosticCaptureSide (Get-DefaultCaptureSide $kind)
}

function Connect-DiagnosticEwon {
    $ip = $Script:Diag.tbDiagIp.Text.Trim()
    $user = $Script:Diag.tbDiagUser.Text.Trim()
    $password = $Script:Diag.pbDiagPassword.Password

    $Script:Diag.Session = $null
    $Script:Diag.NetworkProfile = $null
    $Script:Diag.txtDiagEwonInfo.Text = ""
    Set-DiagnosticBusy $false
    if (-not (Test-IPv4 $ip)) { Add-DiagLog (T "ValInvalidIP"); return }
    if (-not (Test-NotEmpty $user) -or -not (Test-NotEmpty $password)) { Add-DiagLog (T "DiagValCredentials"); return }

    # Bloque les clics rejoués pendant l'attente de l'Ewon (jusqu'au délai HTTP s'il est injoignable).
    Set-DiagnosticBusy $true
    Add-DiagLog ((T "DiagConnecting") -f $ip)
    try {
        $session = New-EwonSession -Ip $ip -User $user -Password $password
        $networkProfile = Get-EwonNetworkProfile -Status (Get-EwonStatus -Session $session)
    } catch {
        Add-DiagLog (Format-DiagError $_.Exception)
        return
    } finally {
        Set-DiagnosticBusy $false
    }
    if (-not $networkProfile.FirmwareSupported) {
        Add-DiagLog ((T "DiagErr_FirmwareUnsupported") -f $networkProfile.Firmware, (Get-TcpDumpMinFirmwareLabel))
        return
    }

    $Script:Diag.Session = $session
    $Script:Diag.NetworkProfile = $networkProfile
    $info = (T "DiagEwonInfo") -f $networkProfile.PartNumber, $networkProfile.SerialNumber, $networkProfile.Firmware, (Get-WanKindLabel $networkProfile.WanKind)
    $Script:Diag.txtDiagEwonInfo.Text = $info
    Add-DiagLog "[OK] $info"

    $combo = $Script:Diag.cbDiagInterface
    $combo.Items.Clear()
    foreach ($side in Get-CaptureSides -NetworkProfile $networkProfile) {
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = (T "DiagSide_$side") -f (Get-WanKindLabel $networkProfile.WanKind)
        $item.Tag = $side
        $combo.Items.Add($item) | Out-Null
    }
    Select-DiagnosticCaptureSide (Get-DefaultCaptureSide (Get-SelectedDiagTest))
    Set-DiagnosticBusy $false
}

function Set-DiagnosticBusy {
    param([bool]$Busy)
    $Script:Diag.pnlDiagRun.IsEnabled = (-not $Busy) -and ($null -ne $Script:Diag.NetworkProfile)
    $Script:Diag.btnDiagConnect.IsEnabled = -not $Busy
    $Script:Diag.btnDiagClose.IsEnabled = -not $Busy
    $Script:Diag.btnDiagSaveCapture.IsEnabled = (-not $Busy) -and ($null -ne $Script:Diag.CaptureBytes)
}

function Get-DiagnosticTestValues {
    # Lit les champs du test et efface les marques d'erreur de la tentative précédente.
    $values = @{}
    foreach ($entry in $Script:Diag.TestFields.GetEnumerator()) {
        $values[$entry.Key] = Get-FieldValue $entry.Value.InputControl
        Clear-ValidationIcon -Icon $entry.Value.ValidationIcon
    }
    return $values
}

function Start-DiagnosticAction {
    $durationText = $Script:Diag.tbDiagDuration.Text.Trim()
    if (-not (Test-CaptureDuration $durationText)) {
        Add-DiagLog ((T "DiagValDuration") -f $Script:CaptureMinSeconds, $Script:CaptureMaxSeconds)
        return
    }
    $kind = Get-SelectedDiagTest
    $values = Get-DiagnosticTestValues
    $invalid = Test-DiagTestParameters -Kind $kind -Values $values
    if ($invalid) {
        Update-ValidationIcon -Icon $Script:Diag.TestFields[$invalid.Param].ValidationIcon -IsValid $false -Message (T $invalid.MessageKey)
        Add-DiagLog (T $invalid.MessageKey)
        return
    }

    $durationSeconds = [int]$durationText
    $interface = Resolve-CaptureInterface -NetworkProfile $Script:Diag.NetworkProfile -Side $Script:Diag.cbDiagInterface.SelectedItem.Tag
    $Script:Diag.CaptureBytes = $null
    $Script:Diag.tbDiagReport.Text = ""
    Set-DiagnosticBusy $true
    $Script:Diag.pbDiagCapture.Value = 0
    Add-DiagLog ((T "DiagRunStarted") -f (T "DiagTest_$kind"), $interface, $durationSeconds)
    try {
        $Script:Diag.Run = Start-DiagnosticRun -Session $Script:Diag.Session -Kind $kind -Values $values `
            -NetworkProfile $Script:Diag.NetworkProfile -Interface $interface -DurationSeconds $durationSeconds
    } catch {
        Add-DiagLog (Format-DiagError $_.Exception)
        Set-DiagnosticBusy $false
        return
    }

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds($Script:DiagPollIntervalMs)
    $timer.Add_Tick({
        param($sender, $e)
        $capture = $Script:Diag.Run.Capture
        if (-not $capture.State.Done) {
            $elapsed = ((Get-Date) - $capture.StartedAt).TotalSeconds
            $remaining = [math]::Ceiling($capture.DurationSeconds - $elapsed)
            $Script:Diag.pbDiagCapture.Value = [math]::Min(100, 100 * $elapsed / $capture.DurationSeconds)
            $Script:Diag.txtDiagCaptureStatus.Text = if ($remaining -gt 0) {
                (T "DiagCaptureRunning") -f $capture.Interface, $remaining
            } else {
                T "DiagCaptureWaiting"
            }
            return
        }
        $sender.Stop()
        Complete-DiagnosticAction
    })
    $timer.Start()
}

function Complete-DiagnosticAction {
    $run = $Script:Diag.Run
    $Script:Diag.txtDiagCaptureStatus.Text = T "DiagDownloading"
    Update-WpfUI
    try {
        # Ces étapes réseau restent sur le fil de l'interface : on la laisse se redessiner entre chacune.
        $result = Complete-DiagnosticRun -Session $Script:Diag.Session -Run $run -OnStep { Update-WpfUI }
        $Script:Diag.pbDiagCapture.Value = 100
        if (-not $result.Cleaned) { Add-DiagLog ((T "DiagCleanupFailed") -f $Script:CaptureOutputPath) }
        $Script:Diag.CaptureBytes = $result.Bytes
        $Script:Diag.CaptureSaved = $false
        $Script:Diag.CaptureFileName = Get-CaptureFileName -NetworkProfile $Script:Diag.NetworkProfile -Interface $run.Interface
        $Script:Diag.tbDiagReport.Text = Format-DiagnosticReport -Kind $run.Kind -Findings (Get-DiagnosticFindings -Run $run -Result $result)
        Add-DiagLog (T "DiagReportReady")
    } catch {
        Add-DiagLog (Format-DiagError $_.Exception)
    } finally {
        $Script:Diag.Run = $null
        $Script:Diag.txtDiagCaptureStatus.Text = ""
        Set-DiagnosticBusy $false
    }
}

function Format-DiagnosticFinding {
    param([hashtable]$Finding)
    $arguments = @($Finding.Arguments | ForEach-Object {
        if ($_ -is [hashtable] -and $_.ContainsKey("TextKey")) { T $_.TextKey }
        elseif ($_ -is [System.Exception]) { (Format-DiagError $_).TrimEnd(".") }
        else { $_ }
    })
    return "$($Script:FindingSymbol[$Finding.Level]) $((T $Finding.Key) -f $arguments)"
}

function Format-DiagnosticReport {
    param([string]$Kind, [object[]]$Findings)
    $header = (T "DiagReportHeader") -f (T "DiagTest_$Kind"), $Script:Diag.NetworkProfile.SerialNumber, (Get-Date).ToString("yyyy-MM-dd HH:mm")
    $lines = @($header, "") + @($Findings | ForEach-Object { Format-DiagnosticFinding $_ })
    return $lines -join [Environment]::NewLine
}

function Save-DiagnosticCaptureFile {
    if (Save-DiagnosticCapture -Bytes $Script:Diag.CaptureBytes -FileName $Script:Diag.CaptureFileName) {
        $Script:Diag.CaptureSaved = $true
    }
}

function Save-DiagnosticCapture {
    param([Parameter(Mandatory)][byte[]]$Bytes, [Parameter(Mandatory)][string]$FileName)
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.FileName = $FileName
    $dialog.Filter = T "DiagPcapFilter"
    $dialog.InitialDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
    # Redemande un emplacement tant que l'écriture échoue (fichier verrouillé, dossier protégé) ; seul l'abandon y met fin.
    while ($dialog.ShowDialog($Script:Diag.Window)) {
        try {
            [System.IO.File]::WriteAllBytes($dialog.FileName, $Bytes)
            Add-DiagLog ((T "DiagCaptureSaved") -f $dialog.FileName, $Bytes.Length)
            return $true
        } catch {
            Add-DiagLog "$(T 'ErrorPrefix') $($_.Exception.Message)"
        }
    }
    return $false
}
