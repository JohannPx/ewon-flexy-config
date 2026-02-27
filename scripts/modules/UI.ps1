# UI.ps1 - WPF Wizard window, XAML definition, event wiring

$Script:StepTitles = $null  # Populated at runtime from T()
$Script:TotalSteps = 8

# Field maps for dynamic panels
$Script:NetworkFieldMap = @{}
$Script:CommonFieldMap  = @{}
$Script:NetworkGroupHeaders = @{}
$Script:CommonGroupHeaders  = @{}
$Script:UserTouched     = @{}  # track manually modified fields

function Get-StepTitles {
    return @(
        (T "Step0Title"), (T "Step1Title"), (T "Step2Title"), (T "Step3Title"),
        (T "Step4Title"), (T "Step5Title"), (T "Step6Title"), (T "Step7Title")
    )
}

$Script:MainXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ewon Flexy SD"
        Width="760" Height="620"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanMinimize"
        UseLayoutRounding="True"
        SnapsToDevicePixels="True"
        Background="#FAFAFA">
  <Window.Resources>
    <Style x:Key="StepHeader" TargetType="TextBlock">
      <Setter Property="FontSize" Value="17"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Margin" Value="0,0,0,12"/>
      <Setter Property="Foreground" Value="#1A5276"/>
    </Style>
    <Style x:Key="SubText" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#666"/>
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="Margin" Value="0,0,0,8"/>
    </Style>
    <Style x:Key="NavBtn" TargetType="Button">
      <Setter Property="MinWidth" Value="110"/>
      <Setter Property="Height" Value="34"/>
      <Setter Property="Margin" Value="5,0"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
    </Style>
    <Style x:Key="RadioOpt" TargetType="RadioButton">
      <Setter Property="Margin" Value="0,6"/>
      <Setter Property="FontSize" Value="13"/>
    </Style>
    <Style x:Key="LangBtn" TargetType="Button">
      <Setter Property="Width" Value="52"/>
      <Setter Property="Height" Value="30"/>
      <Setter Property="Margin" Value="3,0"/>
      <Setter Property="Padding" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="BorderThickness" Value="2"/>
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
      <Setter Property="VerticalContentAlignment" Value="Stretch"/>
    </Style>
  </Window.Resources>

  <DockPanel>
    <!-- Top bar -->
    <Border DockPanel.Dock="Top" Background="#1A5276" Padding="18,12">
      <StackPanel>
        <TextBlock x:Name="txtStepTitle" Foreground="White" FontSize="15" FontWeight="SemiBold" Text="..."/>
        <ProgressBar x:Name="pbSteps" Height="4" Minimum="0" Maximum="8" Value="1"
                     Margin="0,8,0,0" Foreground="#27AE60" Background="#2C6E99"/>
      </StackPanel>
    </Border>

    <!-- Bottom nav -->
    <Border DockPanel.Dock="Bottom" Padding="12,8" Background="#F0F0F0"
            BorderBrush="#DDD" BorderThickness="0,1,0,0">
      <DockPanel>
        <Button x:Name="btnCancel" Content="Annuler" DockPanel.Dock="Left" Style="{StaticResource NavBtn}"/>
        <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="btnPrevious" Content="Precedent" Style="{StaticResource NavBtn}" IsEnabled="False"/>
          <Button x:Name="btnNext" Content="Suivant" Style="{StaticResource NavBtn}"
                  Background="#1A5276" Foreground="White"/>
        </StackPanel>
        <Control/>
      </DockPanel>
    </Border>

    <!-- Wizard pages -->
    <TabControl x:Name="wizardTabs" Margin="18" BorderThickness="0" Background="Transparent">
      <TabControl.ItemContainerStyle>
        <Style TargetType="TabItem">
          <Setter Property="Visibility" Value="Collapsed"/>
        </Style>
      </TabControl.ItemContainerStyle>

      <!-- Step 0: Mode + Firmware -->
      <TabItem>
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel Margin="5">
            <!-- Language selector -->
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,0,8">
              <TextBlock x:Name="txtLangLabel" Text="Langue :" VerticalAlignment="Center" Margin="0,0,8,0" FontSize="11"/>
              <Button x:Name="btnLangFR" Style="{StaticResource LangBtn}" Tag="FR" ToolTip="Français">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/>
                  </Grid.ColumnDefinitions>
                  <Rectangle Grid.Column="0" Fill="#002395"/>
                  <Rectangle Grid.Column="1" Fill="White"/>
                  <Rectangle Grid.Column="2" Fill="#ED2939"/>
                </Grid>
              </Button>
              <Button x:Name="btnLangEN" Style="{StaticResource LangBtn}" Tag="EN" ToolTip="English">
                <Grid Background="#012169">
                  <Rectangle Fill="White" Width="10" HorizontalAlignment="Center"/>
                  <Rectangle Fill="White" Height="8" VerticalAlignment="Center"/>
                  <Rectangle Fill="#CF142B" Width="5" HorizontalAlignment="Center"/>
                  <Rectangle Fill="#CF142B" Height="4" VerticalAlignment="Center"/>
                </Grid>
              </Button>
              <Button x:Name="btnLangES" Style="{StaticResource LangBtn}" Tag="ES" ToolTip="Español">
                <Grid>
                  <Grid.RowDefinitions>
                    <RowDefinition Height="*"/><RowDefinition Height="2*"/><RowDefinition Height="*"/>
                  </Grid.RowDefinitions>
                  <Rectangle Grid.Row="0" Fill="#AA151B"/>
                  <Rectangle Grid.Row="1" Fill="#F1BF00"/>
                  <Rectangle Grid.Row="2" Fill="#AA151B"/>
                </Grid>
              </Button>
              <Button x:Name="btnLangIT" Style="{StaticResource LangBtn}" Tag="IT" ToolTip="Italiano">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/>
                  </Grid.ColumnDefinitions>
                  <Rectangle Grid.Column="0" Fill="#009246"/>
                  <Rectangle Grid.Column="1" Fill="White"/>
                  <Rectangle Grid.Column="2" Fill="#CE2B37"/>
                </Grid>
              </Button>
            </StackPanel>

            <TextBlock x:Name="txtModeTitle" Text="Mode et Firmware" Style="{StaticResource StepHeader}"/>

            <!-- Hidden radio buttons for internal mode logic -->
            <StackPanel Visibility="Collapsed">
              <RadioButton x:Name="rbOnline" GroupName="Mode" IsChecked="True"/>
              <RadioButton x:Name="rbCache" GroupName="Mode"/>
              <RadioButton x:Name="rbPreparation" GroupName="Mode"/>
            </StackPanel>

            <!-- Connection status banner -->
            <Border x:Name="brdConnStatus" Padding="12,8" CornerRadius="4" Background="#E8F8E8" Margin="0,0,0,10">
              <TextBlock x:Name="txtConnStatus" FontSize="12" TextWrapping="Wrap" Text="..."/>
            </Border>

            <Separator Margin="0,8"/>
            <TextBlock x:Name="txtFwTitle" Text="Firmware" Style="{StaticResource StepHeader}"/>
            <TextBlock x:Name="txtFwHelp" Text="..." Style="{StaticResource SubText}"/>

            <StackPanel Orientation="Horizontal" Margin="0,5">
              <TextBlock x:Name="txtFwCurrentLabel" Text="Firmware actuel :" VerticalAlignment="Center" Width="130"/>
              <ComboBox x:Name="cbCurrentFw" Width="180"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" Margin="0,8">
              <TextBlock x:Name="txtFwTargetLabel" Text="Firmware cible :" VerticalAlignment="Center" Width="130"/>
              <ComboBox x:Name="cbTargetFw" Width="180"/>
            </StackPanel>
            <CheckBox x:Name="chkSkipFirmware" Content="Configuration uniquement" Margin="0,10" FontSize="12"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- Step 1: Connection type -->
      <TabItem>
        <StackPanel Margin="5">
          <TextBlock x:Name="txtConnTypeTitle" Text="Type de connexion" Style="{StaticResource StepHeader}"/>
          <TextBlock x:Name="txtConnTypeSubtitle" Text="..." Style="{StaticResource SubText}"/>

          <Border BorderBrush="#DDD" BorderThickness="1" CornerRadius="4" Padding="15" Margin="0,8">
            <RadioButton x:Name="rb4G" GroupName="ConnType" IsChecked="True" Style="{StaticResource RadioOpt}">
              <StackPanel>
                <TextBlock x:Name="txt4GTitle" FontWeight="SemiBold" Text="Modem 4G"/>
                <TextBlock x:Name="txt4GDesc" Text="..." Style="{StaticResource SubText}"/>
              </StackPanel>
            </RadioButton>
          </Border>
          <Border BorderBrush="#DDD" BorderThickness="1" CornerRadius="4" Padding="15" Margin="0,4">
            <RadioButton x:Name="rbEthernet" GroupName="ConnType" Style="{StaticResource RadioOpt}">
              <StackPanel>
                <TextBlock x:Name="txtEthTitle" FontWeight="SemiBold" Text="Ethernet"/>
                <TextBlock x:Name="txtEthDesc" Text="..." Style="{StaticResource SubText}"/>
              </StackPanel>
            </RadioButton>
          </Border>
          <Border BorderBrush="#DDD" BorderThickness="1" CornerRadius="4" Padding="15" Margin="0,4">
            <RadioButton x:Name="rbDatalogger" GroupName="ConnType" Style="{StaticResource RadioOpt}">
              <StackPanel>
                <TextBlock x:Name="txtDLTitle" FontWeight="SemiBold" Text="Datalogger"/>
                <TextBlock x:Name="txtDLDesc" Text="..." Style="{StaticResource SubText}"/>
              </StackPanel>
            </RadioButton>
          </Border>
        </StackPanel>
      </TabItem>

      <!-- Step 2: Network parameters (dynamic) -->
      <TabItem>
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel Margin="5">
            <TextBlock x:Name="txtNetTitle" Text="Parametres reseau" Style="{StaticResource StepHeader}"/>
            <TextBlock x:Name="txtNetworkSubtitle" Style="{StaticResource SubText}" Text="..."/>
            <StackPanel x:Name="pnlNetworkParams"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- Step 3: Common parameters (dynamic) -->
      <TabItem>
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel Margin="5">
            <TextBlock x:Name="txtCommonTitle" Text="Parametres communs" Style="{StaticResource StepHeader}"/>
            <TextBlock x:Name="txtCommonSubtitle" Text="..." Style="{StaticResource SubText}"/>
            <StackPanel x:Name="pnlCommonParams"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- Step 4: Talk2M -->
      <TabItem>
        <StackPanel Margin="5">
          <TextBlock x:Name="txtT2MTitle" Text="Identifiants Talk2M" Style="{StaticResource StepHeader}"/>
          <Border Background="#FFF3CD" Padding="10" CornerRadius="4" Margin="0,0,0,15">
            <TextBlock x:Name="txtT2MWarning" Text="..." FontSize="11" TextWrapping="Wrap"/>
          </Border>

          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="220"/>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="30"/>
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="12"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <TextBlock x:Name="txtT2MKeyLabel" Text="Cle globale :" Grid.Row="0" VerticalAlignment="Center" TextWrapping="Wrap"/>
            <PasswordBox x:Name="tbT2MKey" Grid.Row="0" Grid.Column="1" Height="28" FontSize="12"/>
            <TextBlock x:Name="valT2MKey" Grid.Row="0" Grid.Column="2" FontSize="14"
                       VerticalAlignment="Center" HorizontalAlignment="Center"/>

            <TextBlock x:Name="txtT2MNoteLabel" Text="Description :" Grid.Row="2" VerticalAlignment="Center" TextWrapping="Wrap"/>
            <TextBox x:Name="tbT2MNote" Grid.Row="2" Grid.Column="1" Height="28" FontSize="12"/>
            <TextBlock x:Name="valT2MNote" Grid.Row="2" Grid.Column="2" FontSize="14"
                       VerticalAlignment="Center" HorizontalAlignment="Center"/>
          </Grid>
        </StackPanel>
      </TabItem>

      <!-- Step 5: SD Drive -->
      <TabItem>
        <StackPanel Margin="5">
          <TextBlock x:Name="txtSDTitle" Text="Selection du lecteur SD" Style="{StaticResource StepHeader}"/>
          <TextBlock x:Name="txtSDSubtitle" Text="..." Style="{StaticResource SubText}"/>

          <ListBox x:Name="lbDrives" Height="160" FontSize="13" Margin="0,5"/>
          <Button x:Name="btnRefreshDrives" Content="Actualiser" Width="160"
                  HorizontalAlignment="Left" Margin="0,8" Height="30"/>
          <TextBlock x:Name="txtDriveInfo" Foreground="#888" Margin="0,8" FontSize="11" Text="..."/>
        </StackPanel>
      </TabItem>

      <!-- Step 6: Summary -->
      <TabItem>
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel Margin="5">
            <TextBlock x:Name="txtSummaryTitle" Text="Resume" Style="{StaticResource StepHeader}"/>
            <Border Background="#EAF2F8" Padding="12" CornerRadius="4" Margin="0,0,0,10">
              <TextBlock x:Name="txtSummaryCheck" Text="..."
                         FontSize="12" FontWeight="SemiBold" Foreground="#1A5276"/>
            </Border>
            <TextBlock x:Name="txtSummary" FontFamily="Consolas" FontSize="11.5" TextWrapping="Wrap"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- Step 7: Progress & Procedure -->
      <TabItem>
        <Grid Margin="5">
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <TextBlock x:Name="txtGenerationTitle" Text="Generation en cours..."
                     Style="{StaticResource StepHeader}" Grid.Row="0"/>
          <ProgressBar x:Name="pbGeneration" Height="22" Minimum="0" Maximum="100"
                       Margin="0,8" Foreground="#27AE60" Grid.Row="1"/>
          <TextBlock x:Name="txtGenerationPercent" HorizontalAlignment="Center"
                     FontSize="13" Margin="0,4" Grid.Row="2"/>

          <!-- Log (visible during generation) -->
          <ListBox x:Name="lbLog" FontFamily="Consolas" FontSize="11"
                   Margin="0,12,0,0" Background="#1E1E1E" Foreground="#D4D4D4"
                   BorderThickness="0" Grid.Row="3"/>

          <!-- Procedure (visible after generation) -->
          <ScrollViewer x:Name="svProcedure" Grid.Row="3" Visibility="Collapsed"
                        VerticalScrollBarVisibility="Auto" Margin="0,12,0,0">
            <Border Background="#FFFFFF" BorderBrush="#DDD" BorderThickness="1"
                    CornerRadius="4" Padding="16">
              <TextBlock x:Name="txtProcedure" FontFamily="Consolas" FontSize="11.5"
                         TextWrapping="Wrap"/>
            </Border>
          </ScrollViewer>

          <TextBlock x:Name="txtFinalStatus" FontSize="15" FontWeight="Bold"
                     HorizontalAlignment="Center" Margin="0,10" Grid.Row="4"/>
        </Grid>
      </TabItem>
    </TabControl>
  </DockPanel>
</Window>
'@

function New-AppIcon {
    # Generate a 32x32 SD card icon programmatically using WPF drawing
    $size = 32
    $dv = New-Object System.Windows.Media.DrawingVisual
    $dc = $dv.RenderOpen()

    # SD card body (rounded rectangle, blue gradient)
    $cardRect = New-Object System.Windows.Rect(3, 1, 22, 30)
    $brush = New-Object System.Windows.Media.LinearGradientBrush(
        [System.Windows.Media.Color]::FromRgb(26, 82, 118),
        [System.Windows.Media.Color]::FromRgb(41, 128, 185),
        45)
    $pen = New-Object System.Windows.Media.Pen([System.Windows.Media.Brushes]::White, 0.5)
    $dc.DrawRoundedRectangle($brush, $pen, $cardRect, 2, 2)

    # Corner notch (top-right triangle to mimic SD card shape)
    $notchGeo = New-Object System.Windows.Media.StreamGeometry
    $ctx = $notchGeo.Open()
    $ctx.BeginFigure((New-Object System.Windows.Point(19, 1)), $true, $true)
    $ctx.LineTo((New-Object System.Windows.Point(25, 7)), $true, $false)
    $ctx.LineTo((New-Object System.Windows.Point(25, 1)), $true, $false)
    $ctx.Close()
    $dc.DrawGeometry([System.Windows.Media.Brushes]::White, $null, $notchGeo)

    # Redraw SD body outline over the notch area
    $bodyGeo = New-Object System.Windows.Media.StreamGeometry
    $ctx2 = $bodyGeo.Open()
    $ctx2.BeginFigure((New-Object System.Windows.Point(5, 1)), $false, $false)
    $ctx2.LineTo((New-Object System.Windows.Point(19, 1)), $true, $false)
    $ctx2.LineTo((New-Object System.Windows.Point(25, 7)), $true, $false)
    $ctx2.LineTo((New-Object System.Windows.Point(25, 29)), $true, $false)
    $ctx2.ArcTo((New-Object System.Windows.Point(23, 31)), (New-Object System.Windows.Size(2, 2)), 0, $false,
        [System.Windows.Media.SweepDirection]::Clockwise, $true, $false)
    $ctx2.LineTo((New-Object System.Windows.Point(5, 31)), $true, $false)
    $ctx2.ArcTo((New-Object System.Windows.Point(3, 29)), (New-Object System.Windows.Size(2, 2)), 0, $false,
        [System.Windows.Media.SweepDirection]::Clockwise, $true, $false)
    $ctx2.LineTo((New-Object System.Windows.Point(3, 3)), $true, $false)
    $ctx2.ArcTo((New-Object System.Windows.Point(5, 1)), (New-Object System.Windows.Size(2, 2)), 0, $false,
        [System.Windows.Media.SweepDirection]::Clockwise, $true, $false)
    $ctx2.Close()

    # Contact pins (small gold rectangles)
    $goldBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 215, 0))
    for ($i = 0; $i -lt 4; $i++) {
        $pinRect = New-Object System.Windows.Rect((8 + $i * 4), 4, 2, 8)
        $dc.DrawRectangle($goldBrush, $null, $pinRect)
    }

    # "SD" text
    $typeface = New-Object System.Windows.Media.Typeface(
        (New-Object System.Windows.Media.FontFamily("Segoe UI")),
        [System.Windows.FontStyles]::Normal,
        [System.Windows.FontWeights]::Bold,
        [System.Windows.FontStretches]::Normal)
    $formattedText = New-Object System.Windows.Media.FormattedText(
        "SD", [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Windows.FlowDirection]::LeftToRight,
        $typeface, 10, [System.Windows.Media.Brushes]::White)
    $textX = (28 - $formattedText.Width) / 2
    $dc.DrawText($formattedText, (New-Object System.Windows.Point($textX, 17)))

    $dc.Close()

    # Render to bitmap
    $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($size, $size, 96, 96,
        [System.Windows.Media.PixelFormats]::Pbgra32)
    $rtb.Render($dv)
    $rtb.Freeze()
    return $rtb
}

function Initialize-MainWindow {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    # Set unique AppUserModelID so the taskbar shows our icon instead of PowerShell's
    try {
        Add-Type -Name Shell32AppId -Namespace Native -ErrorAction SilentlyContinue -MemberDefinition @'
            [DllImport("shell32.dll", SetLastError = true)]
            public static extern void SetCurrentProcessExplicitAppUserModelID(
                [MarshalAs(UnmanagedType.LPWStr)] string AppID);
'@
        [Native.Shell32AppId]::SetCurrentProcessExplicitAppUserModelID("EwonFlexConfig.SDTool.1")
    } catch {}

    # Parse XAML
    [xml]$xaml = $Script:MainXaml
    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $Script:Window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Set app icon (programmatically generated SD card icon)
    try { $Script:Window.Icon = New-AppIcon } catch {}

    # Bind all named elements to script variables
    $elementNames = @(
        "txtStepTitle","pbSteps","btnCancel","btnPrevious","btnNext","wizardTabs",
        "txtLangLabel","btnLangFR","btnLangEN","btnLangES","btnLangIT",
        "txtModeTitle","rbOnline","rbCache","rbPreparation","brdConnStatus","txtConnStatus",
        "txtFwTitle","txtFwHelp","txtFwCurrentLabel","txtFwTargetLabel","cbCurrentFw","cbTargetFw","chkSkipFirmware",
        "txtConnTypeTitle","txtConnTypeSubtitle",
        "txt4GTitle","txt4GDesc","txtEthTitle","txtEthDesc","txtDLTitle","txtDLDesc",
        "rb4G","rbEthernet","rbDatalogger",
        "txtNetTitle","txtNetworkSubtitle","pnlNetworkParams",
        "txtCommonTitle","txtCommonSubtitle","pnlCommonParams",
        "txtT2MTitle","txtT2MWarning","txtT2MKeyLabel","txtT2MNoteLabel",
        "tbT2MKey","valT2MKey","tbT2MNote","valT2MNote",
        "txtSDTitle","txtSDSubtitle","lbDrives","btnRefreshDrives","txtDriveInfo",
        "txtSummaryTitle","txtSummaryCheck","txtSummary",
        "txtGenerationTitle","pbGeneration","txtGenerationPercent","lbLog","svProcedure","txtProcedure","txtFinalStatus"
    )
    foreach ($name in $elementNames) {
        $el = $Script:Window.FindName($name)
        if ($el) {
            Set-Variable -Name "ui_$name" -Value $el -Scope Script
        }
    }

    # Initialize state
    Initialize-Network

    # Apply language to all UI controls
    Apply-UILanguage

    # Build dynamic fields
    Build-CommonParameterFields
    Build-NetworkParameterFields

    # Wire events
    Register-NavigationEvents
    Register-Step0Events
    Register-Step1Events
    Register-Step4Events
    Register-Step5Events
    Register-LanguageEvents

    # Window close guard
    $Script:Window.Add_Closing({
        param($sender, $e)
        if ((Get-AppState).IsGenerating) {
            $result = [System.Windows.MessageBox]::Show(
                (T "DlgGenInProgress"), (T "DlgConfirm"), "YesNo", "Warning")
            if ($result -eq "No") { $e.Cancel = $true; return }
        }
        # Clean up background firmware download if running
        Stop-BackgroundFirmwareCache
    })

    return $Script:Window
}

# ============ LANGUAGE ============

function Register-LanguageEvents {
    foreach ($btnName in @("btnLangFR","btnLangEN","btnLangES","btnLangIT")) {
        $btn = Get-Variable -Name "ui_$btnName" -Scope Script -ValueOnly
        $btn.Add_Click({
            param($sender, $e)
            $lang = $sender.Tag
            Set-Language $lang
            Apply-UILanguage
            # Rebuild dynamic fields with new language
            Build-CommonParameterFields
            Build-NetworkParameterFields
        })
    }
    # Highlight default language button
    Update-LanguageButtonHighlight
}

function Update-LanguageButtonHighlight {
    $currentLang = Get-Language
    $brush = [System.Windows.Media.BrushConverter]::new()
    foreach ($langCode in @("FR","EN","ES","IT")) {
        $btn = Get-Variable -Name "ui_btnLang$langCode" -Scope Script -ValueOnly
        if ($langCode -eq $currentLang) {
            $btn.BorderBrush = $brush.ConvertFrom("#FFD700")
            $btn.BorderThickness = [System.Windows.Thickness]::new(2)
        } else {
            $btn.BorderBrush = [System.Windows.Media.Brushes]::Transparent
            $btn.BorderThickness = [System.Windows.Thickness]::new(2)
        }
    }
}

function Apply-UILanguage {
    $Script:StepTitles = Get-StepTitles

    # Window title
    $Script:ui_window = $Script:Window
    $Script:Window.Title = T "WindowTitle"

    # Navigation buttons
    $Script:ui_btnCancel.Content = T "BtnCancel"
    $currentStep = (Get-AppState).CurrentStep
    if ($currentStep -eq 6) {
        $Script:ui_btnNext.Content = T "BtnGenerate"
    } elseif ($currentStep -eq 7) {
        $Script:ui_btnNext.Content = T "BtnClose"
    } else {
        $Script:ui_btnNext.Content = T "BtnNext"
    }
    $Script:ui_btnPrevious.Content = T "BtnPrevious"

    # Step title bar
    $Script:ui_txtStepTitle.Text = (T "StepTitleFormat") -f ($currentStep + 1), $Script:TotalSteps, $Script:StepTitles[$currentStep]

    # Language label
    $Script:ui_txtLangLabel.Text = T "LangLabel"

    # Step 0
    $Script:ui_txtModeTitle.Text = T "ModeTitle"
    $Script:ui_txtFwTitle.Text = T "FwTitle"
    $Script:ui_txtFwHelp.Text = T "FwHelpText"
    $Script:ui_txtFwCurrentLabel.Text = T "FwCurrentLabel"
    $Script:ui_txtFwTargetLabel.Text = T "FwTargetLabel"
    $Script:ui_chkSkipFirmware.Content = T "FwSkipLabel"

    # Step 1
    $Script:ui_txtConnTypeTitle.Text = T "ConnTypeTitle"
    $Script:ui_txtConnTypeSubtitle.Text = T "ConnTypeSubtitle"
    $Script:ui_txt4GTitle.Text = T "Conn4G"
    $Script:ui_txt4GDesc.Text = T "Conn4GDesc"
    $Script:ui_txtEthTitle.Text = T "ConnEthernet"
    $Script:ui_txtEthDesc.Text = T "ConnEthernetDesc"
    $Script:ui_txtDLTitle.Text = T "ConnDatalogger"
    $Script:ui_txtDLDesc.Text = T "ConnDataloggerDesc"

    # Step 2
    $Script:ui_txtNetTitle.Text = T "NetTitle"

    # Step 3
    $Script:ui_txtCommonTitle.Text = T "CommonTitle"
    $Script:ui_txtCommonSubtitle.Text = T "CommonSubtitle"

    # Step 4
    $Script:ui_txtT2MTitle.Text = T "T2MTitle"
    $Script:ui_txtT2MWarning.Text = T "T2MWarning"
    $Script:ui_txtT2MKeyLabel.Text = T "T2MKeyLabel"
    $Script:ui_txtT2MNoteLabel.Text = T "T2MNoteLabel"

    # Step 5
    $Script:ui_txtSDTitle.Text = T "SDTitle"
    $Script:ui_txtSDSubtitle.Text = T "SDSubtitle"
    $Script:ui_btnRefreshDrives.Content = T "SDRefresh"
    $Script:ui_txtDriveInfo.Text = T "SDDriveInfo"

    # Step 6
    $Script:ui_txtSummaryTitle.Text = T "SummaryTitle"
    $Script:ui_txtSummaryCheck.Text = T "SummaryCheck"

    # Step 7
    if (-not (Get-AppState).IsGenerating) {
        $Script:ui_txtGenerationTitle.Text = T "GenTitle"
    }

    # Update button highlight
    Update-LanguageButtonHighlight
}

# ============ NAVIGATION ============

function Show-WizardStep {
    param([int]$StepIndex)

    $state = Get-AppState
    Set-AppStateValue -Key "CurrentStep" -Value $StepIndex
    $Script:StepTitles = Get-StepTitles

    $Script:ui_wizardTabs.SelectedIndex = $StepIndex
    $Script:ui_txtStepTitle.Text = (T "StepTitleFormat") -f ($StepIndex + 1), $Script:TotalSteps, $Script:StepTitles[$StepIndex]
    $Script:ui_pbSteps.Value = $StepIndex + 1

    # Button states
    $Script:ui_btnPrevious.IsEnabled = ($StepIndex -gt 0 -and $StepIndex -lt 7)

    if ($StepIndex -eq 6) {
        $Script:ui_btnNext.Content = T "BtnGenerate"
    } elseif ($StepIndex -eq 7) {
        $Script:ui_btnNext.Content = T "BtnClose"
        $Script:ui_btnNext.IsEnabled = $false
        $Script:ui_btnPrevious.IsEnabled = $false
    } else {
        $Script:ui_btnNext.Content = T "BtnNext"
    }
}

function Get-NextStep {
    param([int]$FromStep)
    $state = Get-AppState
    $next = $FromStep + 1

    if ($next -eq 2 -and $state.Mode -eq "Preparation") { $next = 7 }
    if ($next -eq 3 -and $state.Mode -eq "Preparation") { $next = 7 }
    if ($next -eq 4 -and ($state.ConnectionType -eq "Datalogger" -or $state.Mode -eq "Preparation")) { $next = 5 }
    if ($next -eq 5 -and $state.Mode -eq "Preparation") { $next = 7 }

    return $next
}

function Get-PreviousStep {
    param([int]$FromStep)
    $state = Get-AppState
    $prev = $FromStep - 1

    if ($prev -eq 5 -and $state.Mode -eq "Preparation") { $prev = 1 }
    if ($prev -eq 4 -and ($state.ConnectionType -eq "Datalogger" -or $state.Mode -eq "Preparation")) { $prev = 3 }
    if ($prev -eq 3 -and $state.Mode -eq "Preparation") { $prev = 1 }
    if ($prev -eq 2 -and $state.Mode -eq "Preparation") { $prev = 1 }

    return [Math]::Max(0, $prev)
}

function Validate-CurrentStep {
    param([int]$StepIndex)

    $state = Get-AppState

    switch ($StepIndex) {
        0 {
            if (-not $Script:ui_chkSkipFirmware.IsChecked) {
                if ($Script:ui_cbCurrentFw.SelectedIndex -lt 0) {
                    $null = [System.Windows.MessageBox]::Show((T "DlgSelectCurrentFw"), (T "DlgValidation"), "OK", "Warning")
                    return $false
                }
                if ($Script:ui_cbTargetFw.SelectedIndex -lt 0) {
                    $null = [System.Windows.MessageBox]::Show((T "DlgSelectTargetFw"), (T "DlgValidation"), "OK", "Warning")
                    return $false
                }
            }
            return $true
        }
        1 { return $true }
        2 {
            return Validate-DynamicFields $Script:NetworkFieldMap
        }
        3 {
            return Validate-DynamicFields $Script:CommonFieldMap
        }
        4 {
            if ([string]::IsNullOrWhiteSpace($Script:ui_tbT2MKey.Password)) {
                $null = [System.Windows.MessageBox]::Show((T "DlgT2MKeyRequired"), (T "DlgValidation"), "OK", "Warning")
                return $false
            }
            if ([string]::IsNullOrWhiteSpace($Script:ui_tbT2MNote.Text)) {
                $null = [System.Windows.MessageBox]::Show((T "DlgT2MNoteRequired"), (T "DlgValidation"), "OK", "Warning")
                return $false
            }
            return $true
        }
        5 {
            if ($Script:ui_lbDrives.SelectedIndex -lt 0) {
                $null = [System.Windows.MessageBox]::Show((T "DlgSelectSD"), (T "DlgValidation"), "OK", "Warning")
                return $false
            }
            return $true
        }
        6 { return $true }
        default { return $true }
    }
}

function Validate-DynamicFields {
    param([hashtable]$FieldMap)

    foreach ($entry in $FieldMap.GetEnumerator()) {
        $field = $entry.Value
        if ($field.Container.Visibility -ne [System.Windows.Visibility]::Visible) { continue }

        $value = Get-FieldValue -InputControl $field.InputControl
        $paramDef = $field.ParamDef
        $isRequired = ($null -eq $paramDef.Default) -or ($paramDef.ContainsKey("Required") -and $paramDef.Required -eq $true)

        if ([string]::IsNullOrWhiteSpace($value) -and -not $isRequired -and $null -ne $paramDef.Default) { continue }

        $result = Test-ParameterValue -Type $paramDef.Type -Value $value `
            -ParamName $paramDef.Param -IsRequired $isRequired

        if (-not $result.IsValid) {
            $desc = T $paramDef.Description
            $null = [System.Windows.MessageBox]::Show(
                "$desc : $($result.Message)", (T "DlgValidation"), "OK", "Warning")
            return $false
        }
    }
    return $true
}

function Register-NavigationEvents {
    $Script:ui_btnCancel.Add_Click({
        $result = [System.Windows.MessageBox]::Show(
            (T "DlgQuit"), (T "DlgConfirm"), "YesNo", "Question")
        if ($result -eq "Yes") { $Script:Window.Close() }
    })

    $Script:ui_btnNext.Add_Click({
        try {
            $currentStep = (Get-AppState).CurrentStep

            if ($currentStep -eq 7) {
                $Script:Window.Close()
                return
            }

            if (-not (Validate-CurrentStep -StepIndex $currentStep)) { return }
            Collect-StepState -StepIndex $currentStep

            $nextStep = Get-NextStep -FromStep $currentStep

            if ($nextStep -eq 6) { Build-SummaryText }

            if ($nextStep -eq 7) {
                if ((Get-AppState).Mode -eq "Preparation") {
                    Show-WizardStep -StepIndex $nextStep
                    Start-PreparationMode
                    return
                }
                Show-WizardStep -StepIndex $nextStep
                Start-Generation
                return
            }

            Show-WizardStep -StepIndex $nextStep
        } catch {
            $errMsg = (T "DlgNavError") -f $_.Exception.Message
            [System.Windows.MessageBox]::Show(
                "$errMsg`n`n$($_.ScriptStackTrace)",
                (T "DlgError"), "OK", "Error")
        }
    })

    $Script:ui_btnPrevious.Add_Click({
        $currentStep = (Get-AppState).CurrentStep
        $prevStep = Get-PreviousStep -FromStep $currentStep
        Show-WizardStep -StepIndex $prevStep
    })
}

function Collect-StepState {
    param([int]$StepIndex)

    $state = Get-AppState

    switch ($StepIndex) {
        0 {
            # Mode
            if ($Script:ui_rbOnline.IsChecked)      { Set-AppStateValue -Key "Mode" -Value "Online" }
            elseif ($Script:ui_rbCache.IsChecked)    { Set-AppStateValue -Key "Mode" -Value "Cache" }
            elseif ($Script:ui_rbPreparation.IsChecked) { Set-AppStateValue -Key "Mode" -Value "Preparation" }

            # Firmware
            Set-AppStateValue -Key "SkipFirmwareUpdate" -Value ([bool]$Script:ui_chkSkipFirmware.IsChecked)
            if (-not $Script:ui_chkSkipFirmware.IsChecked) {
                $currentFw = $Script:ui_cbCurrentFw.SelectedItem
                if ($currentFw) { Set-AppStateValue -Key "CurrentFirmware" -Value $currentFw.ToString() }
                $targetItem = $Script:ui_cbTargetFw.SelectedItem
                if ($targetItem -and $targetItem.Tag) {
                    Set-AppStateValue -Key "TargetFirmware" -Value $targetItem.Tag
                }
            }

            # Download manifest + templates + firmware if Online mode
            if ($state.Mode -eq "Online") {
                $manifest = Get-Manifest -OnLog { param($msg) }
                if ($manifest) {
                    Set-AppStateValue -Key "Manifest" -Value $manifest
                    Save-ManifestToCache -Manifest $manifest
                    Download-AllTemplates -OnLog { param($msg) } | Out-Null
                }
            }
        }
        1 {
            # Connection type
            if ($Script:ui_rb4G.IsChecked)          { Set-AppStateValue -Key "ConnectionType" -Value "4G" }
            elseif ($Script:ui_rbEthernet.IsChecked) { Set-AppStateValue -Key "ConnectionType" -Value "Ethernet" }
            elseif ($Script:ui_rbDatalogger.IsChecked) { Set-AppStateValue -Key "ConnectionType" -Value "Datalogger" }

            # Rebuild dynamic params for new connection type
            Build-NetworkParameterFields
            Build-CommonParameterFields

            # Update NTP default for Datalogger
            if ((Get-AppState).ConnectionType -eq "Datalogger") {
                $ntpField = $Script:CommonFieldMap["NtpServerAddr"]
                if ($ntpField -and -not $Script:UserTouched["NtpServerAddr"]) {
                    $ntpField.InputControl.Text = "fr.pool.ntp.org"
                }
            } else {
                $ntpField = $Script:CommonFieldMap["NtpServerAddr"]
                if ($ntpField -and -not $Script:UserTouched["NtpServerAddr"]) {
                    $ntpField.InputControl.Text = "ntp.talk2m.com"
                }
            }
        }
        2 {
            foreach ($entry in $Script:NetworkFieldMap.GetEnumerator()) {
                $field = $entry.Value
                $value = Get-FieldValue -InputControl $field.InputControl
                if ([string]::IsNullOrWhiteSpace($value) -and $field.ParamDef.Default) {
                    $value = $field.ParamDef.Default
                }
                Set-CollectedParam -Name $field.ParamName -Value $value
            }
        }
        3 {
            foreach ($entry in $Script:CommonFieldMap.GetEnumerator()) {
                $field = $entry.Value
                $value = Get-FieldValue -InputControl $field.InputControl
                if ([string]::IsNullOrWhiteSpace($value) -and $field.ParamDef.Default) {
                    $value = $field.ParamDef.Default
                }
                Set-CollectedParam -Name $field.ParamName -Value $value
            }
        }
        4 {
            Set-AppStateValue -Key "T2MKey" -Value $Script:ui_tbT2MKey.Password
            Set-AppStateValue -Key "T2MNote" -Value $Script:ui_tbT2MNote.Text
        }
        5 {
            $selectedItem = $Script:ui_lbDrives.SelectedItem
            if ($selectedItem) {
                $driveLetter = $selectedItem.Tag
                Set-AppStateValue -Key "SdDrive" -Value "$driveLetter\"
            }
        }
    }
}

# ============ STEP 0: MODE + FIRMWARE ============

function Register-Step0Events {
    $Script:ui_chkSkipFirmware.Add_Checked({
        $Script:ui_cbCurrentFw.IsEnabled = $false
        $Script:ui_cbTargetFw.IsEnabled = $false
    })
    $Script:ui_chkSkipFirmware.Add_Unchecked({
        $Script:ui_cbCurrentFw.IsEnabled = $true
        $Script:ui_cbTargetFw.IsEnabled = $true
    })

    $Script:ui_cbCurrentFw.Add_SelectionChanged({
        Update-TargetFirmwareList
    })

    Populate-FirmwareOptions
    Invoke-ConnectivityCheck
}

function Invoke-ConnectivityCheck {
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(200)
    $timer.Add_Tick({
        param($s, $ev)
        $s.Stop()

        $Script:ui_txtConnStatus.Text = T "ConnChecking"
        Update-WpfUI

        $hasInternet = Test-InternetConnectivity
        $hasCache = Test-CacheAvailable
        $brush = [System.Windows.Media.BrushConverter]::new()

        if ($hasInternet) {
            $Script:ui_rbOnline.IsChecked = $true
            $Script:ui_brdConnStatus.Background = $brush.ConvertFrom("#D4EDDA")
            $Script:ui_txtConnStatus.Text = T "ConnCaching"
            Update-WpfUI

            # Eagerly download manifest + templates (small, fast)
            try {
                $manifest = Get-Manifest -OnLog { param($msg) }
                if ($manifest) {
                    Set-AppStateValue -Key "Manifest" -Value $manifest
                    Save-ManifestToCache -Manifest $manifest
                    Download-AllTemplates -OnLog { param($msg) } | Out-Null
                    # Refresh firmware options with fresh manifest data
                    Populate-FirmwareOptions
                }
            } catch {}

            $Script:ui_txtConnStatus.Text = T "ConnOnlineOk"

            # Download all firmwares in a background runspace (truly async, no UI freeze)
            $cachedManifest = (Get-AppState).Manifest
            if ($cachedManifest -and $cachedManifest.firmwares) {
                Start-BackgroundFirmwareCache -Firmwares $cachedManifest.firmwares -CacheDir (Get-LocalCacheDir)

                # Poll progress from UI thread without blocking
                $pollTimer = New-Object System.Windows.Threading.DispatcherTimer
                $pollTimer.Interval = [TimeSpan]::FromMilliseconds(500)
                $pollTimer.Add_Tick({
                    param($sender, $e)
                    $st = $Script:FwCacheState
                    if ($null -eq $st) { $sender.Stop(); return }
                    if ($st.Done) {
                        $sender.Stop()
                        $Script:ui_txtConnStatus.Text = T "ConnOnlineOk"
                        Stop-BackgroundFirmwareCache
                    } else {
                        $Script:ui_txtConnStatus.Text = (T "ConnCachingFw") -f $st.CurrentFw
                    }
                })
                $pollTimer.Start()
            }
        } elseif ($hasCache) {
            $Script:ui_rbCache.IsChecked = $true
            $Script:ui_brdConnStatus.Background = $brush.ConvertFrom("#FFF3CD")
            $Script:ui_txtConnStatus.Text = T "ConnCacheOk"
        } else {
            $Script:ui_rbOnline.IsEnabled = $false
            $Script:ui_rbCache.IsEnabled = $false
            $Script:ui_rbPreparation.IsEnabled = $false
            $Script:ui_brdConnStatus.Background = $brush.ConvertFrom("#F8D7DA")
            $Script:ui_txtConnStatus.Text = T "ConnNoConnection"
            $Script:ui_btnNext.IsEnabled = $false
        }
    })
    $timer.Start()
}

function Populate-FirmwareOptions {
    $Script:ui_cbCurrentFw.Items.Clear()
    $Script:ui_cbTargetFw.Items.Clear()

    $manifest = Get-CachedManifest
    if ($manifest) {
        Set-AppStateValue -Key "Manifest" -Value $manifest
    }

    $availableFirmwares = @()
    if ($manifest) {
        $availableFirmwares = @(Get-AvailableFirmwares -Manifest $manifest)
    }
    Set-AppStateValue -Key "AvailableFirmwares" -Value $availableFirmwares

    $currentOptions = @(Get-CurrentFirmwareOptions -AvailableFirmwares $availableFirmwares)
    foreach ($opt in $currentOptions) {
        $Script:ui_cbCurrentFw.Items.Add($opt) | Out-Null
    }
    if ($currentOptions.Count -gt 0) {
        $preferredIndex = [Array]::IndexOf($currentOptions, "15.x")
        if ($preferredIndex -lt 0) { $preferredIndex = 0 }
        $Script:ui_cbCurrentFw.SelectedIndex = $preferredIndex
    }
}

function Update-TargetFirmwareList {
    $Script:ui_cbTargetFw.Items.Clear()

    $currentSel = $Script:ui_cbCurrentFw.SelectedItem
    if (-not $currentSel) { return }

    $state = Get-AppState
    $compatible = @(Get-CompatibleFirmwares -CurrentFw $currentSel.ToString() -AvailableFirmwares $state.AvailableFirmwares)
    Set-AppStateValue -Key "CompatibleFirmwares" -Value $compatible

    foreach ($fw in $compatible) {
        if (-not $fw) { continue }
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = $fw.Full
        $item.Tag = $fw.Full
        $Script:ui_cbTargetFw.Items.Add($item) | Out-Null
    }

    if ($Script:ui_cbTargetFw.Items.Count -gt 0) {
        $Script:ui_cbTargetFw.SelectedIndex = 0
    }
}

# ============ STEP 1: CONNECTION TYPE ============

function Register-Step1Events {
    # Nothing special needed - radio buttons are read at collect time
}

# ============ STEPS 2 & 3: DYNAMIC PARAMETERS ============

function Build-NetworkParameterFields {
    $Script:ui_pnlNetworkParams.Children.Clear()
    $Script:NetworkFieldMap = @{}
    $Script:NetworkGroupHeaders = @{}

    $state = Get-AppState
    $connType = $state.ConnectionType
    $params = Get-ConnectionParameters -ConnectionType $connType

    $Script:ui_txtNetworkSubtitle.Text = switch ($connType) {
        "4G"         { T "NetSubtitle4G" }
        "Ethernet"   { T "NetSubtitleEth" }
        "Datalogger" { T "NetSubtitleDL" }
        default      { T "NetSubtitleDefault" }
    }

    $lastGroup = $null
    foreach ($paramDef in $params) {
        # Insert section header when group changes
        if ($paramDef.Group -and $paramDef.Group -ne $lastGroup) {
            $header = New-SectionHeader -Title (T $paramDef.Group)
            $Script:ui_pnlNetworkParams.Children.Add($header) | Out-Null
            $Script:NetworkGroupHeaders[$paramDef.Group] = $header
            $lastGroup = $paramDef.Group
        }

        $field = New-ParamFieldRow -ParamDef $paramDef -NamePrefix "net"
        $Script:ui_pnlNetworkParams.Children.Add($field.Container) | Out-Null
        $Script:NetworkFieldMap[$paramDef.Param] = $field

        Wire-FieldValidation -Field $field -FieldMap $Script:NetworkFieldMap
    }

    # Seed CollectedParams with default/current values so conditions evaluate correctly
    foreach ($entry in $Script:NetworkFieldMap.GetEnumerator()) {
        $field = $entry.Value
        $value = Get-FieldValue -InputControl $field.InputControl
        if ([string]::IsNullOrWhiteSpace($value) -and $field.ParamDef.Default) {
            $value = $field.ParamDef.Default
        }
        Set-CollectedParam -Name $field.ParamName -Value $value
    }

    # Apply initial condition visibility
    Update-FieldVisibility -FieldMap $Script:NetworkFieldMap
    Update-GroupHeaderVisibility -FieldMap $Script:NetworkFieldMap -GroupHeaders $Script:NetworkGroupHeaders
}

function Build-CommonParameterFields {
    $Script:ui_pnlCommonParams.Children.Clear()
    $Script:CommonFieldMap = @{}
    $Script:CommonGroupHeaders = @{}

    $params = Get-CommonParameters

    $lastGroup = $null
    foreach ($paramDef in $params) {
        # Insert section header when group changes
        if ($paramDef.Group -and $paramDef.Group -ne $lastGroup) {
            $header = New-SectionHeader -Title (T $paramDef.Group)
            $Script:ui_pnlCommonParams.Children.Add($header) | Out-Null
            $Script:CommonGroupHeaders[$paramDef.Group] = $header
            $lastGroup = $paramDef.Group
        }

        $field = New-ParamFieldRow -ParamDef $paramDef -NamePrefix "common"
        $Script:ui_pnlCommonParams.Children.Add($field.Container) | Out-Null
        $Script:CommonFieldMap[$paramDef.Param] = $field

        Wire-FieldValidation -Field $field -FieldMap $Script:CommonFieldMap

        # Track user touches for NTP
        if ($paramDef.Param -eq "NtpServerAddr") {
            $field.InputControl.Add_TextChanged({
                $Script:UserTouched["NtpServerAddr"] = $true
            })
        }
    }

    # Seed CollectedParams with default/current values
    foreach ($entry in $Script:CommonFieldMap.GetEnumerator()) {
        $field = $entry.Value
        $value = Get-FieldValue -InputControl $field.InputControl
        if ([string]::IsNullOrWhiteSpace($value) -and $field.ParamDef.Default) {
            $value = $field.ParamDef.Default
        }
        Set-CollectedParam -Name $field.ParamName -Value $value
    }

    Update-FieldVisibility -FieldMap $Script:CommonFieldMap
    Update-GroupHeaderVisibility -FieldMap $Script:CommonFieldMap -GroupHeaders $Script:CommonGroupHeaders
}

# ============ FIELD VALIDATION WIRING ============

function Wire-FieldValidation {
    param(
        [hashtable]$Field,
        [hashtable]$FieldMap
    )

    $paramDef = $Field.ParamDef
    $control = $Field.InputControl
    $valIcon = $Field.ValidationIcon

    if ($control -is [System.Windows.Controls.TextBox]) {
        $control.Add_TextChanged({
            param($sender, $e)
            $pName = $sender.Tag
            if (-not $pName) { return }
            $f = $null
            if ($Script:NetworkFieldMap -and $Script:NetworkFieldMap.ContainsKey($pName)) {
                $f = $Script:NetworkFieldMap[$pName]
            } elseif ($Script:CommonFieldMap -and $Script:CommonFieldMap.ContainsKey($pName)) {
                $f = $Script:CommonFieldMap[$pName]
            }
            if (-not $f) { return }

            $val = $sender.Text
            Set-CollectedParam -Name $pName -Value $val

            if ([string]::IsNullOrWhiteSpace($val)) {
                if ($f.ParamDef.ContainsKey("Required") -and $f.ParamDef.Required -eq $true) {
                    Update-ValidationIcon -Icon $f.ValidationIcon -IsValid $false -Message (T "ValRequired")
                } else {
                    Clear-ValidationIcon -Icon $f.ValidationIcon
                }
            } else {
                $result = Test-ParameterValue -Type $f.ParamDef.Type -Value $val -ParamName $pName
                Update-ValidationIcon -Icon $f.ValidationIcon -IsValid $result.IsValid -Message $result.Message
            }
        })
    }
    elseif ($control -is [System.Windows.Controls.PasswordBox]) {
        $control.Add_PasswordChanged({
            param($sender, $e)
            $pName = $sender.Tag
            if (-not $pName) { return }
            $f = $null
            if ($Script:NetworkFieldMap -and $Script:NetworkFieldMap.ContainsKey($pName)) {
                $f = $Script:NetworkFieldMap[$pName]
            } elseif ($Script:CommonFieldMap -and $Script:CommonFieldMap.ContainsKey($pName)) {
                $f = $Script:CommonFieldMap[$pName]
            }
            if (-not $f) { return }

            $val = $sender.Password
            Set-CollectedParam -Name $pName -Value $val

            if ([string]::IsNullOrWhiteSpace($val)) {
                Clear-ValidationIcon -Icon $f.ValidationIcon
            } else {
                Update-ValidationIcon -Icon $f.ValidationIcon -IsValid $true -Message ""
            }
        })
    }
    elseif ($control -is [System.Windows.Controls.ComboBox]) {
        $control.Add_SelectionChanged({
            param($sender, $e)
            $pName = $sender.Tag
            if (-not $pName) { return }
            $selectedItem = $sender.SelectedItem
            if ($selectedItem -and $selectedItem.Tag) {
                $val = $selectedItem.Tag
                Set-CollectedParam -Name $pName -Value $val
                # Re-evaluate conditional visibility for both field maps
                if ($Script:NetworkFieldMap) {
                    Update-FieldVisibility -FieldMap $Script:NetworkFieldMap
                }
                if ($Script:CommonFieldMap) {
                    Update-FieldVisibility -FieldMap $Script:CommonFieldMap
                }
            }
        })
    }
}

function Update-FieldVisibility {
    param([hashtable]$FieldMap)

    $collectedParams = (Get-AppState).CollectedParams

    foreach ($entry in $FieldMap.GetEnumerator()) {
        $field = $entry.Value
        if ($field.ParamDef.Condition) {
            $visible = Test-ParameterCondition -Condition $field.ParamDef.Condition -CollectedParams $collectedParams
            Set-FieldVisibility -Container $field.Container -Visible $visible

            # Reset hidden fields to default
            if (-not $visible -and $field.ParamDef.Default) {
                Set-CollectedParam -Name $field.ParamName -Value $field.ParamDef.Default
            }
        }
    }

    # Update group header visibility
    if ($FieldMap -eq $Script:NetworkFieldMap -and $Script:NetworkGroupHeaders.Count -gt 0) {
        Update-GroupHeaderVisibility -FieldMap $FieldMap -GroupHeaders $Script:NetworkGroupHeaders
    } elseif ($FieldMap -eq $Script:CommonFieldMap -and $Script:CommonGroupHeaders.Count -gt 0) {
        Update-GroupHeaderVisibility -FieldMap $FieldMap -GroupHeaders $Script:CommonGroupHeaders
    }
}

function Update-GroupHeaderVisibility {
    param(
        [hashtable]$FieldMap,
        [hashtable]$GroupHeaders
    )

    foreach ($groupName in @($GroupHeaders.Keys)) {
        $anyVisible = $false
        foreach ($entry in $FieldMap.GetEnumerator()) {
            if ($entry.Value.ParamDef.Group -eq $groupName -and
                $entry.Value.Container.Visibility -eq [System.Windows.Visibility]::Visible) {
                $anyVisible = $true
                break
            }
        }
        Set-FieldVisibility -Container $GroupHeaders[$groupName] -Visible $anyVisible
    }
}

# ============ STEP 4: TALK2M ============

function Register-Step4Events {
    $Script:ui_tbT2MKey.Add_PasswordChanged({
        $val = $Script:ui_tbT2MKey.Password
        if ([string]::IsNullOrWhiteSpace($val)) {
            Clear-ValidationIcon -Icon $Script:ui_valT2MKey
        } else {
            Update-ValidationIcon -Icon $Script:ui_valT2MKey -IsValid $true
        }
    })

    $Script:ui_tbT2MNote.Add_TextChanged({
        $val = $Script:ui_tbT2MNote.Text
        if ([string]::IsNullOrWhiteSpace($val)) {
            Clear-ValidationIcon -Icon $Script:ui_valT2MNote
        } else {
            Update-ValidationIcon -Icon $Script:ui_valT2MNote -IsValid $true
        }
    })
}

# ============ STEP 5: SD DRIVE ============

function Register-Step5Events {
    $Script:ui_btnRefreshDrives.Add_Click({ Refresh-DriveList })
    Refresh-DriveList
}

function Refresh-DriveList {
    $Script:ui_lbDrives.Items.Clear()
    $drives = @(Get-RemovableDrives)

    if ($drives.Count -eq 0 -or ($drives.Count -eq 1 -and $null -eq $drives[0])) {
        $Script:ui_txtDriveInfo.Text = T "SDNoDrive"
    } else {
        $Script:ui_txtDriveInfo.Text = (T "SDDriveCount") -f $drives.Count
        foreach ($d in $drives) {
            if (-not $d) { continue }
            $item = New-Object System.Windows.Controls.ListBoxItem
            $item.Content = $d.Display
            $item.Tag = $d.DeviceID
            $item.FontSize = 13
            $Script:ui_lbDrives.Items.Add($item) | Out-Null
        }
        if ($Script:ui_lbDrives.Items.Count -eq 1) {
            $Script:ui_lbDrives.SelectedIndex = 0
        }
    }
}

# ============ STEP 6: SUMMARY ============

function Build-SummaryText {
    $state = Get-AppState
    $sb = [System.Text.StringBuilder]::new()

    [void]$sb.AppendLine("$(T 'SumMode') : $($state.Mode)")
    [void]$sb.AppendLine("$(T 'SumConnType') : $($state.ConnectionType)")
    [void]$sb.AppendLine("")

    if ($state.SkipFirmwareUpdate) {
        [void]$sb.AppendLine("$(T 'SumFw') : $(T 'SumFwSkip')")
    } else {
        [void]$sb.AppendLine("$(T 'SumFw') : $($state.CurrentFirmware) -> $($state.TargetFirmware)")
    }
    [void]$sb.AppendLine("$(T 'SumSD') : $($state.SdDrive)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine((T "SumParams"))

    # Collect final values for display
    Collect-StepState -StepIndex 2
    Collect-StepState -StepIndex 3

    foreach ($key in ($state.CollectedParams.Keys | Sort-Object)) {
        $value = $state.CollectedParams[$key]
        $paramDef = (Get-ParameterDefinitions) | Where-Object { $_.Param -eq $key } | Select-Object -First 1
        if ($paramDef -and $paramDef.Type -eq "Password" -and $value) {
            $value = "********"
        }
        [void]$sb.AppendLine("  $key = $value")
    }

    if ($state.ConnectionType -ne "Datalogger" -and $state.Mode -ne "Preparation") {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine((T "SumT2M"))
        [void]$sb.AppendLine("  T2MKey = ********")
        [void]$sb.AppendLine("  Description = $($state.T2MNote)")
    }

    $Script:ui_txtSummary.Text = $sb.ToString()
}

# ============ STEP 7: GENERATION ============

function Start-Generation {
    Set-AppStateValue -Key "IsGenerating" -Value $true
    $Script:ui_btnNext.IsEnabled = $false
    $Script:ui_btnPrevious.IsEnabled = $false
    $Script:ui_btnCancel.IsEnabled = $false

    $state = Get-AppState

    # Load manifest if Online mode
    if ($state.Mode -eq "Online") {
        Add-LogEntry (T "ProgOnlineDownload")
        try {
            $manifest = Get-Manifest -OnLog { param($msg) }
            if (-not $manifest) { throw (T "ProgManifestFail") }
            Set-AppStateValue -Key "Manifest" -Value $manifest
            Save-ManifestToCache -Manifest $manifest
            $ok = Download-AllTemplates -OnLog { param($msg) }
            if (-not $ok) { throw (T "ProgTemplateFail") }
            Add-LogEntry (T "ProgResourcesOk")
        } catch {
            Add-LogEntry "$(T 'ErrorPrefix') $($_.Exception.Message)"
            Set-AppStateValue -Key "IsGenerating" -Value $false
            $Script:ui_txtFinalStatus.Text = "$(T 'DlgError'): $($_.Exception.Message)"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Red
            $Script:ui_btnNext.Content = T "BtnClose"
            $Script:ui_btnNext.IsEnabled = $true
            return
        }
    } elseif ($state.Mode -eq "Cache") {
        if (-not (Test-CacheAvailable)) {
            Add-LogEntry "$(T 'ErrorPrefix') $(T 'ProgCacheUnavail')"
            $Script:ui_txtFinalStatus.Text = "$(T 'DlgError'): $(T 'ProgCacheUnavail')"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Red
            Set-AppStateValue -Key "IsGenerating" -Value $false
            $Script:ui_btnNext.Content = T "BtnClose"
            $Script:ui_btnNext.IsEnabled = $true
            return
        }
        $manifest = Get-CachedManifest
        Set-AppStateValue -Key "Manifest" -Value $manifest
    }

    # Run generation using a dispatcher timer to keep UI responsive
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        param($sender, $e)
        $sender.Stop()

        try {
            $currentState = Get-AppState

            Invoke-Generation -State $currentState `
                -OnProgress {
                    param($Percent, $Message)
                    $Script:ui_pbGeneration.Value = $Percent
                    $Script:ui_txtGenerationPercent.Text = "$Percent% - $Message"
                    Update-WpfUI
                } `
                -OnLog {
                    param($Message)
                    Add-LogEntry $Message
                    Update-WpfUI
                }

            $Script:ui_txtGenerationTitle.Text = T "GenComplete"
            $Script:ui_txtFinalStatus.Text = T "GenSuccess"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Green

            # Display procedure in WPF
            $procText = (Get-AppState).ProcedureText
            if ($procText) {
                $Script:ui_lbLog.Visibility = [System.Windows.Visibility]::Collapsed
                $Script:ui_pbGeneration.Visibility = [System.Windows.Visibility]::Collapsed
                $Script:ui_txtGenerationPercent.Visibility = [System.Windows.Visibility]::Collapsed
                $Script:ui_svProcedure.Visibility = [System.Windows.Visibility]::Visible
                $Script:ui_txtProcedure.Text = $procText
                $Script:ui_txtGenerationTitle.Text = T "GenProcTitle"
            }
        } catch {
            $Script:ui_txtFinalStatus.Text = "$(T 'DlgError'): $($_.Exception.Message)"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Red
            Add-LogEntry "$(T 'ErrorPrefix') $($_.Exception.Message)"
        } finally {
            Set-AppStateValue -Key "IsGenerating" -Value $false
            $Script:ui_btnNext.Content = T "BtnClose"
            $Script:ui_btnNext.IsEnabled = $true
            $Script:ui_btnCancel.IsEnabled = $true
        }
    })
    $timer.Start()
}

function Start-PreparationMode {
    Set-AppStateValue -Key "IsGenerating" -Value $true
    $Script:ui_btnNext.IsEnabled = $false
    $Script:ui_btnCancel.IsEnabled = $false

    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        param($sender, $e)
        $sender.Stop()

        try {
            Add-LogEntry (T "ProgPreparation")

            # Manifest
            $Script:ui_pbGeneration.Value = 10
            $Script:ui_txtGenerationPercent.Text = "10% - $(T 'ProgManifest')"
            Update-WpfUI

            $manifest = Get-Manifest -OnLog { param($msg) Add-LogEntry $msg; Update-WpfUI }
            if (-not $manifest) { throw (T "ProgManifestFailOnline") }
            Save-ManifestToCache -Manifest $manifest
            Set-AppStateValue -Key "Manifest" -Value $manifest
            Add-LogEntry (T "ProgManifestOk")

            # Templates
            $Script:ui_pbGeneration.Value = 30
            $Script:ui_txtGenerationPercent.Text = "30% - $(T 'ProgTemplates')"
            Update-WpfUI

            $ok = Download-AllTemplates -OnLog { param($msg) Add-LogEntry $msg; Update-WpfUI }
            if (-not $ok) { throw (T "ProgTemplateFail") }

            # Firmwares
            $Script:ui_pbGeneration.Value = 50
            $Script:ui_txtGenerationPercent.Text = "50% - $(T 'ProgFirmwares')"
            Update-WpfUI

            foreach ($fw in @($manifest.firmwares)) {
                $hasEbu = [bool]$fw.hasEbu
                Download-HMSFirmware -Version $fw.version -HasEbu $hasEbu `
                    -OnLog { param($msg) Add-LogEntry $msg; Update-WpfUI } | Out-Null
            }

            $Script:ui_pbGeneration.Value = 100
            $Script:ui_txtGenerationPercent.Text = "100% - $(T 'ProgDone')"

            $cacheDir = Get-LocalCacheDir
            $Script:ui_txtGenerationTitle.Text = T "PrepTitle"
            $Script:ui_txtFinalStatus.Text = T "PrepSuccess"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Green
            Add-LogEntry ""
            Add-LogEntry "Cache: $cacheDir"
        } catch {
            $Script:ui_txtFinalStatus.Text = "$(T 'DlgError'): $($_.Exception.Message)"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Red
            Add-LogEntry "$(T 'ErrorPrefix') $($_.Exception.Message)"
        } finally {
            Set-AppStateValue -Key "IsGenerating" -Value $false
            $Script:ui_btnNext.Content = T "BtnClose"
            $Script:ui_btnNext.IsEnabled = $true
            $Script:ui_btnCancel.IsEnabled = $true
        }
    })
    $timer.Start()
}

function Add-LogEntry {
    param([string]$Message)
    $ts = (Get-Date).ToString("HH:mm:ss")
    $text = "[$ts] $Message"
    $idx = $Script:ui_lbLog.Items.Add($text)
    $Script:ui_lbLog.ScrollIntoView($Script:ui_lbLog.Items[$idx])
    Update-WpfUI
}

function Update-WpfUI {
    # Force WPF to process pending UI updates
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $null = [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
        [System.Windows.Threading.DispatcherPriority]::Background,
        [Action]{ $frame.Continue = $false }
    )
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}
