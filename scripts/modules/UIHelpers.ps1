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
    $label.Text = if ($ParamDef.Description) { $ParamDef.Description } else { $ParamDef.Param }
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
        "Password" {
            $pwBox = New-Object System.Windows.Controls.PasswordBox
            $pwBox.Tag = $ParamDef.Param
            $pwBox.Height = 28
            $pwBox.FontSize = 12
            $pwBox.MaxLength = 24
            if ($ParamDef.Default) {
                $pwBox.Password = $ParamDef.Default
            }
            $inputControl = $pwBox
        }
        "PIN" {
            $tb = New-Object System.Windows.Controls.TextBox
            $tb.Tag = $ParamDef.Param
            $tb.Height = 28
            $tb.FontSize = 12
            $tb.MaxLength = 4
            if ($ParamDef.Default) { $tb.Text = $ParamDef.Default }
            $inputControl = $tb
        }
        default {
            # Text, IPv4, Integer
            $tb = New-Object System.Windows.Controls.TextBox
            $tb.Tag = $ParamDef.Param
            $tb.Height = 28
            $tb.FontSize = 12
            if ($ParamDef.Default) { $tb.Text = $ParamDef.Default }
            $inputControl = $tb
        }
    }

    [System.Windows.Controls.Grid]::SetColumn($inputControl, 1)
    $inputControl.Margin = [System.Windows.Thickness]::new(5, 0, 5, 0)
    $grid.Children.Add($inputControl) | Out-Null

    return @{
        Container      = $grid
        InputControl   = $inputControl
        ValidationIcon = $valIcon
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
            $volName = if ($_.VolumeName) { $_.VolumeName } else { "Sans nom" }
            $drives += @{
                DeviceID   = $_.DeviceID
                VolumeName = $volName
                SizeGB     = $sizeGB
                Display    = "$($_.DeviceID)\ - $volName ($($sizeGB) Go)"
            }
        }
    } catch {}
    return $drives
}
