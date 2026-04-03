Add-Type -AssemblyName System.Drawing
$dir = Split-Path $PSScriptRoot
$icons = @(
  @{ w = 16; h = 16; path = "icons/icon16.png" },
  @{ w = 48; h = 48; path = "icons/icon48.png" },
  @{ w = 128; h = 128; path = "icons/icon128.png" }
)
foreach ($item in $icons) {
  $bmp = New-Object Drawing.Bitmap $item.w, $item.h
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([Drawing.Color]::FromArgb(255, 198, 40, 40))
  $pw = [Math]::Max(1, [int]($item.w / 8))
  $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(255, 255, 255, 255)), $pw
  $g.DrawEllipse($pen, $item.w * 0.2, $item.h * 0.2, $item.w * 0.6, $item.h * 0.6)
  $g.DrawLine($pen, $item.w * 0.35, $item.h * 0.35, $item.w * 0.65, $item.h * 0.65)
  $pen.Dispose()
  $g.Dispose()
  $full = Join-Path $dir $item.path
  New-Item -ItemType Directory -Force -Path (Split-Path $full) | Out-Null
  $bmp.Save($full, [Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}
$px = New-Object Drawing.Bitmap 1, 1
$px.SetPixel(0, 0, [Drawing.Color]::FromArgb(0, 0, 0, 0))
$px.Save((Join-Path $dir "blocked-pixel.png"), [Drawing.Imaging.ImageFormat]::Png)
$px.Dispose()
Write-Host "OK"
