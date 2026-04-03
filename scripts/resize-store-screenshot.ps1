# Resizes store/store-screenshot-1280x800.png to exactly 1280x800 (Chrome Web Store size).
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot
$path = Join-Path $root "store\store-screenshot-1280x800.png"
if (-not (Test-Path $path)) { throw "Not found: $path" }
Add-Type -AssemblyName System.Drawing
$src = [Drawing.Image]::FromFile($path)
$bmp = New-Object Drawing.Bitmap 1280, 800
$g = [Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.DrawImage($src, 0, 0, 1280, 800)
$g.Dispose()
$src.Dispose()
$tmp = $path + ".tmp.png"
$bmp.Save($tmp, [Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Remove-Item $path -Force
Move-Item $tmp $path
Write-Host "OK: $path is 1280x800"
