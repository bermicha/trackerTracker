# 16x16 pixel-art master: neon 8-bit "eye crossed out", nearest-neighbor scaled to store sizes.
Add-Type -AssemblyName System.Drawing
$dir = Split-Path $PSScriptRoot

function Get-PixelCrushPixel16 {
  param([int]$X, [int]$Y)
  # Neon palette (dark fill + electric outline / pupil / strike)
  $neonCyan = [Drawing.Color]::FromArgb(255, 0, 255, 245)
  $neonCyanHi = [Drawing.Color]::FromArgb(255, 110, 255, 255)
  $neonMagenta = [Drawing.Color]::FromArgb(255, 255, 0, 200)
  $neonMagentaHi = [Drawing.Color]::FromArgb(255, 255, 70, 230)
  $neonYellow = [Drawing.Color]::FromArgb(255, 255, 245, 50)
  $neonYellowDim = [Drawing.Color]::FromArgb(255, 230, 200, 0)
  $fill = [Drawing.Color]::FromArgb(255, 16, 6, 38)
  $fillHi = [Drawing.Color]::FromArgb(255, 38, 14, 64)

  # Almond eye (ellipse), center ~ (7.5, 7)
  $cx = 7.5; $cy = 7.0; $rx = 5.3; $ry = 3.25
  $edx = ([double]$X - $cx) / $rx
  $edy = ([double]$Y - $cy) / $ry
  $eye = $edx * $edx + $edy * $edy

  $px = ([double]$X - 7.5) / 2.05
  $py = ([double]$Y - 7) / 1.65
  $pupil = $px * $px + $py * $py

  # Thick diagonal slash (\) — top layer (full "no" stroke across icon)
  $d = [double]$X - [double]$Y
  $slash = [Math]::Abs($d) -lt 2.0
  if ($slash) {
    if ($eye -le 1.08) {
      return $neonYellow
    }
    return $neonYellowDim
  }

  if ($eye -gt 1.15) {
    return $null
  }

  if ($eye -ge 0.88 -and $eye -le 1.15) {
    if (($X -eq 4 -and $Y -eq 5) -or ($X -eq 11 -and $Y -eq 5)) {
      return $neonCyanHi
    }
    return $neonCyan
  }

  if ($pupil -le 1.0) {
    if ($pupil -le 0.35) {
      return $neonMagentaHi
    }
    return $neonMagenta
  }

  if ($eye -lt 0.88) {
    if ((($X + $Y) % 3) -eq 0) {
      return $fillHi
    }
    return $fill
  }

  return $null
}

function New-PixelCrushPixelArt16 {
  $n = 16
  $bmp = New-Object Drawing.Bitmap $n, $n, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::None
  $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::None
  $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.Clear([Drawing.Color]::Transparent)
  for ($y = 0; $y -lt $n; $y++) {
    for ($x = 0; $x -lt $n; $x++) {
      $c = Get-PixelCrushPixel16 -X $x -Y $y
      if ($null -ne $c) {
        $b = New-Object Drawing.SolidBrush $c
        $g.FillRectangle($b, $x, $y, 1, 1)
        $b.Dispose()
      }
    }
  }
  $g.Dispose()
  return $bmp
}

function Save-ScaledNearest {
  param(
    [Drawing.Bitmap] $Source16,
    [int] $OutSize,
    [string] $OutPath
  )
  $bmp = New-Object Drawing.Bitmap $OutSize, $OutSize, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.Clear([Drawing.Color]::Transparent)
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::None
  $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::Half
  $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
  $g.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceOver
  $dest = New-Object Drawing.Rectangle 0, 0, $OutSize, $OutSize
  $src = New-Object Drawing.Rectangle 0, 0, 16, 16
  $g.DrawImage($Source16, $dest, $src, [Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $bmp.Save($OutPath, [Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

$src16 = New-PixelCrushPixelArt16
$iconsDir = Join-Path $dir "icons"
New-Item -ItemType Directory -Force -Path $iconsDir | Out-Null
Save-ScaledNearest -Source16 $src16 -OutSize 128 -OutPath (Join-Path $iconsDir "icon128.png")
Save-ScaledNearest -Source16 $src16 -OutSize 48 -OutPath (Join-Path $iconsDir "icon48.png")
Save-ScaledNearest -Source16 $src16 -OutSize 16 -OutPath (Join-Path $iconsDir "icon16.png")
$src16.Dispose()

$px = New-Object Drawing.Bitmap 1, 1
$px.SetPixel(0, 0, [Drawing.Color]::FromArgb(0, 0, 0, 0))
$px.Save((Join-Path $dir "blocked-pixel.png"), [Drawing.Imaging.ImageFormat]::Png)
$px.Dispose()
Write-Host "OK: 16x16 neon eye + slash -> icon128/48/16 (nearest-neighbor)."
