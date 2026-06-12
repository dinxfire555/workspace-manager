param(
 [string]$GitlabToken = "",
 [string]$MarketUrl = "",
 [string]$OutputDir = "",
 [switch]$ListOnly,
 [string]$Role = "",
 [string]$CacheDir = ".brain/tool_cache",
 [string]$EnvPath = ".wm-env.json"
)

<#
.SYNOPSIS
 Fetch available tools from FCI Skills marketplace. Reads URL from .wm-env.json.
.DESCRIPTION
 Accesses the fci-skills repository, reads the marketplace.json
 manifest, and returns the list of available plugins/tools.
  Supports role-based filtering. Cache used only with explicit -UseCache flag.
 v2: URL read from .wm-env.json instead of hardcoded.
.PARAMETER GitlabToken
 GitLab personal access token (overrides $env:WM_GITLAB_TOKEN)
.PARAMETER MarketUrl
 URL to the marketplace.json manifest (auto-detected from .wm-env.json if empty)
.PARAMETER OutputDir
 If provided, downloads all tool metadata files to this directory
.PARAMETER ListOnly
 If set, only lists available tools without downloading
.PARAMETER Role
 Filter tools by role (Dev, PO, PM, BA, Tester, SM)
.PARAMETER CacheDir
 Directory for cached marketplace data
.PARAMETER EnvPath
 Path to .wm-env.json (default: .wm-env.json in current directory)
#>

# Config
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
if (-not $GitlabToken) { $GitlabToken = $env:WM_GITLAB_TOKEN }
$TimeoutSec = 10

# Read URL from .wm-env.json
function Get-EnvConfig {
 param([string]$Path)
 if (-not (Test-Path $Path)) {
 Write-Warning "[fetch-tools] .wm-env.json not found at $Path — using hardcoded defaults"
 return $null
 }
 try {
 $env = Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
 return $env
 } catch {
 Write-Warning "[fetch-tools] Failed to parse .wm-env.json: $_"
 return $null
 }
}

# URL builder helpers
function Build-RawUrl {
 param([object]$Source, [string]$SubPath)
 if ($Source.type -eq "gitlab") {
 $url = "$($Source.project_url)/-/raw/$($Source.branch)/$SubPath"
 if ($GitlabToken) { $url += "?private_token=$GitlabToken" }
 return $url
 } else {
 return "$($Source.raw_url)/$SubPath"
 }
}

function Build-BaseUrl {
 param([object]$Source)
 if ($Source.type -eq "gitlab") {
 $url = "$($Source.project_url)/-/raw/$($Source.branch)"
 if ($GitlabToken) { $url += "?private_token=$GitlabToken" }
 return $url
 } else {
 return $Source.raw_url
 }
}

if (-not $MarketUrl) {
 $wmEnv = Get-EnvConfig -Path $EnvPath
 if ($wmEnv -and $wmEnv.fci_skills) {
 $MarketUrl = Build-RawUrl $wmEnv.fci_skills ".claude-plugin/marketplace.json"
 } else {
 $MarketUrl = "https://raw.githubusercontent.com/YOUR_ORG/fci-skills/main/.claude-plugin/marketplace.json"
 }
}

# Fetch Marketplace Manifest
$headers = @{ "Accept" = "application/json" }

Write-Host "[fetch-tools] Fetching marketplace manifest..." -ForegroundColor Gray

try {
 $response = Invoke-WebRequest -Uri $MarketUrl -Headers $headers -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
 $marketplace = $response.Content | ConvertFrom-Json
 Write-Host "[fetch-tools] Marketplace manifest loaded" -ForegroundColor Green
}
catch {
  Write-Error "[fetch-tools] Failed to fetch marketplace: $_"
  Write-Host ""
  Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
  Write-Host "  1. Check .wm-env.json fci_skills URL is correct"
  Write-Host "  2. For private repos, set `$env:WM_GITLAB_TOKEN = 'your-token'"
  Write-Host ""
  
  $cachePath = Join-Path $CacheDir "marketplace.json"
  if (Test-Path $cachePath) {
    Write-Host "[fetch-tools] Cached marketplace exists at $cachePath" -ForegroundColor Yellow
    Write-Host "[fetch-tools] Run sync-tool workflow to retry with fixed URL or token." -ForegroundColor Yellow
  }
  exit 2
}

# Cache manifest
$cacheDir = if ([System.IO.Path]::IsPathRooted($CacheDir)) { $CacheDir } else { Join-Path (Get-Location).Path $CacheDir }
New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
$marketplace | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $cacheDir "marketplace.json") -Encoding UTF8

# Process Plugins
$plugins = $marketplace.plugins
if (-not $plugins -or $plugins.Count -eq 0) {
 Write-Warning "[fetch-tools] No plugins found in marketplace"
 exit 0
}

Write-Host "[fetch-tools] Found $($plugins.Count) available plugins" -ForegroundColor Cyan

# Role-Based Filtering
$roleMapping = @{
 "Dev" = @("development", "ai")
 "PO" = @("planning")
 "PM" = @("planning", "development")
 "BA" = @("analysis")
 "Tester" = @("testing")
 "SM" = @("planning")
}

if ($Role -and $roleMapping.ContainsKey($Role)) {
 $allowedCategories = $roleMapping[$Role]
 $plugins = $plugins | Where-Object { $_.category -in $allowedCategories }
 Write-Host "[fetch-tools] Filtered by role '$Role': $($plugins.Count) plugins" -ForegroundColor Cyan
}

# List
Write-Host ""
Write-Host "Available Tools:" -ForegroundColor Yellow
Write-Host ""

$idx = 0
foreach ($plugin in $plugins) {
 $idx++
 $authorName = if ($plugin.author -and $plugin.author.name) { $plugin.author.name } else { "Unknown" }
 Write-Host "[$idx] $($plugin.name)" -ForegroundColor Green
 Write-Host " Description: $($plugin.description)" -ForegroundColor Gray
 Write-Host " Author: $authorName | Category: $($plugin.category)" -ForegroundColor Gray
 if ($plugin.source) { Write-Host " Source: $($plugin.source)" -ForegroundColor DarkGray }
 Write-Host ""
}

if ($ListOnly) {
 Write-Host "[fetch-tools] List complete. Use without -ListOnly to download." -ForegroundColor Yellow
 return $plugins
}

# Download Tools
if (-not $OutputDir) {
 $OutputDir = "$env:TEMP\wm-tools"
}
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$pluginBase = if ($wmEnv -and $wmEnv.fci_skills) { Build-BaseUrl $wmEnv.fci_skills } else { "https://raw.githubusercontent.com/YOUR_ORG/fci-skills/main" }

$downloaded = 0
foreach ($plugin in $plugins) {
 $pluginDir = Join-Path $OutputDir $plugin.name
 New-Item -ItemType Directory -Force -Path $pluginDir | Out-Null

 # Try to download README.md and skills
 $filesToTry = @("README.md")
 if ($plugin.source) {
 $sourcePath = $plugin.source.TrimStart("./")
 $filesToTry += @(
 "$sourcePath/README.md"
 )
 }

 foreach ($file in $filesToTry) {
 $fileUrl = "$pluginBase/$file"
 try {
 $fileResponse = Invoke-WebRequest -Uri $fileUrl -Headers $headers -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
 $destFile = Join-Path $pluginDir (Split-Path $file -Leaf)
 [System.IO.File]::WriteAllText($destFile, $fileResponse.Content, $utf8NoBom)
 Write-Host " Downloaded: $($plugin.name)/$(Split-Path $file -Leaf)" -ForegroundColor DarkGray
 } catch {
 # File may not exist skip silently
 }
 }
 $downloaded++
}

Write-Host "[fetch-tools] Downloaded metadata for $downloaded plugins to $OutputDir" -ForegroundColor Green
return $plugins
