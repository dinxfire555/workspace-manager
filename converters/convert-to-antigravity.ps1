param(
    [ValidateSet("workflows","skills","schemas","templates","all")]
    [string]$ResourceType = "all",
    [string]$SourceDir = "",
    [string]$TargetBasePath = "",
    [switch]$RegisterInConfig
)

# Target: ~/.gemini/config/
# Workflows → ~/.gemini/config/global_workflows/<name>.md
# Skills → ~/.gemini/config/skills/<name>/SKILL.md
# Config → ~/.gemini/GEMINI.md (append/update rules section)

if (-not $TargetBasePath) { $TargetBasePath = "$env:USERPROFILE\.gemini\config" }
if (-not $SourceDir) { $SourceDir = (Get-Location).Path }

$WorkflowsDir = "$TargetBasePath\global_workflows"
$SkillsDir = "$TargetBasePath\skills"
$SchemasDir = "$TargetBasePath\schemas"
$TemplatesDir = "$TargetBasePath\templates"
$GeminiConfigFile = "$env:USERPROFILE\.gemini\GEMINI.md"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Copy-Workflows {
    param([string]$Src)
    if (-not (Test-Path $Src)) { return }
    New-Item -ItemType Directory -Force -Path $WorkflowsDir | Out-Null
    $files = Get-ChildItem -Path $Src -Filter "*.md" -File
    $i = 0
    foreach ($f in $files) {
        $i++
        Copy-Item -Path $f.FullName -Destination "$WorkflowsDir\$($f.Name)" -Force
    }
    Write-Host "   Converted $i workflows to $WorkflowsDir" -ForegroundColor Green
}

function Copy-Skills {
    param([string]$Src)
    if (-not (Test-Path $Src)) { return }
    New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
    $dirs = Get-ChildItem -Path $Src -Directory
    $i = 0
    foreach ($d in $dirs) {
        $srcMd = Join-Path $d.FullName "SKILL.md"
        if (-not (Test-Path $srcMd)) { continue }
        $i++
        $destDir = "$SkillsDir\$($d.Name)"
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        Copy-Item -Path $srcMd -Destination "$destDir\SKILL.md" -Force
    }
    Write-Host "   Converted $i skills to $SkillsDir" -ForegroundColor Green
}

function Copy-Flat {
    param([string]$Src, [string]$Dest)
    if (-not (Test-Path $Src)) { return }
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    $files = Get-ChildItem -Path $Src -File
    foreach ($f in $files) { Copy-Item -Path $f.FullName -Destination "$Dest\$($f.Name)" -Force }
}

function Update-GeminiConfig {
    param()
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $sectionHeader = "## Workspace Manager (installed $now)"
    $sectionBody = @"
### Available Commands
- /init-wm — Initialize workspace
- /sync-awf — Sync AWF workflows + skills
- /sync-context — Sync context files
- /sync-tool — Sync tools from marketplace
- /save-brain-wm — Save session state
- /recap-wm — Resume session
- /help-wm — Show help

### Available Skills
Skills installed to `~/.gemini/config/skills/`.
See `/help-wm` for skill descriptions.

### Context Loading
- L0: 00_System/01_context/business-context.md
- L1: 00_System/01_context/domain-context.md
- L2: [workspace]/00_context/project-context.md
"@

    $existingContent = ""
    if (Test-Path $GeminiConfigFile) {
        $existingContent = Get-Content -Path $GeminiConfigFile -Raw -Encoding UTF8
    }

    # If WM section already exists, replace it
    if ($existingContent -match "## Workspace Manager \(installed") {
        $existingContent = $existingContent -replace "(?ms)## Workspace Manager \(installed.*?)(\r?\n##|\r?\n\s*$)", "$sectionHeader`n$sectionBody`n`n`$2"
    } else {
        # Append new section
        $existingContent += "`n`n$sectionHeader`n$sectionBody`n"
    }

    $parent = Split-Path $GeminiConfigFile -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    [System.IO.File]::WriteAllText($GeminiConfigFile, $existingContent, $utf8NoBom)
    Write-Host "   Updated GEMINI.md: $GeminiConfigFile" -ForegroundColor Green
}

switch ($ResourceType) {
    "workflows" { Copy-Workflows -Src (Join-Path $SourceDir "workflows") }
    "skills" { Copy-Skills -Src (Join-Path $SourceDir "skills") }
    "schemas" { Copy-Flat -Src (Join-Path $SourceDir "schemas") -Dest $SchemasDir }
    "templates" { Copy-Flat -Src (Join-Path $SourceDir "templates") -Dest $TemplatesDir }
    "all" {
        Copy-Workflows -Src (Join-Path $SourceDir "workflows")
        Copy-Skills -Src (Join-Path $SourceDir "skills")
        Copy-Flat -Src (Join-Path $SourceDir "schemas") -Dest $SchemasDir
        Copy-Flat -Src (Join-Path $SourceDir "templates") -Dest $TemplatesDir
        if ($RegisterInConfig) { Update-GeminiConfig }
    }
}

Write-Host "Conversion complete for target: Antigravity" -ForegroundColor Yellow
