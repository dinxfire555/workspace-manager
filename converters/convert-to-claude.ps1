param(
    [ValidateSet("workflows","skills","schemas","templates","all")]
    [string]$ResourceType = "all",
    [string]$SourceDir = "",
    [string]$TargetBasePath = "",
    [switch]$RegisterInConfig
)

if (-not $TargetBasePath) { $TargetBasePath = "$env:USERPROFILE\.claude" }
if (-not $SourceDir) { $SourceDir = (Get-Location).Path }

$CommandsDir = "$TargetBasePath\commands"
$SkillsDir = "$TargetBasePath\skills"
$SchemasDir = "$TargetBasePath\schemas"
$TemplatesDir = "$TargetBasePath\templates"

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
    $files = Get-ChildItem -Path $Src -Filter "*.json" -File
    foreach ($f in $files) { Copy-Item -Path $f.FullName -Destination "$Dest\$($f.Name)" -Force }
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
        if ($RegisterInConfig) {
          Write-Warning "RegisterInConfig not yet implemented for Claude Code target"
        }
    }
}

Write-Host "Conversion complete for target: Claude Code" -ForegroundColor Yellow
