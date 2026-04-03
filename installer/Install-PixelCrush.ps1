# Installs PixelCrush for Chrome: copies extension files and creates shortcuts that load it via --load-extension.
# Usage (from repo):  powershell -ExecutionPolicy Bypass -File .\installer\Install-PixelCrush.ps1
# Or: double-click Install.bat in this folder after unzipping a release.
param(
  [string] $SourceRoot = "",
  [switch] $SkipShortcuts
)

$ErrorActionPreference = "Stop"

function Get-ChromePath {
  $candidates = @(
    (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe"),
    (Join-Path $env:LOCALAPPDATA "Google\Chrome\Application\chrome.exe")
  )
  foreach ($p in $candidates) {
    if (Test-Path -LiteralPath $p) { return $p }
  }
  return $null
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $SourceRoot) {
  $SourceRoot = Resolve-Path (Join-Path $here "..")
}

. (Join-Path $SourceRoot "scripts\extension-files.ps1")

$installRoot = Join-Path $env:LOCALAPPDATA "PixelCrush"
$extDir = Join-Path $installRoot "extension"

Write-Host "Installing PixelCrush extension to:"
Write-Host "  $extDir"
New-Item -ItemType Directory -Path $installRoot -Force | Out-Null
Copy-PixelCrushExtensionFiles -SourceRoot $SourceRoot -DestinationFolder $extDir

$chrome = Get-ChromePath
if (-not $chrome) {
  Write-Warning "Google Chrome not found in default locations. Install Chrome, then use chrome://extensions → Load unpacked → select the folder above."
  exit 0
}

if ($SkipShortcuts) {
  Write-Host "Skipped shortcuts (--SkipShortcuts). Load unpacked from: $extDir"
  exit 0
}

$arg = "--load-extension=`"$extDir`""
$shell = New-Object -ComObject WScript.Shell

$desktop = [Environment]::GetFolderPath("Desktop")
$deskLink = Join-Path $desktop "PixelCrush (Chrome).lnk"
$sc = $shell.CreateShortcut($deskLink)
$sc.TargetPath = $chrome
$sc.Arguments = $arg
$sc.WorkingDirectory = $installRoot
$sc.Description = "Launch Chrome with PixelCrush extension loaded"
$sc.Save()
Write-Host "Created desktop shortcut: $deskLink"

$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$startLink = Join-Path $startMenu "PixelCrush (Chrome).lnk"
$sc2 = $shell.CreateShortcut($startLink)
$sc2.TargetPath = $chrome
$sc2.Arguments = $arg
$sc2.WorkingDirectory = $installRoot
$sc2.Description = "Launch Chrome with PixelCrush extension loaded"
$sc2.Save()
Write-Host "Created Start Menu shortcut."

Write-Host ""
Write-Host "Done. Use the new shortcut to open Chrome with PixelCrush enabled."
Write-Host "Tip: For a permanent install from the store, use the Chrome Web Store listing when available."
