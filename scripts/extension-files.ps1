# Shared list and copy for Chrome package / Windows installer.
$script:ExtensionRelativePaths = @(
  "manifest.json",
  "background.js",
  "content.js",
  "content.css",
  "blocked-pixel.png",
  "lib",
  "rules",
  "icons"
)

function Copy-TrackerExtensionFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string] $SourceRoot,
    [Parameter(Mandatory = $true)]
    [string] $DestinationFolder
  )
  if (-not (Test-Path $SourceRoot)) { throw "Source not found: $SourceRoot" }
  New-Item -ItemType Directory -Path $DestinationFolder -Force | Out-Null
  foreach ($name in $script:ExtensionRelativePaths) {
    $src = Join-Path $SourceRoot $name
    if (-not (Test-Path $src)) { throw "Missing: $src" }
    Copy-Item -Path $src -Destination (Join-Path $DestinationFolder $name) -Recurse -Force
  }
}
