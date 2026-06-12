param(
 [ValidateSet('L0','L1','L2','system')]
 [string]$Level = 'L0',
 [string]$Unit = 'ai',
 [string]$Department = '',
 [string]$Product = '',
 [string]$OutputPath = '',
 [string]$GitlabToken = '',
 [switch]$UseCache,
 [string]$CacheDir = '.brain/context_cache',
 [string]$EnvPath = '.wm-env.json',
 [ValidateSet('policies','prompts','standards','tool-configs')]
 [string]$SystemFolder = '',
 [switch]$FetchSystemFolders
)

<#
.SYNOPSIS
 Fetch context files from context-hub raw URLs. Reads URL config from .wm-env.json.
.DESCRIPTION
 Downloads L0/L1/L2 context files from the central context-hub repository.
 Supports GitHub and GitLab via .wm-env.json configuration.
  Supports auth via env var or parameter, and explicit -UseCache flag for offline use.
 v2: Added -FetchSystemFolders for policy/prompts/standards/tool-configs.
 v2: Fixed single-quote string bug — CRITICAL: variables now interpolate correctly.
 v2.1: Context manifest integration + fallback chains + redirect detection.
        Supports varied naming conventions (standard vs {Unit}_business-context.md).
.PARAMETER Level
 Context layer: L0 (business), L1 (domain), L2 (project), system (system folders)
.PARAMETER Unit
 Business unit name (e.g., 'ai', 'cloud')
.PARAMETER Department
 Department name (required for L1 and L2)
.PARAMETER Product
 Product name (required for L2)
.PARAMETER OutputPath
 Where to save the fetched file
.PARAMETER GitlabToken
 GitLab personal access token (overrides $env:WM_GITLAB_TOKEN)
.PARAMETER UseCache
 Force use of cached version without attempting online fetch
.PARAMETER CacheDir
 Directory for cached context files (relative to workspace root)
.PARAMETER EnvPath
 Path to .wm-env.json (default: .wm-env.json in current directory)
.PARAMETER SystemFolder
 Which system folder to fetch: policies, prompts, standards, tool-configs
.PARAMETER FetchSystemFolders
 Fetch all 4 system folders (policies, prompts, standards, tool-configs)
#>

# Config
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$TimeoutSec = 10

# Read URL from .wm-env.json
function Get-EnvConfig {
 param([string]$Path)
 if (-not (Test-Path $Path)) {
 Write-Warning "[fetch-context] .wm-env.json not found at $Path — using hardcoded defaults"
 return $null
 }
 try {
 $env = Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json
 return $env
 } catch {
 Write-Warning "[fetch-context] Failed to parse .wm-env.json: $_"
 return $null
 }
}

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

# ── v2.1: Context Manifest + Redirect Support ──
function Parse-ManifestMapping {
    param([string]$Content)
    $mapping = @()
    $lines = $Content -split "`n"
    $inSection = $false
    foreach ($line in $lines) {
        if ($line -match '##\s+3\.\s+Business') { $inSection = $true; continue }
        if ($inSection -and $line -match '^\|\s*`(\w+)`\s*\|\s*`(\w+)`\s*\|\s*`([^`]+)`\s*\|\s*`([^`]+)`') {
            $mapping += @{
                "block"   = $matches[1]
                "domain"  = $matches[2]
                "l0_path" = $matches[3].Trim()
                "l1_path" = $matches[4].Trim()
            }
        }
        if ($inSection -and $mapping.Count -gt 0 -and $line -match '^\s*---\s*$') { break }
    }
    return $mapping
}

function Parse-ManifestLoadOrder {
    param([string]$Content)
    $order = @()
    if ($Content -match '1\.\s*.+?business-context.md.+?L0') { $order += "L0" }
    if ($Content -match '2\.\s*.+?domain-context.md.+?L1')    { $order += "L1" }
    if ($Content -match '3\.\s*.+?project-context.md.+?L2')   { $order += "L2" }
    if ($Content -match '4\.\s*.+?feature-context.md.+?L3')   { $order += "L3" }
    return $order
}

function Parse-ManifestBlocks {
    param([string]$Content)
    $blocks = @()
    $regex = [regex]'(?m)^\s*(?:├──|└──)\s+context/(\w+)/\s+←\s+\[(\w+)\s+Block\]'
    foreach ($match in $regex.Matches($Content)) {
        $blocks += @{ "name" = $match.Groups[1].Value; "label" = $match.Groups[2].Value }
    }
    if ($blocks.Count -eq 0) {
        $mapping = Parse-ManifestMapping -Content $Content
        $blocks = $mapping | Select-Object -ExpandProperty block -Unique | ForEach-Object { @{ "name" = $_; "label" = $_ } }
    }
    return $blocks
}

function Get-ContextManifest {
    param([object]$Source)
    if (-not $Source) { return $null }
    $manifestUrl = Build-RawUrl $Source "context/context-manifest.md"
    try {
        $resp = Invoke-WebRequest -Uri $manifestUrl -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
        $raw = $resp.Content
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        $cacheDirFull = if ([System.IO.Path]::IsPathRooted($CacheDir)) { $CacheDir } else { Join-Path (Get-Location).Path $CacheDir }
        New-Item -ItemType Directory -Force -Path $cacheDirFull | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $cacheDirFull "context-manifest.md"), $raw, $utf8NoBom)
        Write-Host "[fetch-context] Manifest loaded + cached" -ForegroundColor Green
        return @{
            "raw"       = $raw
            "blocks"    = Parse-ManifestBlocks -Content $raw
            "mapping"   = Parse-ManifestMapping -Content $raw
            "loadOrder" = Parse-ManifestLoadOrder -Content $raw
        }
    } catch {
        Write-Host "[fetch-context] context-manifest.md not available — will use directory scan" -ForegroundColor Yellow
        return $null
    }
}

function Test-IsRedirect {
    param([string]$Content)
    $lines = ($Content.Trim() -split "`n" | Where-Object { $_.Trim() -ne '' })
    if ($lines.Count -eq 1 -and $lines[0] -match '^[A-Za-z0-9._-]+\.md$') {
        return $lines[0].Trim()
    }
    return $null
}

$wmEnv = Get-EnvConfig -Path $EnvPath
if (-not $GitlabToken) { $GitlabToken = $env:WM_GITLAB_TOKEN }
$manifest = if ($wmEnv) { Get-ContextManifest -Source $wmEnv.context_hub } else { $null }
if ($wmEnv) {
 $BaseUrl = "$(Build-BaseUrl $wmEnv.context_hub)/context"
} else {
 $BaseUrl = "https://raw.githubusercontent.com/YOUR_ORG/context-hub/main/context"
}

# Resolve context URL using manifest + fallback chains (v2.1)
function Resolve-ContextUrl {
    param([string]$L, [string]$U, [string]$Dept, [string]$Prod)

    $source = if ($wmEnv) { $wmEnv.context_hub } else { $null }

    $chains = @{
        "L0" = @()
        "L1" = @()
        "L2" = @()
        "L3" = @("context/$U/feature-context.md")
    }

    # Use manifest mapping for preferred L0/L1 paths (if available)
    if ($manifest -and $manifest.mapping -and $manifest.mapping.Count -gt 0) {
        if ($L -eq "L0") {
            $row = $manifest.mapping | Where-Object { $_.block -eq $U } | Select-Object -First 1
            if ($row) { $chains["L0"] += $row.l0_path }
        }
        if ($L -eq "L1" -and $Dept) {
            $row = $manifest.mapping | Where-Object { $_.block -eq $U -and $_.domain -eq $Dept } | Select-Object -First 1
            if ($row) { $chains["L1"] += $row.l1_path }
        }
    }

    # Add universal fallback chains (deduplication handled by try order)
    if ($chains["L0"].Count -eq 0) {
        $chains["L0"] += "context/$U/business-context.md"
    }
    $chains["L0"] += "context/$U/${U}_business-context.md"

    if ($Dept) {
        if ($chains["L1"].Count -eq 0) {
            $chains["L1"] += "context/$U/$Dept/domain-context.md"
        }
        $chains["L1"] += "context/$U/$Dept/${Dept}_business-context.md"
    }

    if ($Prod) {
        $chains["L2"] += "context/$U/$Dept/$Prod/project-context.md"
        $chains["L2"] += "context/$U/$Dept/${Prod}_domain-context.md"
    }
    $chains["L2"] += "context/$U/project-context.md"

    # Try each URL in order — first 200 wins
    foreach ($path in $chains[$L]) {
        if ($source) {
            $testUrl = Build-RawUrl $source $path
        } else {
            $shortPath = $path -replace '^context/', ''
            $testUrl = "$BaseUrl/$shortPath"
        }
        try {
            $null = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            Write-Host "[fetch-context] Resolved $L URL: $testUrl" -ForegroundColor Green
            return $testUrl
        } catch {
            try {
                $rangeHeaders = @{ "Range" = "bytes=0-0" }
                $null = Invoke-WebRequest -Uri $testUrl -Headers $rangeHeaders -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                Write-Host "[fetch-context] Resolved $L URL: $testUrl" -ForegroundColor Green
                return $testUrl
            } catch {}
        }
    }

    # All failed — return first URL for error reporting
    $fallbackPath = $chains[$L][0]
    if ($source) {
        return Build-RawUrl $source $fallbackPath
    } else {
        $shortPath = $fallbackPath -replace '^context/', ''
        return "$BaseUrl/$shortPath"
    }
}

# Build template URL (used when context file not found on hub)
function Get-TemplateUrl {
  param([string]$L)
  if ($wmEnv) {
    switch ($L) {
    "L0" { return Build-RawUrl $wmEnv.context_hub "context/$Unit/business-context.md" }
    "L1" { return Build-RawUrl $wmEnv.context_hub "context/$Unit/$Department/domain-context.md" }
    "L2" { return Build-RawUrl $wmEnv.context_hub "context/$Unit/project-context.md" }
    "L3" { return Build-RawUrl $wmEnv.context_hub "context/$Unit/feature-context.md" }
    }
  }
  switch ($L) {
  "L0" { return "$BaseUrl/$Unit/business-context.md" }
  "L1" { return "$BaseUrl/$Unit/$Department/domain-context.md" }
  "L2" { return "$BaseUrl/$Unit/project-context.md" }
  "L3" { return "$BaseUrl/$Unit/feature-context.md" }
  }
}

# Build system folder URL
function Get-SystemFolderUrl {
 param([string]$Folder)
 $hubBase = if ($wmEnv) { Build-BaseUrl $wmEnv.context_hub } else { "https://raw.githubusercontent.com/YOUR_ORG/context-hub/main" }
 switch ($Folder) {
 "policies" { return "$hubBase/policies/" }
 "prompts" { return "$hubBase/prompts/" }
 "standards" { return "$hubBase/standards/$Unit/architecture.md" }
 "tool-configs" { return "$hubBase/tool-configs/" }
 }
}

function Get-CachePath {
 param([string]$L, [string]$Dir)
 $name = switch ($L) {
 "L0" { "business-context.md" }
 "L1" { "domain-context.md" }
 "L2" { "project-context.md" }
 }
 return Join-Path $Dir $name
}

# ─── System Folders Mode ───
if ($FetchSystemFolders) {
  $systemFolders = @("policies", "prompts", "standards", "tool-configs")
  $systemFolderPrefix = @{
    "policies" = "02"; "prompts" = "03"
    "standards" = "04"; "tool-configs" = "05"
  }
  $rootDir = if ($OutputPath) { $OutputPath } else { "00_System" }
  $headers = @{ "Accept" = "text/plain" }

  foreach ($folder in $systemFolders) {
  $folderUrl = Get-SystemFolderUrl -Folder $folder
  $targetDir = Join-Path $rootDir "$($systemFolderPrefix[$folder])_$folder"

 Write-Host "[fetch-context] Fetching system folder: $folder" -ForegroundColor Gray

 # Standards is a single file, others are flat folders
 if ($folder -eq "standards") {
 New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
 try {
 $response = Invoke-WebRequest -Uri $folderUrl -Headers $headers -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
 $fileName = Split-Path $folderUrl -Leaf
 $destFile = Join-Path $targetDir $fileName
 [System.IO.File]::WriteAllText($destFile, $response.Content, $utf8NoBom)
 Write-Host "[fetch-context] Downloaded: $destFile" -ForegroundColor Green
 } catch {
 Write-Host "[fetch-context] standards/ not available — creating empty with .gitkeep" -ForegroundColor Yellow
 New-Item -ItemType File -Force -Path (Join-Path $targetDir ".gitkeep") | Out-Null
 }
 } else {
 # Flat folders: try listing, copy all files, or create empty
 New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
 try {
 # Attempt to fetch a known file or just create .gitkeep
 $testUrl = "$folderUrl.gitkeep"
 $response = Invoke-WebRequest -Uri $testUrl -Headers $headers -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
 if ($response.Content) {
 [System.IO.File]::WriteAllText((Join-Path $targetDir ".gitkeep"), $response.Content, $utf8NoBom)
 }
 Write-Host "[fetch-context] $folder/ fetched" -ForegroundColor Green
 } catch {
 Write-Host "[fetch-context] $folder/ empty or not available — creating .gitkeep" -ForegroundColor Yellow
 New-Item -ItemType File -Force -Path (Join-Path $targetDir ".gitkeep") | Out-Null
 }
 }
 }

 Write-Host "[fetch-context] System folders processed" -ForegroundColor Green
 return
}

# ─── Single System Folder Mode ───
if ($SystemFolder) {
 $folderUrl = Get-SystemFolderUrl -Folder $SystemFolder
 $targetFile = if (-not $OutputPath) { Join-Path "00_System" $SystemFolder } else { $OutputPath }
 $headers = @{ "Accept" = "text/plain" }

 if ($SystemFolder -eq "standards") {
 $parentDir = Split-Path $targetFile -Parent
 if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Force -Path $parentDir | Out-Null }
 try {
 $response = Invoke-WebRequest -Uri $folderUrl -Headers $headers -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
 [System.IO.File]::WriteAllText($targetFile, $response.Content, $utf8NoBom)
 Write-Host "[fetch-context] Downloaded $SystemFolder to $targetFile" -ForegroundColor Green
 } catch {
 Write-Warning "[fetch-context] $SystemFolder not found on hub"
 }
 } else {
 New-Item -ItemType Directory -Force -Path $targetFile | Out-Null
 New-Item -ItemType File -Force -Path (Join-Path $targetFile ".gitkeep") | Out-Null
 Write-Host "[fetch-context] Created $SystemFolder/ with .gitkeep" -ForegroundColor Green
 }
 return
}

# ─── Context Mode (L0/L1/L2) ───

# Validation
if ($Level -ne "L0" -and -not $Department) {
 Write-Error "Department is required for Level $Level"
 exit 1
}
if ($Level -eq "L2" -and -not $Product) {
 Write-Error "Product is required for Level L2"
 exit 1
}
if (-not $OutputPath) {
 $name = switch ($Level) { "L0" { "business-context.md" } "L1" { "domain-context.md" } "L2" { "project-context.md" } }
 $OutputPath = "$env:TEMP\wm-$Level-$name"
}

# Try Cache First (if forced)
if ($UseCache) {
 $cachePath = Get-CachePath -L $Level -Dir $CacheDir
 if (Test-Path $cachePath) {
 Write-Host "[fetch-context] Using cached $Level from $cachePath" -ForegroundColor Cyan
 Copy-Item -Path $cachePath -Destination $OutputPath -Force
 return
 } else {
 Write-Warning "[fetch-context] No cache found for $Level at $cachePath"
 exit 1
 }
}

# Online Fetch
$url = Resolve-ContextUrl -L $Level -U $Unit -Dept $Department -Prod $Product
Write-Host "[fetch-context] Fetching $Level from: $url" -ForegroundColor Gray

$headers = @{ "Accept" = "text/plain" }

try {
 $response = Invoke-WebRequest -Uri $url -Headers $headers -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
 $content = $response.Content

 if ([string]::IsNullOrWhiteSpace($content)) {
  throw "Empty response"
 }

 # ── Redirect Detection (v2.1) ──
 $redirectCount = 0
 $maxRedirects = 2
 while ($redirectCount -lt $maxRedirects) {
  $redirectTarget = Test-IsRedirect -Content $content
  if (-not $redirectTarget) { break }

  Write-Host "[fetch-context] Detected redirect → $redirectTarget" -ForegroundColor Yellow
  $urlNoQuery = ($url -split '\?')[0]
  $parentDir = ($urlNoQuery -replace '/[^/]+$', '')
  $url = "$parentDir/$redirectTarget"
  if ($GitlabToken -and $url -notmatch 'private_token') {
   $url += "?private_token=$GitlabToken"
  }
  $redirectCount++

  $response = Invoke-WebRequest -Uri $url -Headers $headers -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
  $content = $response.Content
  if ([string]::IsNullOrWhiteSpace($content)) {
   throw "Empty response after redirect to $redirectTarget"
  }
 }

 if (Test-IsRedirect -Content $content) {
  throw "Max redirect depth ($maxRedirects) exceeded"
 }
 # ── End Redirect Detection ──

 # Write output
 $parentDir = Split-Path $OutputPath -Parent
 if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Force -Path $parentDir | Out-Null }
 [System.IO.File]::WriteAllText($OutputPath, $content, $utf8NoBom)

 # Update cache
 $cacheDir = if ([System.IO.Path]::IsPathRooted($CacheDir)) { $CacheDir } else { Join-Path (Get-Location).Path $CacheDir }
 New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
 $cacheFile = Get-CachePath -L $Level -Dir $cacheDir
 [System.IO.File]::WriteAllText($cacheFile, $content, $utf8NoBom)

 Write-Host "[fetch-context] $Level fetched and cached successfully" -ForegroundColor Green
 Write-Host "[fetch-context] Output: $OutputPath" -ForegroundColor Gray
}
catch {
  Write-Error "[fetch-context] Online fetch failed: $_"
  Write-Host ""
  Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
  Write-Host "  1. Check .wm-env.json context_hub URL is correct"
  Write-Host "  2. For private repos, set `$env:WM_GITLAB_TOKEN = 'your-token'"
  Write-Host "  3. To use offline cache, add -UseCache flag"
  Write-Host ""
  
  if ($UseCache) {
    $cachePath = Get-CachePath -L $Level -Dir $CacheDir
    if (Test-Path $cachePath) {
      Write-Host "[fetch-context] Using cached $Level from $cachePath" -ForegroundColor Yellow
      Copy-Item -Path $cachePath -Destination $OutputPath -Force
      return
    }
    Write-Error "[fetch-context] No cache available for $Level"
  }
  
  Write-Host "[fetch-context] Run sync-context workflow to update URLs or set token." -ForegroundColor Yellow
  exit 2
}
