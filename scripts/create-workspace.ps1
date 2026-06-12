# Workspace Manager - Create Workspace Script
# Automated workspace folder structure, role folders, and feature-context template creation
#
# Usage:
#   .\scripts\create-workspace.ps1 -Role "Dev BE" -Product "Omni Support"
#   .\scripts\create-workspace.ps1 -Role "PO, BA, Tester" -Product "AI Mentor" -Prefix "11" -Unit "cloud"

param(
    [Parameter(Mandatory = $true)]
    [string]$Role,

    [Parameter(Mandatory = $true)]
    [string]$Product,

    [ValidateSet("10", "11")]
    [string]$Prefix = "10",

    [string]$OutputPath = ".",

    [string]$Unit = "ai",

    [switch]$Force,

    [string]$FeatureContextSource = ""
)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Script:Errors = @()

# ── ROLE NORMALIZATION ──
function Resolve-Role {
    param([string]$RawRole)
    $trimmed = $RawRole.Trim()
    if ($trimmed -eq "") { return "" }

    $mapping = @{
        "dev" = "Dev BE"; "developer" = "Dev BE"; "coder" = "Dev BE"
        "devbe" = "Dev BE"; "dev be" = "Dev BE"; "backend" = "Dev BE"
        "devfe" = "Dev FE"; "dev fe" = "Dev FE"; "frontend" = "Dev FE"
        "po" = "PO"; "product owner" = "PO"
        "pm" = "PM"; "project manager" = "PM"
        "ba" = "BA"; "business analyst" = "BA"
        "tester" = "Tester"; "qa" = "Tester"; "qc" = "Tester"
        "sm" = "SM"; "scrum master" = "SM"
        "devops" = "DevOps"
        "designer" = "Designer"; "ux" = "Designer"; "ui" = "Designer"
        "sales" = "Sales"
        "operations" = "Operations"; "ops" = "Operations"
        "other" = "Other"
    }

    $key = $trimmed.ToLower()
    if ($mapping.ContainsKey($key)) { return $mapping[$key] }

    $validKeys = @("PO", "PM", "BA", "Dev FE", "Dev BE", "Tester", "SM", "DevOps", "Designer", "Sales", "Operations", "Other")
    if ($validKeys -contains $trimmed) { return $trimmed }

    # Unknown role -> fallback to Other
    Write-Warning "[create-workspace] Unrecognized role: '$trimmed' — using 'Other' (generic folders)"
    return "Other"
}

# ── FIND RESOURCE FILES ──
function Find-RoleFoldersJson {
    $homePath = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
    $searchPaths = @(
        (Join-Path $homePath ".config\opencode\templates\role-folders.json"),
        (Join-Path $homePath ".claude\templates\role-folders.json"),
        (Join-Path $homePath ".codex\templates\role-folders.json"),
        (Join-Path $homePath ".gemini\config\templates\role-folders.json"),
        (Join-Path $OutputPath "templates\role-folders.json"),
        (Join-Path $PSScriptRoot "..\..\templates\role-folders.json")
    )
    foreach ($p in $searchPaths) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

function Find-LocalTemplate {
    param([string]$FileName)
    $homePath = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
    $searchPaths = @(
        (Join-Path $homePath ".config\opencode\templates\$FileName"),
        (Join-Path $homePath ".claude\templates\$FileName"),
        (Join-Path $homePath ".codex\templates\$FileName"),
        (Join-Path $homePath ".gemini\config\templates\$FileName"),
        (Join-Path $OutputPath "templates\$FileName")
    )
    foreach ($p in $searchPaths) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

# ── CREATE WORKSPACE STRUCTURE ──
function New-WorkspaceStructure {
    param([string]$WorkspacePath)

    if (Test-Path -LiteralPath $WorkspacePath) {
        if (-not $Force) {
            Write-Warning "[create-workspace] Workspace already exists: $WorkspacePath — use -Force to overwrite"
            return $false
        }
        Write-Host "[create-workspace] Overwriting existing workspace: $WorkspacePath" -ForegroundColor Yellow
    }

    $dirs = @(
        $WorkspacePath,
        (Join-Path $WorkspacePath "00_context"),
        (Join-Path $WorkspacePath "00_temp")
    )
    foreach ($d in $dirs) {
        try {
            New-Item -ItemType Directory -Force -Path $d | Out-Null
        } catch {
            $Script:Errors += "Failed to create directory: $d — $_"
            return $false
        }
    }
    Write-Host "[create-workspace] Created workspace structure: $WorkspacePath" -ForegroundColor Green
    return $true
}

# ── SAVE PROJECT CONTEXT ──
function Save-ProjectContext {
    param([string]$WorkspacePath, [string]$ProductName)

    $projCtxFile = Join-Path $WorkspacePath "00_context\project-context.md"
    if (Test-Path -LiteralPath $projCtxFile) {
        Write-Host "[create-workspace] project-context.md already exists — skipped" -ForegroundColor Gray
        return
    }

    $content = @"
# $ProductName - Project Context
[NEEDS_PM] Fill in project details.
"@
    try {
        [System.IO.File]::WriteAllText($projCtxFile, $content, $utf8NoBom)
        Write-Host "[create-workspace] Created project-context.md placeholder" -ForegroundColor Green
    } catch {
        $Script:Errors += "Failed to create project-context.md: $_"
    }
}

# ── CREATE ROLE FOLDERS ──
function New-RoleFolders {
    param([string]$WorkspacePath, [string]$RolesCsv)

    # Parse comma-separated roles
    $roles = $RolesCsv -split '\s*[,&/]\s*' | Where-Object { $_ -ne '' }
    if ($roles.Count -eq 0) {
        Write-Warning "[create-workspace] No roles provided"
        return
    }

    # Resolve each role
    $resolvedRoles = @()
    foreach ($r in $roles) {
        $resolved = Resolve-Role -RawRole $r
        if ($resolved) { $resolvedRoles += $resolved }
    }

    if ($resolvedRoles.Count -eq 0) {
        $resolvedRoles = @("Other")
    }

    Write-Host "[create-workspace] Roles: $($resolvedRoles -join ', ')" -ForegroundColor Cyan

    # Read role-folders.json
    $jsonPath = Find-RoleFoldersJson
    $roleData = $null
    if ($jsonPath) {
        try {
            $roleData = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            Write-Warning "[create-workspace] Failed to parse role-folders.json: $_"
        }
    } else {
        Write-Warning "[create-workspace] role-folders.json not found — using default folders"
    }

    # Union all unique folders
    $allFolders = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($r in $resolvedRoles) {
        if ($roleData -and $roleData.roles.PSObject.Properties.Name -contains $r) {
            $folders = $roleData.roles.$r.folders
            foreach ($f in $folders) {
                [void]$allFolders.Add($f)
            }
        }
    }

    # Fallback if no folders found
    if ($allFolders.Count -eq 0) {
        @("01_docs/", "02_src/", "03_tests/") | ForEach-Object { [void]$allFolders.Add($_) }
    }

    # Create folders + .gitkeep
    $created = 0
    foreach ($f in $allFolders) {
        $fullPath = Join-Path $WorkspacePath $f
        try {
            New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
            $gitkeep = Join-Path $fullPath ".gitkeep"
            if (-not (Test-Path -LiteralPath $gitkeep)) {
                New-Item -ItemType File -Force -Path $gitkeep | Out-Null
            }
            $created++
        } catch {
            $Script:Errors += "Failed to create folder: $fullPath — $_"
        }
    }
    Write-Host "[create-workspace] Created $created role folders" -ForegroundColor Green
}

# ── DOWNLOAD FEATURE-CONTEXT TEMPLATE ──
function Save-FeatureContextTemplate {
    param([string]$WorkspacePath, [string]$UnitName)

    $tempDir = Join-Path $WorkspacePath "00_temp"
    $destFile = Join-Path $tempDir "feature-context.md"

    if (Test-Path -LiteralPath $destFile) {
        Write-Host "[create-workspace] feature-context.md already exists — skipped" -ForegroundColor Gray
        return
    }

    # Try local source first if provided
    if ($FeatureContextSource -and (Test-Path -LiteralPath $FeatureContextSource)) {
        try {
            Copy-Item -LiteralPath $FeatureContextSource -Destination $destFile -Force
            Write-Host "[create-workspace] feature-context.md copied from source: $FeatureContextSource" -ForegroundColor Green
            return
        } catch {
            Write-Warning "[create-workspace] Failed to copy from source: $_"
        }
    }

    # Try remote context-hub
    $envPath = Join-Path $OutputPath ".wm-env.json"
    if (Test-Path -LiteralPath $envPath) {
        try {
            $env = Get-Content -LiteralPath $envPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $hub = $env.context_hub
            if ($hub) {
                if ($hub.type -eq "gitlab") {
                    $remoteUrl = "$($hub.project_url)/-/raw/$($hub.branch)/context/$UnitName/feature-context.md"
                    $token = if ($env:WM_GITLAB_TOKEN) { "?private_token=$env:WM_GITLAB_TOKEN" } else { "" }
                    $remoteUrl += $token
                } else {
                    $remoteUrl = "$($hub.raw_url)/context/$UnitName/feature-context.md"
                }
                try {
                    $resp = Invoke-WebRequest -Uri $remoteUrl -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
                    if ($resp.Content -and -not [string]::IsNullOrWhiteSpace($resp.Content)) {
                        [System.IO.File]::WriteAllText($destFile, $resp.Content, $utf8NoBom)
                        Write-Host "[create-workspace] feature-context.md downloaded from remote" -ForegroundColor Green
                        return
                    }
                } catch {
                    Write-Host "[create-workspace] Remote feature-context.md not found — trying local template" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "[create-workspace] Failed to read .wm-env.json — trying local template" -ForegroundColor Yellow
        }
    }

    # Try local template
    $localTemplate = Find-LocalTemplate -FileName "feature-context.md"
    if ($localTemplate) {
        try {
            Copy-Item -LiteralPath $localTemplate -Destination $destFile -Force
            Write-Host "[create-workspace] feature-context.md copied from local template" -ForegroundColor Green
            return
        } catch {
            Write-Warning "[create-workspace] Failed to copy local template: $_"
        }
    }

    # Minimal fallback
    $minimalTemplate = @"
# Feature Context: [Feature Name]
## Overview
## Business Requirements
- [REQ-001] ...
## User Stories
- As a [role], I want [action] so that [benefit]
## Acceptance Criteria
- [ ] AC-001: ...
## Technical Notes
[NEEDS_ENG]
## Constraints
- L0: [business rule reference]
- L1: [domain rule reference]
"@
    try {
        [System.IO.File]::WriteAllText($destFile, $minimalTemplate, $utf8NoBom)
        Write-Host "[create-workspace] feature-context.md created from minimal template" -ForegroundColor Yellow
    } catch {
        $Script:Errors += "Failed to create feature-context.md: $_"
    }
}

# ═══════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════

Write-Host ""
Write-Host "Create Workspace" -ForegroundColor Cyan
Write-Host "  Role(s): $Role" -ForegroundColor Gray
Write-Host "  Product: $Product" -ForegroundColor Gray
Write-Host "  Prefix : $Prefix" -ForegroundColor Gray

$workspaceName = "${Prefix}_$Product-wp"
$workspacePath = Join-Path $OutputPath $workspaceName

# 1. Create workspace structure
$created = New-WorkspaceStructure -WorkspacePath $workspacePath
if (-not $created) {
    Write-Error "Failed to create workspace structure"
    exit 1
}

# 2. Save project context
Save-ProjectContext -WorkspacePath $workspacePath -ProductName $Product

# 3. Create role folders (union for multi-role)
New-RoleFolders -WorkspacePath $workspacePath -RolesCsv $Role

# 4. Download feature-context template
Save-FeatureContextTemplate -WorkspacePath $workspacePath -UnitName $Unit

# 5. Report
Write-Host ""
if ($Script:Errors.Count -gt 0) {
    Write-Host "WARNINGS:" -ForegroundColor Yellow
    foreach ($e in $Script:Errors) {
        Write-Host "  - $e" -ForegroundColor Yellow
    }
}

Write-Host "Workspace created: $workspacePath" -ForegroundColor Green
Write-Host ""
Get-ChildItem -LiteralPath $workspacePath -Recurse -Depth 2 | ForEach-Object {
    $prefix = if ($_.PSIsContainer) { "[DIR]" } else { "[FILE]" }
    $relative = $_.FullName.Substring($workspacePath.Length + 1)
    Write-Host "  $prefix $relative" -ForegroundColor Gray
}

exit 0
