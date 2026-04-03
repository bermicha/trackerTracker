Add-Type -AssemblyName System.Drawing
$dir = Split-Path $PSScriptRoot

function Draw-PopArtStrokedLine {
  param(
    [Drawing.Graphics] $G,
    [float] $X1,
    [float] $Y1,
    [float] $X2,
    [float] $Y2,
    [Drawing.Color] $Color,
    [float] $StrokeW,
    [float] $OutlineExtra
  )
  $outW = $StrokeW + $OutlineExtra
  $black = New-Object Drawing.Pen ([Drawing.Color]::Black), $outW
  $black.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
  $black.StartCap = [Drawing.Drawing2D.LineCap]::Round
  $black.EndCap = [Drawing.Drawing2D.LineCap]::Round
  $G.DrawLine($black, $X1, $Y1, $X2, $Y2)
  $black.Dispose()
  $inner = New-Object Drawing.Pen $Color, $StrokeW
  $inner.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
  $inner.StartCap = [Drawing.Drawing2D.LineCap]::Round
  $inner.EndCap = [Drawing.Drawing2D.LineCap]::Round
  $G.DrawLine($inner, $X1, $Y1, $X2, $Y2)
  $inner.Dispose()
}

function New-TrackerIconBitmap {
  param([int]$w, [int]$h)
  $bmp = New-Object Drawing.Bitmap $w, $h, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
  $g.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.Clear([Drawing.Color]::Transparent)
  $cx = [float]$w / 2.0
  $cy = [float]$h / 2.0
  $m = [float]$w * [float]0.06
  $gap = [float]$w * [float]0.13
  $stroke = [Math]::Max([float]2.5, [float]$w / [float]14)
  $outline = [Math]::Max([float]2.5, [float]$w / [float]32)
  # Pop art: yellow + cyan horizontal arms, magenta + lime vertical (bold comic outline)
  $yellow = [Drawing.Color]::FromArgb(255, 255, 235, 59)
  $cyan = [Drawing.Color]::FromArgb(255, 0, 229, 255)
  $magenta = [Drawing.Color]::FromArgb(255, 255, 23, 146)
  $lime = [Drawing.Color]::FromArgb(255, 198, 255, 0)
  Draw-PopArtStrokedLine -G $g -X1 $m -Y1 $cy -X2 ($cx - $gap) -Y2 $cy -Color $yellow -StrokeW $stroke -OutlineExtra $outline
  Draw-PopArtStrokedLine -G $g -X1 ($cx + $gap) -Y1 $cy -X2 ([float]$w - $m) -Y2 $cy -Color $cyan -StrokeW $stroke -OutlineExtra $outline
  Draw-PopArtStrokedLine -G $g -X1 $cx -Y1 $m -X2 $cx -Y2 ($cy - $gap) -Color $magenta -StrokeW $stroke -OutlineExtra $outline
  Draw-PopArtStrokedLine -G $g -X1 $cx -Y1 ($cy + $gap) -X2 $cx -Y2 ([float]$h - $m) -Color $lime -StrokeW $stroke -OutlineExtra $outline
  # Center dot: red with black outline (filled rings, pop art bullseye)
  $dotR = [Math]::Max([float]2, [float]$w / [float]11)
  $ring = [Math]::Max([float]1.5, $outline * [float]0.65)
  $outerR = $dotR + $ring
  $blackBrush = New-Object Drawing.SolidBrush ([Drawing.Color]::Black)
  $g.FillEllipse($blackBrush, $cx - $outerR, $cy - $outerR, $outerR * 2, $outerR * 2)
  $blackBrush.Dispose()
  $red = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 255, 59, 48))
  $g.FillEllipse($red, $cx - $dotR, $cy - $dotR, $dotR * 2, $dotR * 2)
  $red.Dispose()
  $g.Dispose()
  return $bmp
}

# Canonical 128x128 artwork (Chrome Web Store / manifest "128" size)
$src128 = New-TrackerIconBitmap -w 128 -h 128
$path128 = Join-Path $dir "icons/icon128.png"
New-Item -ItemType Directory -Force -Path (Split-Path $path128) | Out-Null
$src128.Save($path128, [Drawing.Imaging.ImageFormat]::Png)

function Save-ScaledIcon {
  param(
    [Drawing.Bitmap] $Source,
    [int] $Size,
    [string] $OutPath
  )
  $bmp = New-Object Drawing.Bitmap $Size, $Size, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.Clear([Drawing.Color]::Transparent)
  $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceOver
  $g.DrawImage($Source, 0, 0, $Size, $Size)
  $g.Dispose()
  $bmp.Save($OutPath, [Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

Save-ScaledIcon -Source $src128 -Size 48 -OutPath (Join-Path $dir "icons/icon48.png")
Save-ScaledIcon -Source $src128 -Size 16 -OutPath (Join-Path $dir "icons/icon16.png")
$src128.Dispose()

$px = New-Object Drawing.Bitmap 1, 1
$px.SetPixel(0, 0, [Drawing.Color]::FromArgb(0, 0, 0, 0))
$px.Save((Join-Path $dir "blocked-pixel.png"), [Drawing.Imaging.ImageFormat]::Png)
$px.Dispose()
Write-Host "OK: icon128.png is 128x128; icon48.png and icon16.png are scaled from it."
