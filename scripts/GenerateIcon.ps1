# GenerateIcon.ps1 - Generate icon.ico from WPF drawing (used by CI)
# Produces a multi-resolution .ico file matching the app's SD card icon

param(
    [string]$OutputPath = "icon.ico"
)

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

function Render-SdCardIcon([int]$size) {
    $scale = $size / 32.0
    $dv = New-Object System.Windows.Media.DrawingVisual
    $dc = $dv.RenderOpen()

    # SD card body (rounded rectangle, blue gradient)
    $cardRect = New-Object System.Windows.Rect((3 * $scale), (1 * $scale), (22 * $scale), (30 * $scale))
    $brush = New-Object System.Windows.Media.LinearGradientBrush(
        [System.Windows.Media.Color]::FromRgb(26, 82, 118),
        [System.Windows.Media.Color]::FromRgb(41, 128, 185),
        45)
    $pen = New-Object System.Windows.Media.Pen([System.Windows.Media.Brushes]::White, (0.5 * $scale))
    $dc.DrawRoundedRectangle($brush, $pen, $cardRect, (2 * $scale), (2 * $scale))

    # Corner notch (top-right triangle)
    $notchGeo = New-Object System.Windows.Media.StreamGeometry
    $ctx = $notchGeo.Open()
    $ctx.BeginFigure((New-Object System.Windows.Point((19 * $scale), (1 * $scale))), $true, $true)
    $ctx.LineTo((New-Object System.Windows.Point((25 * $scale), (7 * $scale))), $true, $false)
    $ctx.LineTo((New-Object System.Windows.Point((25 * $scale), (1 * $scale))), $true, $false)
    $ctx.Close()
    $dc.DrawGeometry([System.Windows.Media.Brushes]::White, $null, $notchGeo)

    # Contact pins (small gold rectangles)
    $goldBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 215, 0))
    for ($i = 0; $i -lt 4; $i++) {
        $pinRect = New-Object System.Windows.Rect(((8 + $i * 4) * $scale), (4 * $scale), (2 * $scale), (8 * $scale))
        $dc.DrawRectangle($goldBrush, $null, $pinRect)
    }

    # "SD" text
    $typeface = New-Object System.Windows.Media.Typeface(
        (New-Object System.Windows.Media.FontFamily("Segoe UI")),
        [System.Windows.FontStyles]::Normal,
        [System.Windows.FontWeights]::Bold,
        [System.Windows.FontStretches]::Normal)
    $fontSize = 10 * $scale
    $formattedText = New-Object System.Windows.Media.FormattedText(
        "SD", [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Windows.FlowDirection]::LeftToRight,
        $typeface, $fontSize, [System.Windows.Media.Brushes]::White)
    $textX = ((28 * $scale) - $formattedText.Width) / 2
    $dc.DrawText($formattedText, (New-Object System.Windows.Point($textX, (17 * $scale))))

    $dc.Close()

    $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($size, $size, 96, 96,
        [System.Windows.Media.PixelFormats]::Pbgra32)
    $rtb.Render($dv)
    $rtb.Freeze()
    return $rtb
}

function ConvertTo-IcoBytes([System.Windows.Media.Imaging.BitmapSource[]]$Bitmaps) {
    # ICO file format: header + directory entries + PNG image data
    $ms = New-Object System.IO.MemoryStream

    # ICO Header: reserved(2) + type(2) + count(2)
    $ms.Write([byte[]](0, 0), 0, 2)                          # Reserved
    $ms.Write([BitConverter]::GetBytes([uint16]1), 0, 2)      # Type: 1 = ICO
    $ms.Write([BitConverter]::GetBytes([uint16]$Bitmaps.Count), 0, 2)

    # Pre-render each bitmap to PNG bytes
    $pngDataList = @()
    foreach ($bmp in $Bitmaps) {
        $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
        $pngMs = New-Object System.IO.MemoryStream
        $encoder.Save($pngMs)
        $pngDataList += , $pngMs.ToArray()
        $pngMs.Dispose()
    }

    # Directory entries offset starts after header (6 bytes) + entries (16 bytes each)
    $dataOffset = 6 + ($Bitmaps.Count * 16)

    for ($i = 0; $i -lt $Bitmaps.Count; $i++) {
        $bmp = $Bitmaps[$i]
        $pngData = $pngDataList[$i]
        $w = [byte]$(if ($bmp.PixelWidth -ge 256) { 0 } else { $bmp.PixelWidth })
        $h = [byte]$(if ($bmp.PixelHeight -ge 256) { 0 } else { $bmp.PixelHeight })

        $ms.WriteByte($w)                                                  # Width
        $ms.WriteByte($h)                                                  # Height
        $ms.WriteByte(0)                                                   # Color palette
        $ms.WriteByte(0)                                                   # Reserved
        $ms.Write([BitConverter]::GetBytes([uint16]1), 0, 2)               # Color planes
        $ms.Write([BitConverter]::GetBytes([uint16]32), 0, 2)              # Bits per pixel
        $ms.Write([BitConverter]::GetBytes([uint32]$pngData.Length), 0, 4) # Image size
        $ms.Write([BitConverter]::GetBytes([uint32]$dataOffset), 0, 4)     # Offset

        $dataOffset += $pngData.Length
    }

    # Write PNG image data
    foreach ($pngData in $pngDataList) {
        $ms.Write($pngData, 0, $pngData.Length)
    }

    return $ms.ToArray()
}

# Generate icons at multiple sizes
$sizes = @(16, 32, 48, 256)
$bitmaps = @()
foreach ($s in $sizes) {
    $bitmaps += Render-SdCardIcon $s
}

$icoBytes = ConvertTo-IcoBytes $bitmaps
$resolvedPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) { $OutputPath } else { Join-Path (Get-Location) $OutputPath }
[System.IO.File]::WriteAllBytes($resolvedPath, $icoBytes)

Write-Host "Icon generated: $resolvedPath ($($sizes -join ', ') px)"
