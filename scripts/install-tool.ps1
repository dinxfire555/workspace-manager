param(
 [Parameter(Mandatory=$true)]
 [string]$ToolName,
 [string]$SourceUrl = '',
 [string]$SourceDir = '',
 [ValidateSet('opencode','claude','codex','antigravity','both')]
 [string]$Target = 'opencode',
 [string]$ConvertersDir = '',
 [string]$WorkspaceDir = '',
 [switch]$RegisterInConfig,
 [switch]$Quiet,
 [string]$EnvPath = '.wm-env.json'
)

<#
.SYNOPSIS
 One-click tool install: download convert install workflow.
.DESCRIPTION
 Downloads a tool from the FCI Skills marketplace (or local source), converts it
 to the target platform format, and installs it. Supports Opencode, Claude Code,
 Codex CLI, and Antigravity. v2: Reads fci-skills URL from .wm-env.json.
.PARAMETER ToolName
 Name of the tool to install (must match marketplace or be a directory name)
.PARAMETER SourceUrl
 Raw URL to download from (overrides auto-detection from marketplace)
.PARAMETER SourceDir
 Local source directory (if already downloaded, skip download step)
.PARAMETER Target
 Target platform: opencode, claude, codex, antigravity, or both (all)
.PARAMETER ConvertersDir
 Directory containing converter scripts (default: ./converters/)
.PARAMETER WorkspaceDir
 Workspace Manager root directory (default: current directory)
.PARAMETER RegisterInConfig
 Register the tool in platform config file (opencode.jsonc / claude.json)
.PARAMETER Quiet
 Suppress verbose output; only show errors and final status
#>

# Config
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
if (-not $WorkspaceDir) { $WorkspaceDir = (Get-Location).Path }
if (-not $ConvertersDir) { $ConvertersDir = Join-Path $WorkspaceDir 'converters' }
$SetupDir = Join-Path $env:TEMP "wm-install-$([System.IO.Path]::GetRandomFileName())"
$GitlabToken = $env:WM_GITLAB_TOKEN

# Read URL from .wm-env.json
function Get-EnvConfig {
 param([string]$Path)
 $envPath = Join-Path $WorkspaceDir $Path
 if (-not (Test-Path $envPath)) { return $null }
 try {
 return Get-Content -Path $envPath -Raw -Encoding UTF8 | ConvertFrom-Json
 } catch { return $null }
}
$wmEnv = Get-EnvConfig -Path $EnvPath

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

function Write-Log {
 param([string]$Message, [string]$ForegroundColor = 'Gray')
 if (-not $Quiet) { Write-Host $Message -ForegroundColor $ForegroundColor }
}

# Step 1: Download
function Step1-Download {
 param([string]$Name, [string]$Url)
 $toolDir = Join-Path $SetupDir 'tools' $Name
 New-Item -ItemType Directory -Force -Path $toolDir | Out-Null

 # If local source provided, copy from there
 if ($SourceDir -and (Test-Path $SourceDir)) {
 Write-Log "[install-tool] Copying from local source: $SourceDir" -ForegroundColor Cyan
 Copy-Item -Path "$SourceDir\*" -Destination $toolDir -Recurse -Force
 return $toolDir
 }

 # Determine download URLs
 $pluginBase = if ($wmEnv -and $wmEnv.fci_skills) { Build-BaseUrl $wmEnv.fci_skills } else { "https://raw.githubusercontent.com/YOUR_ORG/fci-skills/main" }

 # Try marketplace source path first
 $sourcePath = $Url
 if (-not $sourcePath) {
 # Try to find in marketplace
 $marketCache = Join-Path $WorkspaceDir '.brain/tool_cache/marketplace.json'
 if (Test-Path $marketCache) {
 $marketplace = Get-Content -Path $marketCache -Raw -Encoding UTF8 | ConvertFrom-Json
 $plugin = $marketplace.plugins | Where-Object { $_.name -eq $Name } | Select-Object -First 1
 if ($plugin -and $plugin.source) {
 $sourcePath = $plugin.source.TrimStart('./')
 }
 }
 }

 if (-not $sourcePath) {
 # Guess the path from common patterns
 $sourcePath = 'plugins/company/$Name'
 }

 $headers = @{ 'Accept' = 'text/plain' }

 # Download files
 $filesToTry = @(
 'README.md',
 "$sourcePath/README.md",
 "$sourcePath/skills/*.md",
 "$sourcePath/.claude-plugin/*"
 )

 $downloaded = 0
 foreach ($filePattern in $filesToTry) {
 $fileUrl = "$pluginBase/$filePattern"
 try {
 $response = Invoke-WebRequest -Uri $fileUrl -Headers $headers -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
 $fileName = Split-Path $filePattern -Leaf
 if ($fileName -eq '*') { $fileName = 'SKILL.md' } # wildcard handling
 $destFile = Join-Path $toolDir $fileName
 [System.IO.File]::WriteAllText($destFile, $response.Content, $utf8NoBom)
 $downloaded++
 } catch {
 # File may not exist - skip
 }
 }

 if ($downloaded -eq 0) {
 Write-Log "[install-tool] No files downloaded for $Name - source may not exist" -ForegroundColor Yellow
 } else {
 Write-Log "[install-tool] Downloaded $downloaded files for $Name" -ForegroundColor Green
 }

 return $toolDir
}

# Step 2: Convert
function Step2-Convert {
 param([string]$ToolDir, [string]$Tgt)

 $converterScript = Join-Path $ConvertersDir "convert-to-$Tgt.ps1"
 if (-not (Test-Path $converterScript)) {
 Write-Log "[install-tool] Converter not found: $converterScript" -ForegroundColor Red
 return $false
 }

 try {
 & $converterScript -ResourceType 'skills' -SourceDir $ToolDir -TargetBasePath $TargetBasePath -RegisterInConfig:$RegisterInConfig
 Write-Log "[install-tool] Converted $ToolName for $Tgt" -ForegroundColor Green
 return $true
 } catch {
 Write-Log "[install-tool] Convert failed: $_" -ForegroundColor Red
 return $false
 }
}

# Step 3: Verify
function Step3-Verify {
 param([string]$Tgt)
 $targetSkillsDir = switch ($Tgt) {
 'opencode' { "$env:USERPROFILE\.config\opencode\awf-skills" }
 'claude' { "$env:USERPROFILE\.claude\skills" }
 'codex' { "$env:USERPROFILE\.codex\skills" }
 'antigravity' { "$env:USERPROFILE\.gemini\config\skills" }
 }

 $installedSkill = Join-Path $targetSkillsDir $ToolName 'SKILL.md'
 if (Test-Path $installedSkill) {
 Write-Log "[install-tool] Verified: $ToolName installed for $Tgt" -ForegroundColor Green
 return $true
 } else {
 Write-Log "[install-tool] $ToolName not found in $Tgt skills directory" -ForegroundColor Yellow
 return $false
 }
}

# MAIN
Write-Log "" -ForegroundColor Cyan
Write-Log " INSTALL TOOL: $ToolName" -ForegroundColor Cyan
Write-Log "" -ForegroundColor Cyan

try {
 # Step 1: Download
 Write-Log ""; Write-Log "[1/3] Downloading $ToolName..." -ForegroundColor Yellow
 $toolDir = Step1-Download -Name $ToolName -Url $SourceUrl
 $downloadOk = (Get-ChildItem -Path $toolDir -File | Measure-Object).Count -gt 0

 # Determine which targets
 $targets = @()
 if ($Target -eq 'both') { $targets = @('opencode', 'claude', 'codex', 'antigravity') }
 else { $targets = @($Target) }

 # Step 2-3: Convert + Verify per target
 $installResults = @()
 foreach ($tgt in $targets) {
 $TargetBasePath = switch ($tgt) {
 'opencode' { "$env:USERPROFILE\.config\opencode" }
 'claude' { "$env:USERPROFILE\.claude" }
 'codex' { "$env:USERPROFILE\.codex" }
 'antigravity' { "$env:USERPROFILE\.gemini\config" }
 }

 if (-not (Test-Path $TargetBasePath)) {
 Write-Log "[install-tool] $tgt not installed - skipping" -ForegroundColor DarkGray
 $installResults += [PSCustomObject]@{ Target = $tgt; Status = 'skipped'; Reason = 'Not installed' }
 continue
 }

 Write-Log ""; Write-Log "[2/3] Converting for $tgt..." -ForegroundColor Yellow
 $convertOk = Step2-Convert -ToolDir $toolDir -Tgt $tgt

 Write-Log ""; Write-Log "[3/3] Verifying $tgt installation..." -ForegroundColor Yellow
 $verifyOk = Step3-Verify -Tgt $tgt

 $status = if ($convertOk -and $verifyOk) { 'ok' } elseif ($downloadOk -and !$convertOk) { 'convert-failed' } else { 'failed' }
 $installResults += [PSCustomObject]@{ Target = $tgt; Status = $status }
 }

 # Report
 Write-Log ''
 Write-Log '' -ForegroundColor Cyan
 $allOk = ($installResults | Where-Object { $_.Status -eq 'ok' }).Count -gt 0
 if ($allOk) {
 Write-Log " $ToolName installed successfully!" -ForegroundColor Green
 } else {
 Write-Log " $ToolName installation had issues" -ForegroundColor Yellow
 }
 foreach ($r in $installResults) {
 $icon = switch ($r.Status) { 'ok' { "[OK]" } 'skipped' { "[--]" } default { "[!!]" } }
 $color = switch ($r.Status) { 'ok' { 'Green' } 'skipped' { 'DarkGray' } default { 'Red' } }
 Write-Log " $icon $($r.Target): $($r.Status)" -ForegroundColor $color
 }
 Write-Log '' -ForegroundColor Cyan

 # Log to session_log
 $now = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
 $logLine = "$now INSTALL: $ToolName via install-tool.ps1 [ok=$allOk]"
 Add-Content -Path (Join-Path $WorkspaceDir '.brain/session_log.txt') -Value $logLine -Encoding UTF8

 # Cleanup
 if (Test-Path $SetupDir) { Remove-Item -Path $SetupDir -Recurse -Force -ErrorAction SilentlyContinue }

 return $allOk
}
catch {
 Write-Log "[install-tool] Fatal error: $_" -ForegroundColor Red
 if (Test-Path $SetupDir) { Remove-Item -Path $SetupDir -Recurse -Force -ErrorAction SilentlyContinue }
 exit 1
}
