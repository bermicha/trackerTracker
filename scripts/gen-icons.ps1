Add-Type -AssemblyName System.Drawing
$dir = Split-Path $PSScriptRoot

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
  $circle = New-Object Drawing.Drawing2D.GraphicsPath
  $circle.AddEllipse([float]0, [float]0, [float]$w, [float]$h)
  # Light grey HUD-style panel; green phosphor crosshair
  $bg = [Drawing.Color]::FromArgb(255, 218, 222, 226)
  $bgBrush = New-Object Drawing.SolidBrush $bg
  $g.FillPath($bgBrush, $circle)
  $bgBrush.Dispose()
  $g.SetClip($circle, [Drawing.Drawing2D.CombineMode]::Replace)
  $circle.Dispose()
  $gap = [Math]::Max([float]1, [Math]::Min($cx, $cy) / [float]5)
  $pw = [Math]::Max([float]1, [float]$w / [float]32)
  $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(255, 0, 210, 90)), $pw
  $pen.StartCap = [Drawing.Drawing2D.LineCap]::Flat
  $pen.EndCap = [Drawing.Drawing2D.LineCap]::Flat
  $g.DrawLine($pen, [float]0, $cy, $cx - $gap, $cy)
  $g.DrawLine($pen, $cx + $gap, $cy, [float]$w, $cy)
  $g.DrawLine($pen, $cx, [float]0, $cx, $cy - $gap)
  $g.DrawLine($pen, $cx, $cy + $gap, $cx, [float]$h)
  $pen.Dispose()
  $px = [Math]::Max(1, [int][Math]::Floor([float]$w / [float]16))
  $rx = [int][Math]::Floor($cx - [float]$px / 2.0)
  $ry = [int][Math]::Floor($cy - [float]$px / 2.0)
  $brush = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 229, 57, 53))
  $g.FillRectangle($brush, $rx, $ry, $px, $px)
  $brush.Dispose()
  $g.ResetClip()
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
