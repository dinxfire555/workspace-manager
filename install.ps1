# Workspace Manager Installer for Windows (PowerShell)
# One-line: irm https://raw.githubusercontent.com/YOUR_ORG/workspace-manager/main/install.ps1 | iex

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# ── Fix #1: Enable TLS 1.2 for GitHub raw content downloads ──
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$RepoBase = "https://gitlab.fci.vn/dungnt261/workspace-manager/-/raw/master"
$RepoWorkflows = "$RepoBase/workflows"
$RepoSchemas = "$RepoBase/schemas"
$RepoTemplates = "$RepoBase/templates"
$RepoSills = "$RepoBase/skills"
$RepoConverters = "$RepoBase/converters"

# Auth token for private repos (GitLab: ?private_token=; GitHub: ignored)
$WmToken = if ($env:WM_GITLAB_TOKEN) { "?private_token=$env:WM_GITLAB_TOKEN" } else { "" }

$WorkingDir = (Get-Location).Path

# ── Fix #3: Detect if running from cloned repo (files already local) ──
if ($MyInvocation.MyCommand.Path) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $IsLocalRepo = (Test-Path (Join-Path $ScriptDir "skills\wm-merge-context\SKILL.md")) -or `
    (Test-Path (Join-Path $ScriptDir "workflows\init-wm.md"))
}
else {
    $ScriptDir = $WorkingDir
    $IsLocalRepo = $false
}

# Get version — read local VERSION file if available, otherwise fetch remote
if ($IsLocalRepo) {
    $localVersionFile = Join-Path $ScriptDir "VERSION"
    if (Test-Path -LiteralPath $localVersionFile) {
        $WMVersion = (Get-Content -LiteralPath $localVersionFile -Raw).Trim()
    }
    else {
        $WMVersion = "1.0.0"
    }
}
else {
    try {
        $WMVersion = (Invoke-WebRequest -Uri "$RepoBase/VERSION$WmToken" -UseBasicParsing -ErrorAction Stop).Content.Trim()
    }
    catch {
        $WMVersion = "1.0.0"
    }
}

$SetupDir = "$WorkingDir\setup-wm"
$script:success = 0

function Write-Header {
    Write-Host ""
    Write-Host "Workspace Manager v$WMVersion" -ForegroundColor Cyan
    Write-Host "Enterprise AI Workspace Deployment Tool" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([int]$Step, [string]$Label, [int]$TotalSteps)
    Write-Host ""
    Write-Host "--- Step $Step/$TotalSteps : $Label ---" -ForegroundColor Yellow
}

function Write-ProgressPct {
    param([int]$Current, [int]$Total)
    $pct = 0
    if ($Total -gt 0) { $pct = [math]::Round($Current / $Total * 100) }
    Write-Host "   Progress: $Current/$Total ($pct%)" -ForegroundColor Cyan
}

# ── Helper: copy local file or download ──
function Copy-OrDownload {
    param([string]$RelativeSubPath, [string]$DestPath, [string]$Label)
    $localPath = Join-Path $ScriptDir $RelativeSubPath

    if ($IsLocalRepo -and (Test-Path $localPath)) {
        $parent = Split-Path $DestPath -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
        Copy-Item -Path $localPath -Destination $DestPath -Force
        Write-Host "      [OK] $Label (local)" -ForegroundColor Green
        $script:success += 1
        return $true
    }

    $url = "$RepoBase/$RelativeSubPath$WmToken"
    $parent = Split-Path $DestPath -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    try {
        Invoke-WebRequest -Uri $url -OutFile $DestPath -UseBasicParsing -ErrorAction Stop
        Write-Host "      [OK] $Label" -ForegroundColor Green
        $script:success += 1
        return $true
    }
    catch {
        $errMsg = $_.Exception.Message
        if ($errMsg.Length -gt 80) { $errMsg = $errMsg.Substring(0, 77) + "..." }
        Write-Host "      [--] $Label - $errMsg" -ForegroundColor Yellow
        return $false
    }
}

# STEP 1: DETECT TARGETS
function Step1-DetectTargets {
    Write-Step -Step 1 -Label "Detect CLI/IDE Target" -TotalSteps 7

    $detectedTargets = @()
    $paths = @(
        @{P = "$env:USERPROFILE\.claude"; N = "Claude Code"; I = "claude" },
        @{P = "$env:USERPROFILE\.config\opencode"; N = "Opencode"; I = "opencode" },
        @{P = "$env:USERPROFILE\.codex"; N = "Codex CLI"; I = "codex" },
        @{P = "$env:USERPROFILE\.gemini\config"; N = "Antigravity"; I = "antigravity" }
    )

    # Filter: only show targets with available converters
    $availableConverters = @("claude", "opencode", "codex", "antigravity")

    foreach ($cp in $paths) {
        if ((Test-Path $cp.P) -and ($cp.I -in $availableConverters)) {
            Write-Host "   [OK] $($cp.N)" -ForegroundColor Green
            $detectedTargets += $cp
        }
    }

    if ($detectedTargets.Count -eq 0) {
        Write-Host "   No target detected. Defaulting to Claude Code." -ForegroundColor Yellow
        $default = New-Object PSObject -Property @{I = "claude"; N = "Claude Code"; P = "$env:USERPROFILE\.claude" }
        return @($default)
    }

    if ($detectedTargets.Count -eq 1) {
        Write-Host "   Using: $($detectedTargets[0].N)" -ForegroundColor Green
        return @($detectedTargets[0])
    }

    # Multiple targets
    Write-Host "   Multiple targets detected. Select to install:" -ForegroundColor Cyan
    $idx = 0
    foreach ($t in $detectedTargets) {
        $idx += 1
        Write-Host "   [$idx] $($t.N)"
    }
    Write-Host "   [A] All" -ForegroundColor Yellow

    $selection = Read-Host "   Enter numbers (comma separated) or A for all"
    if ($selection.Trim().ToUpper() -eq "A") { return $detectedTargets }

    $selected = @()
    $parts = $selection -split ','
    foreach ($part in $parts) {
        $num = $part.Trim()
        if ($num -match '^\d+$') {
            $idx2 = [int]$num - 1
            if ($idx2 -ge 0 -and $idx2 -lt $detectedTargets.Count) {
                $selected += $detectedTargets[$idx2]
            }
        }
    }

    if ($selected.Count -eq 0) {
        Write-Host "   No valid selection. Using all targets." -ForegroundColor Yellow
        return $detectedTargets
    }
    return $selected
}

# STEP 2: DOWNLOAD SKILLS
function Step2-DownloadSkills {
    Write-Step -Step 2 -Label "Download Default Skills" -TotalSteps 7
    $skillsDir = "$SetupDir\skills"
    New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null

    if ($IsLocalRepo) {
        Write-Host "   Local repo detected - copying skills from local repository" -ForegroundColor Cyan
        $localSkills = Join-Path $ScriptDir "skills"
        if (Test-Path $localSkills) {
            Get-ChildItem $localSkills -Directory | Where-Object { $_.Name -notlike 'awf-*' } | ForEach-Object {
                $srcMd = Join-Path $localSkills "$($_.Name)\SKILL.md"
                $destMd = "$skillsDir\$($_.Name)\SKILL.md"
                if (Test-Path $srcMd) {
                    $parent = Split-Path $destMd -Parent
                    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
                    Copy-Item -Path $srcMd -Destination $destMd -Force
                    Write-Host "      [OK] $($_.Name) (local)" -ForegroundColor Green
                }
            }
            return
        }
    }

    $skillList = @("wm-merge-context", "wm-context-fetcher", "wm-tool-recommender", "wm-folder-naming")
    $cnt = $skillList.Count
    $cur = 0
    foreach ($skill in $skillList) {
        $cur += 1
        Write-ProgressPct -Current $cur -Total $cnt
        [void] (Copy-OrDownload -RelativeSubPath "skills/$skill/SKILL.md" -DestPath "$skillsDir\$skill\SKILL.md" -Label $skill)
    }
}

# STEP 3: DOWNLOAD WORKFLOWS
function Step3-DownloadWorkflows {
    Write-Step -Step 3 -Label "Download Workflows" -TotalSteps 7
    $workflowsDir = "$SetupDir\workflows"
    New-Item -ItemType Directory -Force -Path $workflowsDir | Out-Null

    if ($IsLocalRepo) {
        Write-Host "   Local repo detected - copying workflows from local repository" -ForegroundColor Cyan
        Copy-Item -Path (Join-Path $ScriptDir "workflows\*.md") -Destination "$workflowsDir\" -Force
        Write-Host "   Copied $( (Get-ChildItem "$workflowsDir" -Filter '*.md').Count) workflows" -ForegroundColor Green
        return
    }

    $mainWf = @("init-wm.md", "new-workspace.md", "new-workspace-local.md",
        "sync-context.md", "sync-tool.md", "sync-awf.md", "update-persona.md",
        "save-brain-wm.md", "recap-wm.md", "help-wm.md")

    $cnt = $mainWf.Count
    $cur = 0

    foreach ($wf in $mainWf) {
        $cur += 1
        Write-ProgressPct -Current $cur -Total $cnt
        [void] (Copy-OrDownload -RelativeSubPath "workflows/$wf" -DestPath "$workflowsDir\$wf" -Label $wf)
    }

    Write-Host "   AWF workflows are available via /sync-awf after workspace init" -ForegroundColor Gray
}

# STEP 4: DOWNLOAD SCHEMAS
function Step4-DownloadSchemas {
    Write-Step -Step 4 -Label "Download Schemas" -TotalSteps 7
    $schemasDir = "$SetupDir\schemas"
    New-Item -ItemType Directory -Force -Path $schemasDir | Out-Null

    if ($IsLocalRepo) {
        Write-Host "   Local repo detected - copying schemas from local" -ForegroundColor Cyan
        Copy-Item -Path (Join-Path $ScriptDir "schemas\*.json") -Destination "$schemasDir\" -Force
        Write-Host "   [OK] $( (Get-ChildItem "$schemasDir" -Filter '*.json').Count) schemas" -ForegroundColor Green
        return
    }

    $schemas = @("brain.schema.json", "session.schema.json", "preferences.schema.json")
    foreach ($s in $schemas) {
        [void] (Copy-OrDownload -RelativeSubPath "schemas/$s" -DestPath "$schemasDir\$s" -Label $s)
    }
}

# STEP 5: DOWNLOAD TEMPLATES
function Step5-DownloadTemplates {
    Write-Step -Step 5 -Label "Download Templates" -TotalSteps 7
    $templatesDir = "$SetupDir\templates"
    New-Item -ItemType Directory -Force -Path $templatesDir | Out-Null

    if ($IsLocalRepo) {
        Write-Host "   Local repo detected - copying templates from local" -ForegroundColor Cyan
        Copy-Item -Path (Join-Path $ScriptDir "templates\*.*") -Destination "$templatesDir\" -Force
        Write-Host "   [OK] $( (Get-ChildItem "$templatesDir" -File).Count) templates" -ForegroundColor Green
        return
    }

    $templates = @("brain.example.json", "session.example.json", "preferences.example.json",
        "AGENTS.md.template", "CLAUDE.md.template",
        "role-tools.json", "role-folders.json", "feature-context.md", ".wm-env.json")
    foreach ($t in $templates) {
        [void] (Copy-OrDownload -RelativeSubPath "templates/$t" -DestPath "$templatesDir\$t" -Label $t)
    }
}

# STEP 6: DOWNLOAD SCRIPTS + CONVERT RESOURCES
function Step6-ConvertResources {
    param($Targets)
    Write-Step -Step 6 -Label "Download Scripts + Convert Resources" -TotalSteps 7

    # Download scripts first (used by sync-tool etc.)
    $scriptsDir = "$SetupDir\scripts"
    New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null

    if ($IsLocalRepo) {
        Write-Host "   Local repo detected - copying scripts from local" -ForegroundColor Cyan
        Copy-Item -Path (Join-Path $ScriptDir "scripts\*.ps1") -Destination "$scriptsDir\" -Force
        Write-Host "   [OK] $( (Get-ChildItem "$scriptsDir" -Filter '*.ps1').Count) scripts" -ForegroundColor Green
    }
    else {
        $scriptFiles = @("fetch-context.ps1", "fetch-tools.ps1", "install-tool.ps1", "compare-skills.ps1", "create-workspace.ps1")
        foreach ($sf in $scriptFiles) {
            [void] (Copy-OrDownload -RelativeSubPath "scripts/$sf" -DestPath "$scriptsDir\$sf" -Label "scripts/$sf")
        }
    }

    # Download converters
    $convertersDir = "$SetupDir\converters"
    New-Item -ItemType Directory -Force -Path $convertersDir | Out-Null

    if ($IsLocalRepo) {
        Write-Host "   Local repo detected - copying converters from local" -ForegroundColor Cyan
        Copy-Item -Path (Join-Path $ScriptDir "converters\*.*") -Destination "$convertersDir\" -Force
    }
    else {
        $convFiles = @("target-mapping.json", "convert-to-opencode.ps1", "convert-to-claude.ps1", "convert-to-codex.ps1", "convert-to-antigravity.ps1")
        foreach ($cf in $convFiles) {
            [void] (Copy-OrDownload -RelativeSubPath "converters/$cf" -DestPath "$convertersDir\$cf" -Label "converters/$cf")
        }
    }

    $totalTargets = $Targets.Count
    $tIdx = 0
    foreach ($target in $Targets) {
        $tIdx += 1
        $tName = $target.N
        $tPath = $target.P
        $tId = $target.I
        Write-Host "   Converting for target [$tIdx/$totalTargets]: $tName" -ForegroundColor Cyan

        # Copy scripts/ to target (needed by sync-tool, sync-context, etc.)
        $targetScripts = "$tPath\scripts"
        if (Test-Path "$SetupDir\scripts") {
            New-Item -ItemType Directory -Force -Path $targetScripts | Out-Null
            Copy-Item -Path "$SetupDir\scripts\*.ps1" -Destination $targetScripts -Force
            Write-Host "      Scripts copied to $targetScripts" -ForegroundColor Gray
        }

        # Copy templates/ to target (needed by update-persona, sync-tool, etc.)
        $targetTemplates = "$tPath\templates"
        if (Test-Path "$SetupDir\templates") {
            New-Item -ItemType Directory -Force -Path $targetTemplates | Out-Null
            Copy-Item -Path "$SetupDir\templates\*.*" -Destination $targetTemplates -Force
            Write-Host "      Templates copied to $targetTemplates" -ForegroundColor Gray
        }

        # Run converter script
        $converterScript = "$convertersDir\convert-to-$tId.ps1"
        if (Test-Path $converterScript) {
            & $converterScript -ResourceType "all" -SourceDir $SetupDir -TargetBasePath $tPath -RegisterInConfig
        }
        else {
            # Fallback: copy directly
            Write-Host "   No converter for $tName - copying directly" -ForegroundColor Yellow
            $workflowsDir = switch ($tId) {
                "opencode" { "awf-workflows" }
                "antigravity" { "global_workflows" }
                default { "commands" }
            }
            $skillsDir = if ($tId -eq "opencode") { "awf-skills" } else { "skills" }
            $targetWorkflows = "$tPath\$workflowsDir"
            $targetSkills = "$tPath\$skillsDir"
            if (Test-Path "$SetupDir\workflows") {
                New-Item -ItemType Directory -Force -Path $targetWorkflows | Out-Null
                Copy-Item -Path "$SetupDir\workflows\*.md" -Destination $targetWorkflows -Force
            }
            if (Test-Path "$SetupDir\skills") {
                New-Item -ItemType Directory -Force -Path $targetSkills | Out-Null
                Get-ChildItem "$SetupDir\skills" -Directory | ForEach-Object {
                    $dest = "$targetSkills\$($_.Name)"
                    New-Item -ItemType Directory -Force -Path $dest | Out-Null
                    Copy-Item -Path "$($_.FullName)\SKILL.md" -Destination "$dest\SKILL.md" -Force
                }
            }
            if (Test-Path "$SetupDir\schemas") {
                $targetSchemas = "$tPath\schemas"
                New-Item -ItemType Directory -Force -Path $targetSchemas | Out-Null
                Copy-Item -Path "$SetupDir\schemas\*.json" -Destination $targetSchemas -Force
            }
        }
    }
}

# STEP 7: SAVE VERSION
function Step7-SaveVersion {
    param($Targets)
    Write-Step -Step 7 -Label "Save Version" -TotalSteps 7

    foreach ($target in $Targets) {
        $tPath = $target.P
        $tName = $target.N
        $versionFile = "$tPath\wm-version"
        $versionDir = Split-Path $versionFile -Parent
        if (-not (Test-Path $versionDir)) { New-Item -ItemType Directory -Force -Path $versionDir | Out-Null }

        $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $content = "Workspace Manager v$WMVersion`r`n"
        $content += "Installed: $now`r`n"
        $content += "Target: $tName`r`n"
        $content += "Repo: $RepoBase`r`n"

        [System.IO.File]::WriteAllText($versionFile, $content, $utf8NoBom)
        Write-Host "   Version saved: $versionFile" -ForegroundColor Green
    }
}

# MAIN
Write-Header

if ($IsLocalRepo) {
    Write-Host "Local repository detected - using local files" -ForegroundColor Green
}
else {
    Write-Host "Online mode - downloading from $RepoBase" -ForegroundColor Gray
}

try {
    $selectedTargets = Step1-DetectTargets
    Write-Host "   Selected $($selectedTargets.Count) target(s)" -ForegroundColor Green

    New-Item -ItemType Directory -Force -Path $SetupDir | Out-Null

    Step2-DownloadSkills
    Step3-DownloadWorkflows
    Step4-DownloadSchemas
    Step5-DownloadTemplates
    Step6-ConvertResources -Targets $selectedTargets
    Step7-SaveVersion -Targets $selectedTargets

    Write-Host ""
    Write-Host "WORKSPACE MANAGER INSTALLATION COMPLETE!" -ForegroundColor Yellow
    Write-Host "Version: $WMVersion" -ForegroundColor Cyan
    Write-Host "To initialize: /init-wm" -ForegroundColor Cyan

}
catch {
    Write-Host ""
    Write-Host "Installation failed: $_" -ForegroundColor Red
    exit 1
}
