param(
    [ValidateSet("workflows","skills","schemas","templates","all")]
    [string]$ResourceType = "all",
    [string]$SourceDir = "",
    [string]$TargetBasePath = "",
    [switch]$RegisterInConfig
)

# Target: ~/.codex/
# Workflows → ~/.codex/commands/<name>.md
# Skills → ~/.codex/skills/<name>/SKILL.md
# Config → ~/.codex/config.json

if (-not $TargetBasePath) { $TargetBasePath = "$env:USERPROFILE\.codex" }
if (-not $SourceDir) { $SourceDir = (Get-Location).Path }

$CommandsDir = "$TargetBasePath\commands"
$SkillsDir = "$TargetBasePath\skills"
$SchemasDir = "$TargetBasePath\schemas"
$TemplatesDir = "$TargetBasePath\templates"
$ConfigFile = "$TargetBasePath\config.json"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Copy-Workflows {
    param([string]$Src)
    if (-not (Test-Path $Src)) { return }
    New-Item -ItemType Directory -Force -Path $CommandsDir | Out-Null
    $files = Get-ChildItem -Path $Src -Filter "*.md" -File
    $i = 0
    foreach ($f in $files) {
        $i++
        Copy-Item -Path $f.FullName -Destination "$CommandsDir\$($f.Name)" -Force
    }
    Write-Host "   Converted $i workflows to $CommandsDir" -ForegroundColor Green
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

function Update-CodexConfig {
    param()
    $config = @{}
    if (Test-Path $ConfigFile) {
        try { $config = Get-Content -Path $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable } catch {}
    }

    if (-not $config.ContainsKey("skills")) { $config["skills"] = @{} }
    if (-not $config.ContainsKey("commands")) { $config["commands"] = @{} }

    # Register skills from target skills directory
    if (Test-Path $SkillsDir) {
        $skillDirs = Get-ChildItem -Path $SkillsDir -Directory
        foreach ($sd in $skillDirs) {
            $skillMd = Join-Path $sd.FullName "SKILL.md"
            if (Test-Path $skillMd) {
                $config["skills"][$sd.Name] = @{ "path" = "$SkillsDir\$($sd.Name)\SKILL.md" }
            }
        }
    }

    # Register workflows from target commands directory
    if (Test-Path $CommandsDir) {
        $wfFiles = Get-ChildItem -Path $CommandsDir -Filter "*.md" -File
        foreach ($wf in $wfFiles) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($wf.Name)
            $config["commands"][$name] = @{ "path" = "$CommandsDir\$($wf.Name)" }
        }
    }

    $json = $config | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($ConfigFile, $json, $utf8NoBom)
    Write-Host "   Updated config: $ConfigFile" -ForegroundColor Green
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
        if ($RegisterInConfig) { Update-CodexConfig }
    }
}

Write-Host "Conversion complete for target: Codex CLI" -ForegroundColor Yellow
