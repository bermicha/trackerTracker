# Removes Tracker Tracker install folder and shortcuts created by the installer.
$ErrorActionPreference = "Stop"
$installRoot = Join-Path $env:LOCALAPPDATA "TrackerTracker"
$desktop = [Environment]::GetFolderPath("Desktop")
$startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
foreach ($p in @(
  (Join-Path $desktop "Tracker Tracker (Chrome).lnk"),
  (Join-Path $startMenu "Tracker Tracker (Chrome).lnk")
)) {
  if (Test-Path -LiteralPath $p) {
    Remove-Item -LiteralPath $p -Force
    Write-Host "Removed: $p"
  }
}
if (Test-Path -LiteralPath $installRoot) {
  Remove-Item -LiteralPath $installRoot -Recurse -Force
  Write-Host "Removed: $installRoot"
}
Write-Host "Uninstall complete."
