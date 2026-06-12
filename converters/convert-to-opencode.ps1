param(
    [ValidateSet("workflows","awf-workflows","skills","awf-skills","schemas","templates","all")]
    [string]$ResourceType = "all",
    [string]$SourceDir = "",
    [string]$TargetBasePath = "",
    [switch]$RegisterInConfig,
    [string]$ConfigPath = ""
)

# Defaults
if (-not $TargetBasePath) { $TargetBasePath = "$env:USERPROFILE\.config\opencode" }
if (-not $ConfigPath) { $ConfigPath = "$TargetBasePath\opencode.jsonc" }
if (-not $SourceDir) { $SourceDir = (Get-Location).Path }

$WorkflowsDir = "$TargetBasePath\awf-workflows"
$SkillsDir = "$TargetBasePath\awf-skills"
$SchemasDir = "$TargetBasePath\schemas"
$TemplatesDir = "$TargetBasePath\templates"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# ── Fix: Create empty config template ──
function New-EmptyConfig {
    $empty = New-Object PSObject
    $empty | Add-Member -NotePropertyName "agent" -NotePropertyValue (New-Object PSObject) -Force
    $empty | Add-Member -NotePropertyName "command" -NotePropertyValue (New-Object PSObject) -Force
    return $empty
}

function Read-Config {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return New-EmptyConfig
    }
    $content = Get-Content -Path $Path -Raw -Encoding UTF8
    # Strip single-line comments (JSONC support)
    $content = [regex]::Replace($content, '(?m)^\s*//.*$', '')
    $content = [regex]::Replace($content, '(?<!:)\s+//[^""\n]*$', '', 'Multiline')
    try {
        $result = $content | ConvertFrom-Json
        # Ensure agent and command properties exist as PSCustomObject
        if (-not $result.agent -or $result.agent.GetType().Name -eq "Hashtable") {
            $result | Add-Member -NotePropertyName "agent" -NotePropertyValue (New-Object PSObject) -Force
        }
        if (-not $result.command -or $result.command.GetType().Name -eq "Hashtable") {
            $result | Add-Member -NotePropertyName "command" -NotePropertyValue (New-Object PSObject) -Force
        }
        return $result
    } catch {
        return New-EmptyConfig
    }
}

function Write-Config {
    param([string]$Path, [object]$Data)
    $json = $Data | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
    Write-Host "   Updated config: $Path" -ForegroundColor Green
}

# ── Fix: Safely add property using either PSObject or hashtable ──
function Add-ConfigProperty {
    param([object]$Target, [string]$Name, [object]$Value)
    if ($Target -is [System.Management.Automation.PSObject]) {
        $Target | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
    } elseif ($Target -is [hashtable]) {
        $Target[$Name] = $Value
    }
}

function Get-WorkflowDescription {
    param([string]$FilePath)
    $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    if ($content -match 'description:\s*"(.+?)"') { return $matches[1] }
    if ($content -match "description:\s*'(.+?)'") { return $matches[1] }
    $name = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    return "WM workflow: $name"
}

function Convert-Workflows {
    param([string]$SourceWorkflows)
    if (-not (Test-Path $SourceWorkflows)) { Write-Host "   No workflows dir at $SourceWorkflows"; return }
    New-Item -ItemType Directory -Force -Path $WorkflowsDir | Out-Null
    $files = Get-ChildItem -Path $SourceWorkflows -Filter "*.md" -File
    $i = 0
    foreach ($f in $files) {
        $i++
        Copy-Item -Path $f.FullName -Destination "$WorkflowsDir\$($f.Name)" -Force
    }
    Write-Host "   Converted $i workflows" -ForegroundColor Green

    # Register all workflows as both agent + command in config
    if ($RegisterInConfig -and $i -gt 0) {
        $config = Read-Config -Path $ConfigPath
        $changed = $false
        foreach ($f in $files) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
            $mdPath = "$WorkflowsDir\$($f.Name)"

            # Register as agent (subagent) so opencode can execute it
            $agentExisting = $config.agent.PSObject.Properties.Name -contains $name
            if (-not $agentExisting) {
                $desc = Get-WorkflowDescription -FilePath $f.FullName
                $agentEntry = @{
                    "description" = $desc
                    "mode" = "subagent"
                    "prompt" = "You are the WM $name workflow executor.`n`nRead the complete instructions from:`n$mdPath`n`nFollow all stages sequentially."
                    "maxSteps" = 50
                    "permission" = @{ "external_directory" = "allow" }
                }
                Add-ConfigProperty -Target $config.agent -Name $name -Value $agentEntry
                $changed = $true
            }

            # Register as command so /name is recognized
            $cmdExisting = $config.command.PSObject.Properties.Name -contains $name
            if (-not $cmdExisting) {
                $cmdEntry = @{
                    "template" = "Run the WM $name workflow. Input: {{input}}"
                    "description" = "WM workflow: $name"
                    "agent" = $name
                    "subtask" = $true
                }
                Add-ConfigProperty -Target $config.command -Name $name -Value $cmdEntry
                $changed = $true
            }
        }
        if ($changed) { Write-Config -Path $ConfigPath -Data $config }
    }
}

function Convert-Skills {
    param([string]$SourceSkills)
    if (-not (Test-Path $SourceSkills)) { Write-Host "   No skills dir at $SourceSkills"; return }
    New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
    $dirs = Get-ChildItem -Path $SourceSkills -Directory
    $i = 0
    foreach ($d in $dirs) {
        $srcMd = Join-Path $d.FullName "SKILL.md"
        if (-not (Test-Path $srcMd)) { continue }
        $i++
        $destDir = "$SkillsDir\$($d.Name)"
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        Copy-Item -Path $srcMd -Destination "$destDir\SKILL.md" -Force
    }
    Write-Host "   Converted $i skills" -ForegroundColor Green

    if ($RegisterInConfig -and $i -gt 0) {
        $config = Read-Config -Path $ConfigPath
        $changed = $false
        foreach ($d in $dirs) {
            $srcMd = Join-Path $d.FullName "SKILL.md"
            if (-not (Test-Path $srcMd)) { continue }
            $name = $d.Name
            $destDir = "$SkillsDir\$name"
            $null = $config.agent.$name
            $existing = $config.agent.PSObject.Properties.Name -contains $name
            if (-not $existing) {
                $entry = @{
                    "description" = "WM skill: $name"
                    "mode" = "subagent"
                    "prompt" = "You are the $name skill. Read: $destDir\SKILL.md"
                    "maxSteps" = 50
                    "permission" = @{ "external_directory" = "allow" }
                }
                Add-ConfigProperty -Target $config.agent -Name $name -Value $entry
                $changed = $true
            }
        }
        if ($changed) { Write-Config -Path $ConfigPath -Data $config }
    }
}

function Copy-FlatFiles {
    param([string]$Source, [string]$DestDir)
    if (-not (Test-Path $Source)) { return }
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
    $files = Get-ChildItem -Path $Source -Filter "*.json" -File
    foreach ($f in $files) {
        Copy-Item -Path $f.FullName -Destination "$DestDir\$($f.Name)" -Force
    }
}

switch ($ResourceType) {
    "workflows" { Convert-Workflows -SourceWorkflows (Join-Path $SourceDir "workflows") }
    "awf-workflows" { Convert-Workflows -SourceWorkflows (Join-Path $SourceDir "awf-workflows") }
    "skills" { Convert-Skills -SourceSkills (Join-Path $SourceDir "skills") }
    "awf-skills" { Convert-Skills -SourceSkills (Join-Path $SourceDir "skills\awf-skills") }
    "schemas" { Copy-FlatFiles -Source (Join-Path $SourceDir "schemas") -DestDir $SchemasDir }
    "templates" { Copy-FlatFiles -Source (Join-Path $SourceDir "templates") -DestDir $TemplatesDir }
    "all" {
        Convert-Workflows -SourceWorkflows (Join-Path $SourceDir "workflows")
        Convert-Workflows -SourceWorkflows (Join-Path $SourceDir "awf-workflows")
        Convert-Skills -SourceSkills (Join-Path $SourceDir "skills")
        Convert-Skills -SourceSkills (Join-Path $SourceDir "skills\awf-skills")
        Copy-FlatFiles -Source (Join-Path $SourceDir "schemas") -DestDir $SchemasDir
        Copy-FlatFiles -Source (Join-Path $SourceDir "templates") -DestDir $TemplatesDir
    }
}

Write-Host "Conversion complete for target: Opencode" -ForegroundColor Yellow
