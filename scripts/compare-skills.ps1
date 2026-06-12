param(
    [string]$LocalSkillsDir = '',
    [string]$RemoteSkillsDir = '',
    [string]$LocalConfigPath = '',
    [ValidateSet('opencode','claude','both')]
    [string]$Target = 'opencode',
    [string]$Role = '',
    [switch]$Detailed
)

<#
.SYNOPSIS
    Compare locally installed tools/skills against remote marketplace offerings.
.DESCRIPTION
    Analyzes the difference between locally installed AI tools and tools available
    in the FCI skills marketplace. Generates a structured diff: new tools available,
    tools needing updates, and tools only available locally.
.PARAMETER LocalSkillsDir
    Path to locally installed skills directory
.PARAMETER RemoteSkillsDir
    Path to fetched remote tools directory
.PARAMETER LocalConfigPath
    Path to local config file (opencode.jsonc or CLAUDE.md)
.PARAMETER Target
    Which AI tool target to analyze (opencode, claude, or both)
.PARAMETER Role
    Filter recommendations by role
.PARAMETER Detailed
    Show detailed comparison including version info
#>

# ?? Default Paths ??????????????????????????????????????????????????????
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not $LocalSkillsDir) {
    switch ($Target) {
        'opencode' { $LocalSkillsDir = '$env:USERPROFILE\.config\opencode\awf-skills' }
        'claude'   { $LocalSkillsDir = '$env:USERPROFILE\.claude\skills' }
        'both'     { $LocalSkillsDir = '$env:USERPROFILE\.config\opencode\awf-skills' }
    }
}

if (-not $RemoteSkillsDir) {
    $RemoteSkillsDir = '$env:TEMP\wm-tools'
}

# ?? Helper: Discover local skills ??????????????????????????????????????
function Get-LocalSkills {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) { return @() }
    $skills = @()
    $skillDirs = Get-ChildItem -Path $Dir -Directory -ErrorAction SilentlyContinue
    foreach ($sd in $skillDirs) {
        $skillMd = Join-Path $sd.FullName 'SKILL.md'
        $version = 'unknown'
        $description = ''
        if (Test-Path $skillMd) {
            $content = Get-Content -Path $skillMd -Raw -Encoding UTF8
            if ($content -match 'version:\s*([\d.]+)') { $version = $matches[1] }
            if ($content -match 'description:\s*>(.+?)\n') {
                $description = $matches[1].Trim()
            } elseif ($content -match 'description:\s*''(.+?)''') {
                $description = $matches[1]
            }
        }
        $skills += [PSCustomObject]@{
            Name        = $sd.Name
            Version     = $version
            Description = $description
            Source      = 'local'
            Path        = $sd.FullName
            LastModified = $sd.LastWriteTime
        }
    }
    return $skills
}

# ?? Helper: Discover remote skills ?????????????????????????????????????
function Get-RemoteSkills {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) { return @() }
    $skills = @()
    $toolDirs = Get-ChildItem -Path $Dir -Directory -ErrorAction SilentlyContinue
    foreach ($td in $toolDirs) {
        $readme = Join-Path $td.FullName 'README.md'
        $description = ''
        $version = 'unknown'
        if (Test-Path $readme) {
            $content = Get-Content -Path $readme -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content -match '# (.+)') { $description = $matches[1] }
        }
        $skills += [PSCustomObject]@{
            Name        = $td.Name
            Version     = $version
            Description = $description
            Source      = 'remote'
            Path        = $td.FullName
            LastModified = $td.LastWriteTime
        }
    }
    return $skills
}

# ?? Role-based filter ??????????????????????????????????????????????????
$roleToolMapping = @{
    'Dev'    = @('guideline-conv-ui', 'ctx-init', 'prototype-generator', 'task-architecture-decision-record', 'task-architecture-proposal')
    'PO'     = @()
    'PM'     = @('prototype-generator', 'company-docsmith')
    'BA'     = @('guideline-conv-ui', 'company-docsmith')
    'Tester' = @()
    'SM'     = @()
}

# ?? Main Comparison ????????????????????????????????????????????????????
Write-Host '????????????????????????????????????????????????????' -ForegroundColor Cyan
Write-Host '  SKILLS COMPARISON ENGINE' -ForegroundColor Cyan
Write-Host '????????????????????????????????????????????????????' -ForegroundColor Cyan
Write-Host ''

$localSkills = Get-LocalSkills -Dir $LocalSkillsDir
$remoteSkills = Get-RemoteSkills -Dir $RemoteSkillsDir

Write-Host "Local skills found: $($localSkills.Count)" -ForegroundColor Cyan
Write-Host "Remote tools found: $($remoteSkills.Count)" -ForegroundColor Cyan
Write-Host ''

# Create lookup maps
$localNames = $localSkills | ForEach-Object { $_.Name } | ForEach-Object { $_ }  # flatten
$remoteNames = $remoteSkills | ForEach-Object { $_.Name } | ForEach-Object { $_ }

# Categorize
$newTools = $remoteSkills | Where-Object { $_.Name -notin $localNames }
$missingLocal = $localSkills | Where-Object { $_.Name -notin $remoteNames }
$common = $localSkills | Where-Object { $_.Name -in $remoteNames }

# Version comparison for common tools
$needsUpdate = @()
foreach ($tool in $common) {
    $remote = $remoteSkills | Where-Object { $_.Name -eq $tool.Name } | Select-Object -First 1
    if ($remote.Version -ne 'unknown' -and $tool.Version -ne 'unknown' -and $remote.Version -ne $tool.Version) {
        $needsUpdate += [PSCustomObject]@{
            Name           = $tool.Name
            LocalVersion   = $tool.Version
            RemoteVersion  = $remote.Version
        }
    }
}

# Report
if ($newTools.Count -gt 0) {
    Write-Host "?? NEW TOOLS AVAILABLE ($($newTools.Count)):" -ForegroundColor Green
    foreach ($t in $newTools) {
        Write-Host "   [+] $($t.Name)" -ForegroundColor Green
        if ($Detailed -and $t.Description) { Write-Host "       $($t.Description)" -ForegroundColor Gray }
    }
    Write-Host ''
}

if ($needsUpdate.Count -gt 0) {
    Write-Host "?? TOOLS NEEDING UPDATE ($($needsUpdate.Count)):" -ForegroundColor Yellow
    foreach ($t in $needsUpdate) {
        Write-Host "   [~] $($t.Name): $($t.LocalVersion) ? $($t.RemoteVersion)" -ForegroundColor Yellow
    }
    Write-Host ''
}

if ($missingLocal.Count -gt 0) {
    Write-Host "?? LOCAL-ONLY TOOLS ($($missingLocal.Count)):" -ForegroundColor DarkGray
    foreach ($t in $missingLocal) {
        Write-Host "   [L] $($t.Name) v$($t.Version)" -ForegroundColor DarkGray
    }
    Write-Host ''
}

# Role-based recommendation
if ($Role) {
    $recommended = $roleToolMapping[$Role]
    if ($recommended -and $recommended.Count -gt 0) {
        $availableRecs = $newTools | Where-Object { $_.Name -in $recommended }
        if ($availableRecs.Count -gt 0) {
            Write-Host "? RECOMMENDED FOR $Role ROLE ($($availableRecs.Count)):" -ForegroundColor Magenta
            foreach ($t in $availableRecs) {
                Write-Host "   [?] $($t.Name) - recommended for $Role" -ForegroundColor Magenta
            }
        }
    }
}

Write-Host ''
Write-Host '????????????????????????????????????????????????????' -ForegroundColor Cyan

# Return structured result
$result = [PSCustomObject]@{
    NewTools     = $newTools
    NeedsUpdate  = $needsUpdate
    MissingLocal = $missingLocal
    TotalLocal   = $localSkills.Count
    TotalRemote  = $remoteSkills.Count
}

# ?? Generate Action Summary ????????????????????????????????????????????
Write-Host ''
Write-Host 'Summary:' -ForegroundColor Yellow
Write-Host "  Install: $($newTools.Count) new tools available" -ForegroundColor Green
Write-Host "  Update:  $($needsUpdate.Count) tools have newer versions" -ForegroundColor Yellow
Write-Host "  Local:   $($missingLocal.Count) local-only (no remote equivalent)" -ForegroundColor DarkGray
Write-Host ''

return $result
