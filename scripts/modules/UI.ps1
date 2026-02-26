# UI.ps1 - WPF Wizard window, XAML definition, event wiring

$Script:StepTitles = @(
    "Mode et Firmware"
    "Type de connexion"
    "Parametres reseau"
    "Parametres communs"
    "Identifiants Talk2M"
    "Selection lecteur SD"
    "Resume"
    "Generation"
)
$Script:TotalSteps = 8

# Field maps for dynamic panels
$Script:NetworkFieldMap = @{}
$Script:CommonFieldMap  = @{}
$Script:UserTouched     = @{}  # track manually modified fields

$Script:MainXaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Preparation Carte SD Ewon Flexy"
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
  </Window.Resources>

  <DockPanel>
    <!-- Top bar -->
    <Border DockPanel.Dock="Top" Background="#1A5276" Padding="18,12">
      <StackPanel>
        <TextBlock x:Name="txtStepTitle" Foreground="White" FontSize="15" FontWeight="SemiBold"
                   Text="Etape 1 / 8 - Mode et Firmware"/>
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
          <Button x:Name="btnPrevious" Content="&#x25C0; Precedent" Style="{StaticResource NavBtn}" IsEnabled="False"/>
          <Button x:Name="btnNext" Content="Suivant &#x25B6;" Style="{StaticResource NavBtn}"
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
            <TextBlock Text="Mode de fonctionnement" Style="{StaticResource StepHeader}"/>

            <RadioButton x:Name="rbOnline" GroupName="Mode" IsChecked="True" Style="{StaticResource RadioOpt}">
              <StackPanel>
                <TextBlock FontWeight="SemiBold" Text="ONLINE"/>
                <TextBlock Text="Telecharger manifest + templates (Internet requis)" Style="{StaticResource SubText}"/>
              </StackPanel>
            </RadioButton>
            <RadioButton x:Name="rbCache" GroupName="Mode" Style="{StaticResource RadioOpt}">
              <StackPanel>
                <TextBlock FontWeight="SemiBold" Text="CACHE"/>
                <TextBlock Text="Utiliser les fichiers deja telecharges" Style="{StaticResource SubText}"/>
              </StackPanel>
            </RadioButton>
            <RadioButton x:Name="rbPreparation" GroupName="Mode" Style="{StaticResource RadioOpt}">
              <StackPanel>
                <TextBlock FontWeight="SemiBold" Text="PREPARATION"/>
                <TextBlock Text="Tout telecharger pour usage offline (pas de carte SD)" Style="{StaticResource SubText}"/>
              </StackPanel>
            </RadioButton>

            <Separator Margin="0,14"/>
            <TextBlock Text="Firmware" Style="{StaticResource StepHeader}"/>
            <TextBlock Text="Si inconnu : demarrer l'Ewon sans SD et lire via eBuddy." Style="{StaticResource SubText}"/>

            <StackPanel Orientation="Horizontal" Margin="0,5">
              <TextBlock Text="Firmware actuel :" VerticalAlignment="Center" Width="130"/>
              <ComboBox x:Name="cbCurrentFw" Width="180"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" Margin="0,8">
              <TextBlock Text="Firmware cible :" VerticalAlignment="Center" Width="130"/>
              <ComboBox x:Name="cbTargetFw" Width="180"/>
            </StackPanel>
            <CheckBox x:Name="chkSkipFirmware" Content="Configuration uniquement (pas de mise a jour firmware)"
                      Margin="0,10" FontSize="12"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- Step 1: Connection type -->
      <TabItem>
        <StackPanel Margin="5">
          <TextBlock Text="Type de connexion" Style="{StaticResource StepHeader}"/>
          <TextBlock Text="Choisissez le mode de communication de l'Ewon Flexy." Style="{StaticResource SubText}"/>

          <Border BorderBrush="#DDD" BorderThickness="1" CornerRadius="4" Padding="15" Margin="0,8">
            <RadioButton x:Name="rb4G" GroupName="ConnType" IsChecked="True" Style="{StaticResource RadioOpt}">
              <StackPanel>
                <TextBlock FontWeight="SemiBold" Text="Modem 4G"/>
                <TextBlock Text="Connexion cellulaire via carte SIM" Style="{StaticResource SubText}"/>
              </StackPanel>
            </RadioButton>
          </Border>
          <Border BorderBrush="#DDD" BorderThickness="1" CornerRadius="4" Padding="15" Margin="0,4">
            <RadioButton x:Name="rbEthernet" GroupName="ConnType" Style="{StaticResource RadioOpt}">
              <StackPanel>
                <TextBlock FontWeight="SemiBold" Text="Ethernet"/>
                <TextBlock Text="Connexion filaire (DHCP ou IP statique, proxy optionnel)" Style="{StaticResource SubText}"/>
              </StackPanel>
            </RadioButton>
          </Border>
          <Border BorderBrush="#DDD" BorderThickness="1" CornerRadius="4" Padding="15" Margin="0,4">
            <RadioButton x:Name="rbDatalogger" GroupName="ConnType" Style="{StaticResource RadioOpt}">
              <StackPanel>
                <TextBlock FontWeight="SemiBold" Text="Datalogger (LAN uniquement)"/>
                <TextBlock Text="Communication via LAN, pas de Talk2M" Style="{StaticResource SubText}"/>
              </StackPanel>
            </RadioButton>
          </Border>
        </StackPanel>
      </TabItem>

      <!-- Step 2: Network parameters (dynamic) -->
      <TabItem>
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel Margin="5">
            <TextBlock Text="Parametres reseau" Style="{StaticResource StepHeader}"/>
            <TextBlock x:Name="txtNetworkSubtitle" Style="{StaticResource SubText}"
                       Text="Configurez les parametres specifiques a votre connexion."/>
            <StackPanel x:Name="pnlNetworkParams"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- Step 3: Common parameters (dynamic) -->
      <TabItem>
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel Margin="5">
            <TextBlock Text="Parametres communs" Style="{StaticResource StepHeader}"/>
            <TextBlock Text="Ces parametres sont utilises quel que soit le type de connexion."
                       Style="{StaticResource SubText}"/>
            <StackPanel x:Name="pnlCommonParams"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- Step 4: Talk2M -->
      <TabItem>
        <StackPanel Margin="5">
          <TextBlock Text="Identifiants Talk2M" Style="{StaticResource StepHeader}"/>
          <Border Background="#FFF3CD" Padding="10" CornerRadius="4" Margin="0,0,0,15">
            <TextBlock Text="Ces donnees ne sont JAMAIS mises en cache."
                       FontSize="11" TextWrapping="Wrap"/>
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

            <TextBlock Text="Cle globale d'enregistrement :" Grid.Row="0" VerticalAlignment="Center" TextWrapping="Wrap"/>
            <PasswordBox x:Name="tbT2MKey" Grid.Row="0" Grid.Column="1" Height="28" FontSize="12"/>
            <TextBlock x:Name="valT2MKey" Grid.Row="0" Grid.Column="2" FontSize="14"
                       VerticalAlignment="Center" HorizontalAlignment="Center"/>

            <TextBlock Text="Description Ewon Talk2M :" Grid.Row="2" VerticalAlignment="Center" TextWrapping="Wrap"/>
            <TextBox x:Name="tbT2MNote" Grid.Row="2" Grid.Column="1" Height="28" FontSize="12"/>
            <TextBlock x:Name="valT2MNote" Grid.Row="2" Grid.Column="2" FontSize="14"
                       VerticalAlignment="Center" HorizontalAlignment="Center"/>
          </Grid>
        </StackPanel>
      </TabItem>

      <!-- Step 5: SD Drive -->
      <TabItem>
        <StackPanel Margin="5">
          <TextBlock Text="Selection du lecteur SD" Style="{StaticResource StepHeader}"/>
          <TextBlock Text="Inserez la carte SD puis selectionnez le lecteur ci-dessous."
                     Style="{StaticResource SubText}"/>

          <ListBox x:Name="lbDrives" Height="160" FontSize="13" Margin="0,5"/>
          <Button x:Name="btnRefreshDrives" Content="Actualiser les lecteurs" Width="160"
                  HorizontalAlignment="Left" Margin="0,8" Height="30"/>
          <TextBlock x:Name="txtDriveInfo" Foreground="#888" Margin="0,8" FontSize="11"
                     Text="Seuls les lecteurs amovibles sont affiches."/>
        </StackPanel>
      </TabItem>

      <!-- Step 6: Summary -->
      <TabItem>
        <ScrollViewer VerticalScrollBarVisibility="Auto">
          <StackPanel Margin="5">
            <TextBlock Text="Resume de la configuration" Style="{StaticResource StepHeader}"/>
            <Border Background="#EAF2F8" Padding="12" CornerRadius="4" Margin="0,0,0,10">
              <TextBlock Text="Verifiez tous les parametres avant de lancer la generation."
                         FontSize="12" FontWeight="SemiBold" Foreground="#1A5276"/>
            </Border>
            <TextBlock x:Name="txtSummary" FontFamily="Consolas" FontSize="11.5"
                       TextWrapping="Wrap"/>
          </StackPanel>
        </ScrollViewer>
      </TabItem>

      <!-- Step 7: Progress -->
      <TabItem>
        <StackPanel Margin="5">
          <TextBlock x:Name="txtGenerationTitle" Text="Generation en cours..."
                     Style="{StaticResource StepHeader}"/>
          <ProgressBar x:Name="pbGeneration" Height="22" Minimum="0" Maximum="100"
                       Margin="0,8" Foreground="#27AE60"/>
          <TextBlock x:Name="txtGenerationPercent" HorizontalAlignment="Center"
                     FontSize="13" Margin="0,4"/>
          <ListBox x:Name="lbLog" Height="280" FontFamily="Consolas" FontSize="11"
                   Margin="0,12,0,0" Background="#1E1E1E" Foreground="#D4D4D4"
                   BorderThickness="0"/>
          <TextBlock x:Name="txtFinalStatus" FontSize="15" FontWeight="Bold"
                     HorizontalAlignment="Center" Margin="0,10"/>
        </StackPanel>
      </TabItem>
    </TabControl>
  </DockPanel>
</Window>
'@

function Initialize-MainWindow {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    # Parse XAML
    [xml]$xaml = $Script:MainXaml
    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $Script:Window = [System.Windows.Markup.XamlReader]::Load($reader)

    # Bind all named elements to script variables
    $elementNames = @(
        "txtStepTitle","pbSteps","btnCancel","btnPrevious","btnNext","wizardTabs",
        "rbOnline","rbCache","rbPreparation","cbCurrentFw","cbTargetFw","chkSkipFirmware",
        "rb4G","rbEthernet","rbDatalogger","pnlNetworkParams","txtNetworkSubtitle","pnlCommonParams",
        "tbT2MKey","valT2MKey","tbT2MNote","valT2MNote",
        "lbDrives","btnRefreshDrives","txtDriveInfo",
        "txtSummary",
        "txtGenerationTitle","pbGeneration","txtGenerationPercent","lbLog","txtFinalStatus"
    )
    foreach ($name in $elementNames) {
        $el = $Script:Window.FindName($name)
        if ($el) {
            Set-Variable -Name "ui_$name" -Value $el -Scope Script
        }
    }

    # Initialize state
    Initialize-Network

    # Build dynamic fields
    Build-CommonParameterFields
    Build-NetworkParameterFields

    # Wire events
    Register-NavigationEvents
    Register-Step0Events
    Register-Step1Events
    Register-Step4Events
    Register-Step5Events

    # Window close guard
    $Script:Window.Add_Closing({
        param($sender, $e)
        if ((Get-AppState).IsGenerating) {
            $result = [System.Windows.MessageBox]::Show(
                "Une generation est en cours. Voulez-vous vraiment quitter?",
                "Confirmation", "YesNo", "Warning")
            if ($result -eq "No") { $e.Cancel = $true }
        }
    })

    return $Script:Window
}

# ============ NAVIGATION ============

function Show-WizardStep {
    param([int]$StepIndex)

    $state = Get-AppState
    Set-AppStateValue -Key "CurrentStep" -Value $StepIndex

    $Script:ui_wizardTabs.SelectedIndex = $StepIndex
    $Script:ui_txtStepTitle.Text = "Etape $($StepIndex + 1) / $Script:TotalSteps - $($Script:StepTitles[$StepIndex])"
    $Script:ui_pbSteps.Value = $StepIndex + 1

    # Button states
    $Script:ui_btnPrevious.IsEnabled = ($StepIndex -gt 0 -and $StepIndex -lt 7)

    if ($StepIndex -eq 6) {
        $Script:ui_btnNext.Content = "Generer"
    } elseif ($StepIndex -eq 7) {
        $Script:ui_btnNext.Content = "Fermer"
        $Script:ui_btnNext.IsEnabled = $false
        $Script:ui_btnPrevious.IsEnabled = $false
    } else {
        $Script:ui_btnNext.Content = "Suivant $([char]0x25B6)"
    }
}

function Get-NextStep {
    param([int]$FromStep)
    $state = Get-AppState
    $next = $FromStep + 1

    # Skip network params if Preparation mode (step 2)
    # Actually, we still need params for Preparation mode? No - Preparation is download-only
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
            # Mode is always selected (radio). Firmware validation.
            if (-not $Script:ui_chkSkipFirmware.IsChecked) {
                if ($Script:ui_cbCurrentFw.SelectedIndex -lt 0) {
                    $null = [System.Windows.MessageBox]::Show("Selectionnez le firmware actuel.", "Validation", "OK", "Warning")
                    return $false
                }
                if ($Script:ui_cbTargetFw.SelectedIndex -lt 0) {
                    $null = [System.Windows.MessageBox]::Show("Selectionnez le firmware cible (ou cochez 'Configuration uniquement').", "Validation", "OK", "Warning")
                    return $false
                }
            }
            return $true
        }
        1 { return $true }  # radio always has selection
        2 {
            # Validate visible network fields
            return Validate-DynamicFields $Script:NetworkFieldMap
        }
        3 {
            # Validate common fields
            return Validate-DynamicFields $Script:CommonFieldMap
        }
        4 {
            # T2M
            if ([string]::IsNullOrWhiteSpace($Script:ui_tbT2MKey.Password)) {
                $null = [System.Windows.MessageBox]::Show("La cle globale d'enregistrement Talk2M est obligatoire.", "Validation", "OK", "Warning")
                return $false
            }
            if ([string]::IsNullOrWhiteSpace($Script:ui_tbT2MNote.Text)) {
                $null = [System.Windows.MessageBox]::Show("La description Ewon Talk2M est obligatoire.", "Validation", "OK", "Warning")
                return $false
            }
            return $true
        }
        5 {
            # SD drive
            if ($Script:ui_lbDrives.SelectedIndex -lt 0) {
                $null = [System.Windows.MessageBox]::Show("Selectionnez un lecteur SD.", "Validation", "OK", "Warning")
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
        # Skip hidden fields
        if ($field.Container.Visibility -ne [System.Windows.Visibility]::Visible) { continue }

        $value = Get-FieldValue -InputControl $field.InputControl
        $paramDef = $field.ParamDef

        # Skip empty fields that have a default (including empty string default = optional)
        if ([string]::IsNullOrWhiteSpace($value) -and $null -ne $paramDef.Default) { continue }

        $result = Test-ParameterValue -Type $paramDef.Type -Value $value `
            -ParamName $paramDef.Param -IsRequired ($null -eq $paramDef.Default)

        if (-not $result.IsValid) {
            $null = [System.Windows.MessageBox]::Show(
                "$($paramDef.Description): $($result.Message)", "Validation", "OK", "Warning")
            return $false
        }
    }
    return $true
}

function Register-NavigationEvents {
    $Script:ui_btnCancel.Add_Click({
        $result = [System.Windows.MessageBox]::Show(
            "Voulez-vous vraiment quitter?", "Confirmation", "YesNo", "Question")
        if ($result -eq "Yes") { $Script:Window.Close() }
    })

    $Script:ui_btnNext.Add_Click({
        try {
            $currentStep = (Get-AppState).CurrentStep

            # If on final step (generation complete), close
            if ($currentStep -eq 7) {
                $Script:Window.Close()
                return
            }

            # Validate current step
            if (-not (Validate-CurrentStep -StepIndex $currentStep)) { return }

            # Collect state from current step
            Collect-StepState -StepIndex $currentStep

            $nextStep = Get-NextStep -FromStep $currentStep

            # Build summary before showing it
            if ($nextStep -eq 6) { Build-SummaryText }

            # Start generation when moving to step 7
            if ($nextStep -eq 7) {
                # For Preparation mode, run download-only generation
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
            [System.Windows.MessageBox]::Show(
                "Erreur navigation: $($_.Exception.Message)`n`n$($_.ScriptStackTrace)",
                "Erreur", "OK", "Error")
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
            Set-AppStateValue -Key "SkipFirmwareUpdate" -Value $Script:ui_chkSkipFirmware.IsChecked

            if (-not $Script:ui_chkSkipFirmware.IsChecked) {
                $currentSel = $Script:ui_cbCurrentFw.SelectedItem
                if ($currentSel) { Set-AppStateValue -Key "CurrentFirmware" -Value $currentSel.ToString() }

                $targetSel = $Script:ui_cbTargetFw.SelectedItem
                if ($targetSel) { Set-AppStateValue -Key "TargetFirmware" -Value $targetSel.Tag }
            } else {
                Set-AppStateValue -Key "TargetFirmware" -Value $null
            }
        }
        1 {
            if ($Script:ui_rb4G.IsChecked)           { Set-AppStateValue -Key "ConnectionType" -Value "4G" }
            elseif ($Script:ui_rbEthernet.IsChecked) { Set-AppStateValue -Key "ConnectionType" -Value "Ethernet" }
            elseif ($Script:ui_rbDatalogger.IsChecked) { Set-AppStateValue -Key "ConnectionType" -Value "Datalogger" }

            # Rebuild network fields when connection type changes
            Build-NetworkParameterFields

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
            # Collect network param values
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
            # Collect common param values
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
    # Load manifest based on mode when moving forward
    # Firmware combo population will happen when step 0 is validated

    # Skip firmware checkbox
    $Script:ui_chkSkipFirmware.Add_Checked({
        $Script:ui_cbCurrentFw.IsEnabled = $false
        $Script:ui_cbTargetFw.IsEnabled = $false
    })
    $Script:ui_chkSkipFirmware.Add_Unchecked({
        $Script:ui_cbCurrentFw.IsEnabled = $true
        $Script:ui_cbTargetFw.IsEnabled = $true
    })

    # When current firmware changes, update compatible targets
    $Script:ui_cbCurrentFw.Add_SelectionChanged({
        Update-TargetFirmwareList
    })

    # Populate firmware options on load
    Populate-FirmwareOptions
}

function Populate-FirmwareOptions {
    $Script:ui_cbCurrentFw.Items.Clear()
    $Script:ui_cbTargetFw.Items.Clear()

    # Try to load manifest
    $state = Get-AppState
    $manifest = $null

    # Try cache first for immediate display
    $manifest = Get-CachedManifest
    if ($manifest) {
        Set-AppStateValue -Key "Manifest" -Value $manifest
    }

    $availableFirmwares = @()
    if ($manifest) {
        $availableFirmwares = @(Get-AvailableFirmwares -Manifest $manifest)
    }
    Set-AppStateValue -Key "AvailableFirmwares" -Value $availableFirmwares

    # Current firmware options
    $currentOptions = @(Get-CurrentFirmwareOptions -AvailableFirmwares $availableFirmwares)
    foreach ($opt in $currentOptions) {
        $Script:ui_cbCurrentFw.Items.Add($opt) | Out-Null
    }
    if ($currentOptions.Count -gt 0) {
        $Script:ui_cbCurrentFw.SelectedIndex = 0
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

    $state = Get-AppState
    $connType = $state.ConnectionType
    $params = Get-ConnectionParameters -ConnectionType $connType

    $Script:ui_txtNetworkSubtitle.Text = switch ($connType) {
        "4G"         { "Parametres du modem 4G" }
        "Ethernet"   { "Parametres de la connexion Ethernet" }
        "Datalogger" { "Parametres Datalogger (LAN uniquement)" }
        default      { "Configurez les parametres reseau." }
    }

    foreach ($paramDef in $params) {
        $field = New-ParamFieldRow -ParamDef $paramDef -NamePrefix "net"
        $Script:ui_pnlNetworkParams.Children.Add($field.Container) | Out-Null
        $Script:NetworkFieldMap[$paramDef.Param] = $field

        # Wire validation events
        Wire-FieldValidation -Field $field -FieldMap $Script:NetworkFieldMap
    }

    # Apply initial condition visibility
    Update-FieldVisibility -FieldMap $Script:NetworkFieldMap
}

function Build-CommonParameterFields {
    $Script:ui_pnlCommonParams.Children.Clear()
    $Script:CommonFieldMap = @{}

    $params = Get-CommonParameters

    foreach ($paramDef in $params) {
        $field = New-ParamFieldRow -ParamDef $paramDef -NamePrefix "common"
        $Script:ui_pnlCommonParams.Children.Add($field.Container) | Out-Null
        $Script:CommonFieldMap[$paramDef.Param] = $field

        # Wire validation events
        Wire-FieldValidation -Field $field -FieldMap $Script:CommonFieldMap

        # Track user touches for NTP
        if ($paramDef.Param -eq "NtpServerAddr") {
            $field.InputControl.Add_TextChanged({
                $Script:UserTouched["NtpServerAddr"] = $true
            })
        }
    }
}

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
                Clear-ValidationIcon -Icon $f.ValidationIcon
            } else {
                $result = Test-ParameterValue -Type $f.ParamDef.Type -Value $val -ParamName $pName
                Update-ValidationIcon -Icon $f.ValidationIcon -IsValid $result.IsValid -Message $result.Message
            }
        }.GetNewClosure())
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
        }.GetNewClosure())
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
                # Re-evaluate conditional visibility
                if ($Script:NetworkFieldMap) {
                    Update-FieldVisibility -FieldMap $Script:NetworkFieldMap
                }
            }
        }.GetNewClosure())
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
        $Script:ui_txtDriveInfo.Text = "Aucun lecteur amovible detecte. Inserez une carte SD et cliquez Actualiser."
    } else {
        $Script:ui_txtDriveInfo.Text = "$($drives.Count) lecteur(s) amovible(s) detecte(s)."
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

    [void]$sb.AppendLine("MODE : $($state.Mode)")
    [void]$sb.AppendLine("TYPE DE CONNEXION : $($state.ConnectionType)")
    [void]$sb.AppendLine("")

    if ($state.SkipFirmwareUpdate) {
        [void]$sb.AppendLine("FIRMWARE : Configuration uniquement (pas de MAJ)")
    } else {
        [void]$sb.AppendLine("FIRMWARE : $($state.CurrentFirmware) -> $($state.TargetFirmware)")
    }
    [void]$sb.AppendLine("LECTEUR SD : $($state.SdDrive)")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("--- Parametres ---")

    # Collect final values for display
    Collect-StepState -StepIndex 2
    Collect-StepState -StepIndex 3

    foreach ($key in ($state.CollectedParams.Keys | Sort-Object)) {
        $value = $state.CollectedParams[$key]
        # Mask passwords
        $paramDef = $Script:ParameterDefinitions | Where-Object { $_.Param -eq $key } | Select-Object -First 1
        if ($paramDef -and $paramDef.Type -eq "Password" -and $value) {
            $value = "********"
        }
        [void]$sb.AppendLine("  $key = $value")
    }

    if ($state.ConnectionType -ne "Datalogger" -and $state.Mode -ne "Preparation") {
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("--- Talk2M ---")
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
        Add-LogEntry "Mode ONLINE - telechargement des ressources..."
        try {
            $manifest = Get-Manifest -OnLog { param($msg) }
            if (-not $manifest) { throw "Impossible de recuperer le manifest." }
            Set-AppStateValue -Key "Manifest" -Value $manifest
            Save-ManifestToCache -Manifest $manifest
            $ok = Download-AllTemplates -OnLog { param($msg) }
            if (-not $ok) { throw "Echec du telechargement des templates." }
            Add-LogEntry "[OK] Ressources telechargees"
        } catch {
            Add-LogEntry "[ERREUR] $($_.Exception.Message)"
            Set-AppStateValue -Key "IsGenerating" -Value $false
            $Script:ui_txtFinalStatus.Text = "ERREUR: $($_.Exception.Message)"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Red
            $Script:ui_btnNext.Content = "Fermer"
            $Script:ui_btnNext.IsEnabled = $true
            return
        }
    } elseif ($state.Mode -eq "Cache") {
        if (-not (Test-CacheAvailable)) {
            Add-LogEntry "[ERREUR] Cache non disponible"
            $Script:ui_txtFinalStatus.Text = "ERREUR: Cache non disponible"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Red
            Set-AppStateValue -Key "IsGenerating" -Value $false
            $Script:ui_btnNext.Content = "Fermer"
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
                    # Force UI update
                    Update-WpfUI
                } `
                -OnLog {
                    param($Message)
                    Add-LogEntry $Message
                    Update-WpfUI
                }

            $Script:ui_txtGenerationTitle.Text = "Generation terminee !"
            $Script:ui_txtFinalStatus.Text = "PREPARATION TERMINEE AVEC SUCCES"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Green

            $modeText = if ($currentState.SkipFirmwareUpdate) { "Configuration uniquement" } else { "MAJ firmware + Configuration" }
            Add-LogEntry ""
            Add-LogEntry "MODE: $modeText"
            Add-LogEntry "Type de connexion: $($currentState.ConnectionType)"
            Add-LogEntry ""
            Add-LogEntry "Lisez la procedure dans Notepad et ejectez proprement la carte SD."
        } catch {
            $Script:ui_txtFinalStatus.Text = "ERREUR: $($_.Exception.Message)"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Red
            Add-LogEntry "[ERREUR] $($_.Exception.Message)"
        } finally {
            Set-AppStateValue -Key "IsGenerating" -Value $false
            $Script:ui_btnNext.Content = "Fermer"
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
            Add-LogEntry "Mode PREPARATION - telechargement de toutes les ressources..."

            # Manifest
            $Script:ui_pbGeneration.Value = 10
            $Script:ui_txtGenerationPercent.Text = "10% - Recuperation du manifest..."
            Update-WpfUI

            $manifest = Get-Manifest -OnLog { param($msg) Add-LogEntry $msg; Update-WpfUI }
            if (-not $manifest) { throw "Impossible de recuperer le manifest en ligne." }
            Save-ManifestToCache -Manifest $manifest
            Set-AppStateValue -Key "Manifest" -Value $manifest
            Add-LogEntry "[OK] Manifest sauvegarde"

            # Templates
            $Script:ui_pbGeneration.Value = 30
            $Script:ui_txtGenerationPercent.Text = "30% - Telechargement des templates..."
            Update-WpfUI

            $ok = Download-AllTemplates -OnLog { param($msg) Add-LogEntry $msg; Update-WpfUI }
            if (-not $ok) { throw "Echec du telechargement des templates." }

            # Firmwares
            $Script:ui_pbGeneration.Value = 50
            $Script:ui_txtGenerationPercent.Text = "50% - Telechargement des firmwares..."
            Update-WpfUI

            foreach ($fw in @($manifest.firmwares)) {
                $hasEbu = [bool]$fw.hasEbu
                Download-HMSFirmware -Version $fw.version -HasEbu $hasEbu `
                    -OnLog { param($msg) Add-LogEntry $msg; Update-WpfUI } | Out-Null
            }

            $Script:ui_pbGeneration.Value = 100
            $Script:ui_txtGenerationPercent.Text = "100% - Termine !"

            $cacheDir = Get-LocalCacheDir
            $Script:ui_txtGenerationTitle.Text = "Preparation terminee !"
            $Script:ui_txtFinalStatus.Text = "PREPARATION TERMINEE AVEC SUCCES"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Green
            Add-LogEntry ""
            Add-LogEntry "Cache: $cacheDir"
        } catch {
            $Script:ui_txtFinalStatus.Text = "ERREUR: $($_.Exception.Message)"
            $Script:ui_txtFinalStatus.Foreground = [System.Windows.Media.Brushes]::Red
            Add-LogEntry "[ERREUR] $($_.Exception.Message)"
        } finally {
            Set-AppStateValue -Key "IsGenerating" -Value $false
            $Script:ui_btnNext.Content = "Fermer"
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
