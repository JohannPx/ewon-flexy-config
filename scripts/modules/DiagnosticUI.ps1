# DiagnosticUI.ps1 - Fenêtre de diagnostic réseau (connexion à l'Ewon par son LAN, capture du trafic)

$Script:DiagDefaultIp        = "192.168.253.254"
$Script:DiagDefaultUser      = "adm"
$Script:DiagPollIntervalMs   = 500
$Script:Diag                 = $null

$Script:DiagXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Width="640" Height="640" MinWidth="560" MinHeight="560"
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

    <StackPanel DockPanel.Dock="Top">
      <TextBlock x:Name="txtDiagEwonSection" Style="{StaticResource SectionHeader}"/>
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="140"/>
          <ColumnDefinition Width="220"/>
        </Grid.ColumnDefinitions>
        <Grid.RowDefinitions>
          <RowDefinition Height="32"/>
          <RowDefinition Height="32"/>
          <RowDefinition Height="32"/>
        </Grid.RowDefinitions>
        <TextBlock x:Name="txtDiagIpLabel" Style="{StaticResource FieldLabel}" Grid.Row="0"/>
        <TextBox x:Name="tbDiagIp" Grid.Row="0" Grid.Column="1" Height="26" VerticalContentAlignment="Center"/>
        <TextBlock x:Name="txtDiagUserLabel" Style="{StaticResource FieldLabel}" Grid.Row="1"/>
        <TextBox x:Name="tbDiagUser" Grid.Row="1" Grid.Column="1" Height="26" VerticalContentAlignment="Center"/>
        <TextBlock x:Name="txtDiagPasswordLabel" Style="{StaticResource FieldLabel}" Grid.Row="2"/>
        <PasswordBox x:Name="pbDiagPassword" Grid.Row="2" Grid.Column="1" Height="26" VerticalContentAlignment="Center"/>
      </Grid>
      <Button x:Name="btnDiagConnect" Style="{StaticResource ActionBtn}" Margin="0,8,0,0"
              Background="#1A5276" Foreground="White"/>
      <TextBlock x:Name="txtDiagEwonInfo" FontSize="12" Margin="0,8,0,0" TextWrapping="Wrap" Foreground="#333"/>

      <Separator Margin="0,12"/>

      <StackPanel x:Name="pnlDiagCapture" IsEnabled="False">
        <TextBlock x:Name="txtDiagCaptureSection" Style="{StaticResource SectionHeader}"/>
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="140"/>
            <ColumnDefinition Width="220"/>
          </Grid.ColumnDefinitions>
          <Grid.RowDefinitions>
            <RowDefinition Height="32"/>
            <RowDefinition Height="32"/>
          </Grid.RowDefinitions>
          <TextBlock x:Name="txtDiagInterfaceLabel" Style="{StaticResource FieldLabel}" Grid.Row="0"/>
          <ComboBox x:Name="cbDiagInterface" Grid.Row="0" Grid.Column="1" Height="26"/>
          <TextBlock x:Name="txtDiagDurationLabel" Style="{StaticResource FieldLabel}" Grid.Row="1"/>
          <TextBox x:Name="tbDiagDuration" Grid.Row="1" Grid.Column="1" Height="26" VerticalContentAlignment="Center"/>
        </Grid>
        <TextBlock x:Name="txtDiagDurationHint" FontSize="11" Foreground="#666" Margin="0,4,0,0" TextWrapping="Wrap"/>
        <Button x:Name="btnDiagStartCapture" Style="{StaticResource ActionBtn}" Margin="0,8,0,0"/>
        <ProgressBar x:Name="pbDiagCapture" Height="16" Margin="0,10,0,0" Foreground="#27AE60" Minimum="0" Maximum="100"/>
        <TextBlock x:Name="txtDiagCaptureStatus" FontSize="12" Margin="0,4,0,0"/>
      </StackPanel>
    </StackPanel>

    <ListBox x:Name="lbDiagLog" FontFamily="Consolas" FontSize="11" Margin="0,10,0,0"
             Background="#1E1E1E" Foreground="#D4D4D4" BorderThickness="0"/>
  </DockPanel>
</Window>
'@

function Show-NetworkDiagnosticWindow {
    param([Parameter(Mandatory)][System.Windows.Window]$Owner)

    [xml]$xaml = $Script:DiagXaml
    $window = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
    $window.Owner = $Owner
    $window.Icon = $Owner.Icon

    $Script:Diag = @{ Window = $window; Session = $null; NetworkProfile = $null; Capture = $null }
    foreach ($name in @(
            "btnDiagClose", "txtDiagEwonSection", "txtDiagIpLabel", "tbDiagIp", "txtDiagUserLabel", "tbDiagUser",
            "txtDiagPasswordLabel", "pbDiagPassword", "btnDiagConnect", "txtDiagEwonInfo", "pnlDiagCapture",
            "txtDiagCaptureSection", "txtDiagInterfaceLabel", "cbDiagInterface", "txtDiagDurationLabel",
            "tbDiagDuration", "txtDiagDurationHint", "btnDiagStartCapture", "pbDiagCapture", "txtDiagCaptureStatus",
            "lbDiagLog")) {
        $Script:Diag[$name] = $window.FindName($name)
    }

    Set-DiagnosticTexts
    $Script:Diag.tbDiagIp.Text = $Script:DiagDefaultIp
    $Script:Diag.tbDiagUser.Text = $Script:DiagDefaultUser
    $Script:Diag.tbDiagDuration.Text = $Script:CaptureDefaultSeconds

    $Script:Diag.btnDiagConnect.Add_Click({ Connect-DiagnosticEwon })
    $Script:Diag.btnDiagStartCapture.Add_Click({ Start-DiagnosticCapture })
    $Script:Diag.btnDiagClose.Add_Click({ $Script:Diag.Window.Close() })
    $window.Add_Closing({
        param($sender, $e)
        if ($Script:Diag.Capture) {
            [System.Windows.MessageBox]::Show((T "DiagCaptureBusy"), (T "DlgConfirm"), "OK", "Warning") | Out-Null
            $e.Cancel = $true
        }
    })

    try {
        $window.ShowDialog() | Out-Null
    } finally {
        # Les identifiants de l'Ewon ne survivent pas à la fenêtre, même sur exception.
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
    $Script:Diag.txtDiagCaptureSection.Text = T "DiagCaptureSection"
    $Script:Diag.txtDiagInterfaceLabel.Text = T "DiagInterfaceLabel"
    $Script:Diag.txtDiagDurationLabel.Text = T "DiagDurationLabel"
    $Script:Diag.txtDiagDurationHint.Text = (T "DiagDurationHint") -f $Script:CaptureMinSeconds, $Script:CaptureMaxSeconds
    $Script:Diag.btnDiagStartCapture.Content = T "DiagStartCapture"
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
    $combo.SelectedIndex = 0
    Set-DiagnosticBusy $false
}

function Set-DiagnosticBusy {
    param([bool]$Busy)
    $Script:Diag.pnlDiagCapture.IsEnabled = (-not $Busy) -and ($null -ne $Script:Diag.NetworkProfile)
    $Script:Diag.btnDiagConnect.IsEnabled = -not $Busy
    $Script:Diag.btnDiagClose.IsEnabled = -not $Busy
}

function Start-DiagnosticCapture {
    $durationText = $Script:Diag.tbDiagDuration.Text.Trim()
    if (-not (Test-CaptureDuration $durationText)) {
        Add-DiagLog ((T "DiagValDuration") -f $Script:CaptureMinSeconds, $Script:CaptureMaxSeconds)
        return
    }

    $durationSeconds = [int]$durationText
    $interface = Resolve-CaptureInterface -NetworkProfile $Script:Diag.NetworkProfile -Side $Script:Diag.cbDiagInterface.SelectedItem.Tag
    Set-DiagnosticBusy $true
    $Script:Diag.pbDiagCapture.Value = 0
    Add-DiagLog ((T "DiagCaptureStarted") -f $interface, $durationSeconds)
    $Script:Diag.Capture = Start-EwonCapture -Session $Script:Diag.Session -Interface $interface -DurationSeconds $durationSeconds

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds($Script:DiagPollIntervalMs)
    $timer.Add_Tick({
        param($sender, $e)
        $capture = $Script:Diag.Capture
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
        Complete-DiagnosticCapture
    })
    $timer.Start()
}

function Complete-DiagnosticCapture {
    $capture = $Script:Diag.Capture
    $Script:Diag.txtDiagCaptureStatus.Text = T "DiagDownloading"
    Update-WpfUI
    try {
        $bytes = Complete-EwonCapture -Session $Script:Diag.Session -Capture $capture
        $Script:Diag.pbDiagCapture.Value = 100
        $saved = Save-DiagnosticCapture -Bytes $bytes -FileName (Get-CaptureFileName -NetworkProfile $Script:Diag.NetworkProfile -Interface $capture.Interface)
        if (-not $saved) {
            Add-DiagLog ((T "DiagCaptureKeptOnEwon") -f $Script:CaptureOutputPath)
        } elseif (-not (Clear-EwonCapture -Session $Script:Diag.Session)) {
            Add-DiagLog ((T "DiagCleanupFailed") -f $Script:CaptureOutputPath)
        }
    } catch {
        Add-DiagLog (Format-DiagError $_.Exception)
    } finally {
        $Script:Diag.Capture = $null
        $Script:Diag.txtDiagCaptureStatus.Text = ""
        Set-DiagnosticBusy $false
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
