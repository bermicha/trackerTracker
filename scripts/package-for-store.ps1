# Builds pixelcrush-store.zip for Chrome Web Store upload (no .git, no dev scripts).
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot
. (Join-Path $PSScriptRoot "extension-files.ps1")
$outZip = Join-Path $root "pixelcrush-store.zip"
$staging = Join-Path $env:TEMP "pixelcrush-store-$(Get-Random)"
New-Item -ItemType Directory -Path $staging -Force | Out-Null
Copy-PixelCrushExtensionFiles -SourceRoot $root -DestinationFolder $staging

if (Test-Path $outZip) { Remove-Item $outZip -Force }
Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $outZip -Force
Remove-Item $staging -Recurse -Force
Write-Host "Created: $outZip"
(Get-Item $outZip).Length | ForEach-Object { Write-Host ("Size: {0:N0} bytes" -f $_) }
