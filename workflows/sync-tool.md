---
description: Sync tools from FCI Skills Market compare, recommend, install
---

# Workflow: /sync-tool

Synchronize AI coding tools from the FCI Skills GitLab marketplace. Compares locally installed tools against available market tools, recommends based on role, and supports one-click install.

## Overview

Keep your AI development tools up-to-date by syncing with the centralized FCI Skills market. The workflow discovers local tools, fetches the marketplace manifest, compares both sides, and guides you through installation.

**Features**: F-21 (sync-tool), F-22 (skills comparison), F-23 (role-based recommendation), F-24 (GitLab integration), F-25 (one-click install), F-26 (default skills bundle)

---

## Pipeline

### Step 1: Detect Local Tools + CLI/IDE Target

```
Detect current CLI/IDE target (reuse install.ps1 Step1-DetectTargets logic):
 Check paths:
  ~/.claude/          → target = "claude-code"
  ~/.config/opencode/ → target = "opencode"
  ~/.codex/           → target = "codex"
  ~/.gemini/config/   → target = "antigravity"
 Default to "claude-code" if no target detected

Scan for installed tools in the detected target directory:
 Skills: {target_base}/skills/ (list subdirectories with SKILL.md)
 Commands: {target_base}/commands/ (list .md files) or config file
 For each tool collect:
  Name
  Version (from YAML frontmatter)
  Description
```

**Input**: Filesystem path-existence scan
**Output**: `$targetId` (claude-code/opencode/codex/antigravity), `$localTools` array

---

### Step 2: Fetch Marketplace (F-24)

```
Read .wm-env.json for fci-skills configuration.
Use Get-ResourceUrl(source, subPath) helper to build URLs.

Access fci-skills marketplace:
 URL: {fci_skills.raw_url}/.claude-plugin/marketplace.json
 Auth: $env:WM_GITLAB_TOKEN (Bearer token, for GitLab only)

On success:
 Parse plugins array from marketplace manifest
 Extract per-plugin: name, description, author, category, source
 Cache manifest to .brain/tool_cache/marketplace.json
 Output: $marketTools array

On failure:
 Use cached manifest (if available, show age)
 If no cache "Cannot reach GitLab. Try again later."
 Offer offline mode with cached data only
```

**GitLab auth note**: If `$env:WM_GITLAB_TOKEN` is not set, show:
```
 GitLab token not found. Set $env:WM_GITLAB_TOKEN for full access.
Proceeding without auth (public tools only).
```

**Input**: GitLab API call
**Output**: `$marketTools` array with available plugins

---

### Step 3: Compare Local vs Market (F-22)

```
Run skills comparison:

 SKILLS COMPARISON


 Local tools found: 9
 Market tools found: 9

 NEW TOOLS AVAILABLE (2):
 [+] company-guideline-django Django guidelines
 [+] init-zhcc Zero Human Code Commit

 TOOLS NEEDING UPDATE (1):
 [~] wm-merge-context: 1.0.0 2.0.0

 LOCAL-ONLY TOOLS (3):
 [L] awf-adaptive-language (custom skill)
 [L] awf-auto-save (custom skill)
 [L] wm-context-fetcher (custom skill)


```

Categories:
- **New tools**: On market but not installed locally
- **Needs update**: Different version locally vs market
- **Local-only**: Installed but not in market (custom skills)
- **Synced**: Same version both sides

**Input**: `$localTools` + `$marketTools`
**Output**: Comparison result with 4 categories

---

### Step 4: Filter by Role Recommendations (F-23)

```
Load role-tools mapping from templates/role-tools.json:

| Role | Recommended Tools |
|---------|-------------------------------------------------------|
| Dev | ctx-init, guideline-conv-ui, prototype-generator, ... |
| PO | company-docsmith, prototype-generator |
| PM | company-docsmith, prototype-generator, ctx-init |
| BA | guideline-conv-ui, company-docsmith |
| Tester | (none specific) |
| SM | init-zhcc |

Detect user role:
 From .brain/user_info.json $role
 From preferences.json $role
 If unknown Ask: "Which role are you in? (Dev/PO/PM/BA/Tester/SM)"

Filter new tools by role:
 Recommended for your role marked with
 Other roles marked as secondary
 Optional tools marked as optional
```

**Input**: User role + role-tools mapping
**Output**: Filtered recommendation list

---

### Step 5: Display + Ask User

```

 TOOL SYNC RECOMMENDATIONS


 Your role: Dev

 RECOMMENDED FOR DEV:
 [1] ctx-init Bootstrap AI context
 [2] guideline-conv-ui AI Conversation UI guide
 [3] prototype-generator UI prototype generator
 [4] task-architecture-* ADR + Proposal tools

 OTHER AVAILABLE:
 [5] company-docsmith Documentation builder
 [6] company-guideline-django Django guidelines
 [7] init-zhcc Zero Human Code Commit
 [8] cloud-workflow-mui-to-v2 MUI migration tool

 Enter numbers to install (e.g., 1,2,3), or A for all:
 [Enter] to skip installation

On tool count:
 If 0 new tools " All tools are up-to-date! "
 If > 0 Show recommendations and ask for selection
```

**Input**: User selection
**Output**: `$selectedTools` array

---

### Step 6: One-Click Install (F-25)

```
For each selected tool:
 Step 6a: DOWNLOAD
 Source: GitLab raw URL from marketplace.source
 Target: $SetupDir/tools/[tool-name]/
 Download: README.md, skills/*.md, .claude-plugin/*

 Step 6b: CONVERT (via convert engine)
 Detect target platform from Step 1 ($targetId)
 Run convert script:
  ./converters/convert-to-{target}.ps1 -ResourceType skills
 Register in config (opencode.jsonc / claude.json / config.json / GEMINI.md)
 Supported targets: claude-code, opencode, codex, antigravity

 Step 6c: VERIFY
 Check SKILL.md exists in target skills directory
 Check config entry was added
 Report success/failure per tool

 Step 6d: LOG
 Append to .brain/session_log.txt:
 [timestamp] INSTALL: [tool-name] via sync-tool [OK]

Progress indicator:
 Installing [1/4]: ctx-init 50%
```

**Input**: `$selectedTools` names
**Output**: Installed tools with success/failure per tool

---

### Step 7: Report Results

```

 TOOL SYNC COMPLETE


 Installed (3):
 ctx-init, guideline-conv-ui, prototype-generator
 Skipped (1):
 company-docsmith (not found)
 Up-to-date (6):
 wm-merge-context, wm-context-fetcher, ...

 Total: 9 local tools, 9 market tools
 3 new, 0 updated, 3 local-only

 Next: Run /sync-context to update your context files


```

---

## Script Integration

| Script | Purpose | Called in Step |
|--------|---------|----------------|
| `scripts/fetch-tools.ps1` | Fetch marketplace manifest + metadata | Step 2 |
| `scripts/compare-skills.ps1` | Compare local vs remote skills | Step 3 |
| `converters/convert-to-opencode.ps1` | Install tools for Opencode | Step 6b |
| `converters/convert-to-claude.ps1` | Install tools for Claude Code | Step 6b |

---

## Offline Mode

When GitLab is unreachable:

```
1. Detect: try HEAD request to marketplace URL (3s timeout)
2. If fails Offline mode:
 Use cached marketplace.json from .brain/tool_cache/
 Show " Offline mode data from [date]"
 Comparison still works (local vs cache)
 Installation disabled (no download source)
 Offer: "Would you like to retry? [y/N]"
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| GitLab timeout | Retry once with 5s timeout; if fails ask user to fix URL, set token, or cancel |
| No cache available | "Cannot sync no network, no cache" |
| Marketplace parse error | Log raw response, show "Invalid manifest" |
| Download fails for specific tool | Skip, continue with remaining tools |
| Convert engine not found | "Convert scripts missing. Run install again." |
| Permission denied on install | "Cannot write to target directory. Run as admin." |
| No tools selected | "No changes made. All tools up-to-date." |

---

## Default Skills Bundle (F-26)

The following 3 WM skills are included in the default install (Step 2). AWF skills are available separately via `/sync-awf`:

| Skill | Purpose |
|-------|---------|
| `wm-merge-context` | Merge context from multiple layers |
| `wm-context-fetcher` | Fetch context from remote sources |
| `wm-tool-recommender` | Recommend tools from FCI marketplace |

For AWF skills (`awf-adaptive-language`, `awf-auto-save`, etc.), run `/sync-awf` after workspace initialization.

---

## References

- **F-21**: `/sync-tool` workflow (this file)
- **F-22**: Skills comparison engine (`scripts/compare-skills.ps1`)
- **F-23**: Role-based tool recommendation (`templates/role-tools.json`)
- **F-24**: FCI Skills GitLab integration (`scripts/fetch-tools.ps1`)
- **F-25**: One-click tool install (convert engine integration)
- **F-26**: Default skills bundle (6 AWF skills)
- **Companion**: `/sync-context` workflow (Phase 04)
- **Phase 01 dependency**: Convert engine scripts + target mapping
