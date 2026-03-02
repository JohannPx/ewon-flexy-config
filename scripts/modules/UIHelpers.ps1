# UIHelpers.ps1 - Dynamic WPF field creation and validation indicators

function Update-ValidationIcon {
    param(
        [System.Windows.Controls.TextBlock]$Icon,
        [bool]$IsValid,
        [string]$Message = ""
    )

    if ($IsValid) {
        $Icon.Text = [char]0x2714  # checkmark
        $Icon.Foreground = [System.Windows.Media.Brushes]::Green
        $Icon.ToolTip = $null
    } else {
        $Icon.Text = [char]0x2718  # X
        $Icon.Foreground = [System.Windows.Media.Brushes]::Red
        $Icon.ToolTip = $Message
    }
}

function Clear-ValidationIcon {
    param([System.Windows.Controls.TextBlock]$Icon)
    $Icon.Text = ""
    $Icon.ToolTip = $null
}

function Set-FieldVisibility {
    param(
        [System.Windows.UIElement]$Container,
        [bool]$Visible
    )
    $Container.Visibility = if ($Visible) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
}

function Add-SelectAllOnFocus {
    param([System.Windows.UIElement]$Control)
    $Control.Add_GotKeyboardFocus({ $this.SelectAll() })
    $Control.Add_PreviewMouseLeftButtonDown({
        if (-not $this.IsKeyboardFocusWithin) {
            $this.Focus()
            $this.SelectAll()
            $_.Handled = $true
        }
    })
}

function New-ParamFieldRow {
    param(
        [hashtable]$ParamDef,
        [string]$NamePrefix
    )

    # Container grid: Label (140px) | Input (*) | Validation icon (30px)
    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = [System.Windows.Thickness]::new(0, 4, 0, 4)

    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = [System.Windows.GridLength]::new(140)
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $col3 = New-Object System.Windows.Controls.ColumnDefinition
    $col3.Width = [System.Windows.GridLength]::new(30)
    $grid.ColumnDefinitions.Add($col1)
    $grid.ColumnDefinitions.Add($col2)
    $grid.ColumnDefinitions.Add($col3)

    # Label
    $label = New-Object System.Windows.Controls.TextBlock
    $label.Text = if ($ParamDef.Description) { T $ParamDef.Description } else { $ParamDef.Param }
    $label.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $label.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $label.FontSize = 12
    [System.Windows.Controls.Grid]::SetColumn($label, 0)
    $grid.Children.Add($label) | Out-Null

    # Validation icon
    $valIcon = New-Object System.Windows.Controls.TextBlock
    $valIcon.FontSize = 14
    $valIcon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $valIcon.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    [System.Windows.Controls.Grid]::SetColumn($valIcon, 2)
    $grid.Children.Add($valIcon) | Out-Null

    # Input control based on type
    $inputControl = $null

    switch ($ParamDef.Type) {
        "Choice" {
            $combo = New-Object System.Windows.Controls.ComboBox
            $combo.Tag = $ParamDef.Param
            $combo.Height = 28
            $combo.FontSize = 12

            $labels = Get-ChoiceLabels -ParamName $ParamDef.Param
            $selectedIdx = 0
            $idx = 0
            foreach ($entry in $labels.GetEnumerator()) {
                $item = New-Object System.Windows.Controls.ComboBoxItem
                $item.Content = $entry.Value
                $item.Tag = $entry.Key
                $combo.Items.Add($item) | Out-Null
                if ($entry.Key -eq $ParamDef.Default) { $selectedIdx = $idx }
                $idx++
            }
            $combo.SelectedIndex = $selectedIdx

            $inputControl = $combo
        }
        "Timezone" {
            $combo = New-Object System.Windows.Controls.ComboBox
            $combo.Tag = $ParamDef.Param
            $combo.Height = 28
            $combo.FontSize = 12
            $combo.IsEditable = $true
            $combo.IsTextSearchEnabled = $true

            $tzList = @(
                "Africa/Abidjan","Africa/Algiers","Africa/Cairo","Africa/Casablanca","Africa/Ceuta",
                "Africa/Dakar","Africa/Dar_es_Salaam","Africa/Djibouti","Africa/Douala","Africa/Johannesburg",
                "Africa/Khartoum","Africa/Kinshasa","Africa/Lagos","Africa/Libreville","Africa/Maputo",
                "Africa/Nairobi","Africa/Nouakchott","Africa/Ouagadougou","Africa/Tripoli","Africa/Tunis",
                "America/Adak","America/Anchorage","America/Argentina/Buenos_Aires","America/Asuncion",
                "America/Bahia","America/Barbados","America/Belem","America/Bogota","America/Caracas",
                "America/Cayenne","America/Chicago","America/Costa_Rica","America/Cuiaba","America/Denver",
                "America/Edmonton","America/Fortaleza","America/Godthab","America/Guatemala",
                "America/Guayaquil","America/Halifax","America/Havana","America/Indianapolis",
                "America/Jamaica","America/La_Paz","America/Lima","America/Los_Angeles","America/Managua",
                "America/Manaus","America/Martinique","America/Mexico_City","America/Montevideo",
                "America/Montreal","America/New_York","America/Panama","America/Paramaribo",
                "America/Phoenix","America/Port-au-Prince","America/Porto_Velho","America/Puerto_Rico",
                "America/Recife","America/Regina","America/Santiago","America/Santo_Domingo",
                "America/Sao_Paulo","America/St_Johns","America/Tegucigalpa","America/Toronto",
                "America/Vancouver","America/Winnipeg",
                "Antarctica/McMurdo","Antarctica/Palmer","Antarctica/South_Pole",
                "Arctic/Longyearbyen",
                "Asia/Almaty","Asia/Amman","Asia/Baghdad","Asia/Bahrain","Asia/Baku","Asia/Bangkok",
                "Asia/Beirut","Asia/Bishkek","Asia/Calcutta","Asia/Colombo","Asia/Damascus","Asia/Dhaka",
                "Asia/Dubai","Asia/Gaza","Asia/Ho_Chi_Minh","Asia/Hong_Kong","Asia/Irkutsk","Asia/Istanbul",
                "Asia/Jakarta","Asia/Jerusalem","Asia/Kabul","Asia/Kamchatka","Asia/Karachi",
                "Asia/Kathmandu","Asia/Krasnoyarsk","Asia/Kuala_Lumpur","Asia/Kuwait","Asia/Macau",
                "Asia/Magadan","Asia/Manila","Asia/Muscat","Asia/Nicosia","Asia/Novosibirsk",
                "Asia/Omsk","Asia/Phnom_Penh","Asia/Pyongyang","Asia/Qatar","Asia/Riyadh",
                "Asia/Saigon","Asia/Seoul","Asia/Shanghai","Asia/Singapore","Asia/Taipei",
                "Asia/Tashkent","Asia/Tbilisi","Asia/Tehran","Asia/Tokyo","Asia/Ulaanbaatar",
                "Asia/Vladivostok","Asia/Yakutsk","Asia/Yekaterinburg","Asia/Yerevan",
                "Atlantic/Azores","Atlantic/Canary","Atlantic/Cape_Verde","Atlantic/Faroe",
                "Atlantic/Madeira","Atlantic/Reykjavik",
                "Australia/Adelaide","Australia/Brisbane","Australia/Darwin","Australia/Hobart",
                "Australia/Melbourne","Australia/Perth","Australia/Sydney",
                "Europe/Amsterdam","Europe/Athens","Europe/Belgrade","Europe/Berlin","Europe/Bratislava",
                "Europe/Brussels","Europe/Bucharest","Europe/Budapest","Europe/Chisinau","Europe/Copenhagen",
                "Europe/Dublin","Europe/Gibraltar","Europe/Helsinki","Europe/Istanbul","Europe/Kiev",
                "Europe/Lisbon","Europe/Ljubljana","Europe/London","Europe/Luxembourg","Europe/Madrid",
                "Europe/Malta","Europe/Minsk","Europe/Monaco","Europe/Moscow","Europe/Oslo","Europe/Paris",
                "Europe/Prague","Europe/Riga","Europe/Rome","Europe/Samara","Europe/Sarajevo",
                "Europe/Skopje","Europe/Sofia","Europe/Stockholm","Europe/Tallinn","Europe/Tirane",
                "Europe/Vienna","Europe/Vilnius","Europe/Volgograd","Europe/Warsaw","Europe/Zagreb",
                "Europe/Zurich",
                "Indian/Antananarivo","Indian/Maldives","Indian/Mauritius","Indian/Reunion",
                "Pacific/Auckland","Pacific/Chatham","Pacific/Easter","Pacific/Fiji","Pacific/Guam",
                "Pacific/Honolulu","Pacific/Midway","Pacific/Noumea","Pacific/Pago_Pago",
                "Pacific/Port_Moresby","Pacific/Tahiti","Pacific/Tongatapu",
                "Etc/GMT","Etc/UTC"
            )

            $selectedIdx = 0
            $idx = 0
            foreach ($tz in $tzList) {
                $combo.Items.Add($tz) | Out-Null
                if ($tz -eq $ParamDef.Default) { $selectedIdx = $idx }
                $idx++
            }
            $combo.SelectedIndex = $selectedIdx

            $inputControl = $combo
        }
        "Password" {
            $pwBox = New-Object System.Windows.Controls.PasswordBox
            $pwBox.Tag = $ParamDef.Param
            $pwBox.Height = 28
            $pwBox.FontSize = 12
            if ($ParamDef.Param -eq "Password") { $pwBox.MaxLength = 24 }
            if ($ParamDef.Default) {
                $pwBox.Password = $ParamDef.Default
            }
            Add-SelectAllOnFocus -Control $pwBox
            $inputControl = $pwBox

            # Confirmation row (only for admin password)
            if ($ParamDef.Param -ne "Password") { break }
            $confirmGrid = New-Object System.Windows.Controls.Grid
            $confirmGrid.Margin = [System.Windows.Thickness]::new(0, 2, 0, 4)
            $cc1 = New-Object System.Windows.Controls.ColumnDefinition; $cc1.Width = [System.Windows.GridLength]::new(140)
            $cc2 = New-Object System.Windows.Controls.ColumnDefinition; $cc2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $cc3 = New-Object System.Windows.Controls.ColumnDefinition; $cc3.Width = [System.Windows.GridLength]::new(30)
            $confirmGrid.ColumnDefinitions.Add($cc1); $confirmGrid.ColumnDefinitions.Add($cc2); $confirmGrid.ColumnDefinitions.Add($cc3)

            $confirmLabel = New-Object System.Windows.Controls.TextBlock
            $confirmLabel.Text = T "ValConfirmLabel"
            $confirmLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $confirmLabel.TextWrapping = [System.Windows.TextWrapping]::Wrap
            $confirmLabel.FontSize = 11
            $confirmLabel.Foreground = [System.Windows.Media.Brushes]::Gray
            [System.Windows.Controls.Grid]::SetColumn($confirmLabel, 0)
            $confirmGrid.Children.Add($confirmLabel) | Out-Null

            $Script:ConfirmPwBox = New-Object System.Windows.Controls.PasswordBox
            $Script:ConfirmPwBox.Tag = "$($ParamDef.Param)_confirm"
            $Script:ConfirmPwBox.Height = 28
            $Script:ConfirmPwBox.FontSize = 12
            $Script:ConfirmPwBox.MaxLength = 24
            if ($ParamDef.Default) {
                $Script:ConfirmPwBox.Password = $ParamDef.Default
            }
            Add-SelectAllOnFocus -Control $Script:ConfirmPwBox
            $Script:ConfirmPwBox.Margin = [System.Windows.Thickness]::new(5, 0, 5, 0)
            [System.Windows.Controls.Grid]::SetColumn($Script:ConfirmPwBox, 1)
            $confirmGrid.Children.Add($Script:ConfirmPwBox) | Out-Null

            $Script:ConfirmValIcon = New-Object System.Windows.Controls.TextBlock
            $Script:ConfirmValIcon.FontSize = 14
            $Script:ConfirmValIcon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $Script:ConfirmValIcon.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
            [System.Windows.Controls.Grid]::SetColumn($Script:ConfirmValIcon, 2)
            $confirmGrid.Children.Add($Script:ConfirmValIcon) | Out-Null

            $Script:ConfirmGridRef = $confirmGrid
            $Script:ConfirmLabelRef = $confirmLabel
        }
        "PIN" {
            $tb = New-Object System.Windows.Controls.TextBox
            $tb.Tag = $ParamDef.Param
            $tb.Height = 28
            $tb.FontSize = 12
            $tb.MaxLength = 4
            if ($ParamDef.Default) { $tb.Text = $ParamDef.Default }
            Add-SelectAllOnFocus -Control $tb
            $inputControl = $tb
        }
        default {
            # Text, IPv4, Integer
            $tb = New-Object System.Windows.Controls.TextBox
            $tb.Tag = $ParamDef.Param
            $tb.Height = 28
            $tb.FontSize = 12
            if ($ParamDef.Default) { $tb.Text = $ParamDef.Default }
            Add-SelectAllOnFocus -Control $tb
            $inputControl = $tb
        }
    }

    [System.Windows.Controls.Grid]::SetColumn($inputControl, 1)
    $inputControl.Margin = [System.Windows.Thickness]::new(5, 0, 5, 0)
    $grid.Children.Add($inputControl) | Out-Null

    # For password fields, wrap main row + confirmation row in a StackPanel
    $container = $grid
    $confirmCtrl = $null
    $confirmIcon = $null
    if ($ParamDef.Type -eq "Password" -and $Script:ConfirmGridRef) {
        $wrapper = New-Object System.Windows.Controls.StackPanel
        $wrapper.Children.Add($grid) | Out-Null
        $wrapper.Children.Add($Script:ConfirmGridRef) | Out-Null
        $container = $wrapper
        $confirmCtrl = $Script:ConfirmPwBox
        $confirmIcon = $Script:ConfirmValIcon
        $Script:ConfirmGridRef = $null
        $Script:ConfirmPwBox = $null
        $Script:ConfirmValIcon = $null
        $Script:ConfirmLabelRef = $null
    }

    return @{
        Container      = $container
        InputControl   = $inputControl
        ValidationIcon = $valIcon
        ConfirmControl = $confirmCtrl
        ConfirmValIcon = $confirmIcon
        ParamDef       = $ParamDef
        ParamName      = $ParamDef.Param
        TriggerParams  = @(Get-ConditionTriggers -Condition $ParamDef.Condition)
    }
}

function Get-FieldValue {
    param($InputControl)

    if ($InputControl -is [System.Windows.Controls.PasswordBox]) {
        return $InputControl.Password
    } elseif ($InputControl -is [System.Windows.Controls.ComboBox]) {
        if ($InputControl.IsEditable) {
            return $InputControl.Text
        }
        $selectedItem = $InputControl.SelectedItem
        if ($selectedItem -and $selectedItem.Tag) {
            return $selectedItem.Tag
        }
        return ""
    } else {
        return $InputControl.Text
    }
}

function Get-RemovableDrives {
    $drives = @()
    try {
        Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=2" | ForEach-Object {
            $sizeGB = if ($_.Size) { [math]::Round($_.Size / 1GB, 1) } else { 0 }
            $volName = if ($_.VolumeName) { $_.VolumeName } else { T "DriveNoName" }
            $drives += @{
                DeviceID   = $_.DeviceID
                VolumeName = $volName
                SizeGB     = $sizeGB
                Display    = "$($_.DeviceID)\ - $volName ($($sizeGB) $(T 'SizeUnitGB'))"
            }
        }
    } catch {}
    return $drives
}

function New-SectionHeader {
    param([string]$Title)

    $border = New-Object System.Windows.Controls.Border
    $border.Margin = [System.Windows.Thickness]::new(0, 12, 0, 4)
    $border.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#1A5276")
    $border.BorderThickness = [System.Windows.Thickness]::new(0, 0, 0, 1)
    $border.Padding = [System.Windows.Thickness]::new(0, 0, 0, 4)

    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Title
    $tb.FontSize = 13
    $tb.FontWeight = [System.Windows.FontWeights]::SemiBold
    $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#1A5276")

    $border.Child = $tb
    return $border
}
