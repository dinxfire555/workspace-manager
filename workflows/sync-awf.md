---
description: Synchronize AWF workflows and skills from workspace-manager repository
---

# Workflow: /sync-awf

Synchronize AWF (Antigravity Workflow Framework) workflows and skills from the workspace-manager repository. Separated from the main install pipeline so users can opt in to AWF assets.

## Overview

After v2, AWF workflows and skills are NOT downloaded during install. Run `/sync-awf` to fetch and install them on demand.

**Features**: AWF workflow sync, AWF skill sync, diff-based update, guard check

---

## Pipeline

### Step 0: GUARD — Check .wm-env.json

```
Check if .wm-env.json exists in the project root:
 YES → continue to Step 1
 NO → Display:
  "Workspace not initialized. Run /init-wm first to set up your workspace,
   then run /sync-awf to download AWF assets."
  STOP — do not proceed
```

This prevents misleading errors when running on an uninitialized workspace.

### Step 1: Read Configuration

```
Read .wm-env.json → workspace_manager section
Extract: raw_url, branch, type (github/gitlab)
Build base URL for fetching AWF assets
```

### Step 2: Fetch AWF Workflow List

```
Fetch from {workspace_manager.raw_url}/awf-workflows/
List available .md files (plan-awf.md, design-awf.md, ...)
```

### Step 3: Fetch AWF Skills

```
Fetch from {workspace_manager.raw_url}/skills/awf-skills/
List available subdirectories with SKILL.md files
```

### Step 4: Compare with Local

```
Compare remote AWF workflows against local awf-workflows/
Compare remote AWF skills against local skills/awf-skills/

Categories:
 NEW — on remote but not locally
 UPDATED — different version (from frontmatter)
 OBSOLETE — local but not on remote
 SYNCED — same version both sides
```

### Step 5: Show Diff

```
Display summary:

 AWF SYNC STATUS

 Local AWF workflows: N
 Remote AWF workflows: N

 New: 0 | Updated: 0 | Synced: N | Obsolete: 0

 Local AWF skills: N
 Remote AWF skills: N

 New: 0 | Updated: 0 | Synced: N | Obsolete: 0
```

### Step 6: Ask User

```
Ask: "Apply updates? [Y]es / [N]o / [S]elect specific"
 Y → install all new/updated, skip obsolete
 N → cancel, no changes
 S → show numbered list, user picks which to install
```

### Step 7: Convert and Install

```
For each selected AWF workflow:
 Download from remote
 Detect CLI/IDE target (reuse install.ps1 Step1-DetectTargets logic)
 Call convert-to-{target}.ps1
 Install to target directory

For each selected AWF skill:
 Download from remote
 Detect CLI/IDE target
 Call convert-to-{target}.ps1
 Install to target skills directory
  
REGISTER:
 Register in config (opencode.jsonc / claude.json / config.json / GEMINI.md)
 Supported targets: claude-code, opencode, codex, antigravity
```

### Step 8: Report Results

```
Display:

 AWF SYNC COMPLETE

 Downloaded: N workflows, N skills
 Installed: N workflows, N skills
 Skipped: N
 Failed: N

Registered to {claude-code, opencode, codex, antigravity} N workflows, N skills

 AWF workflows are now available:
 /plan-awf, /design-awf, /code-awf, /test-awf, ...
```

---

## Guard Behavior

- `/sync-awf` MUST NOT attempt to run if `.wm-env.json` is missing
- Fallback: inform user to run `/init-wm` first, then retry
- This prevents misleading errors when invoked on an uninitialized workspace

---

## Offline Mode

When workspace-manager repo is unreachable:
1. Detect network failure (try HEAD request, 3s timeout)
2. Show detailed error:
   "❌ Cannot reach workspace-manager repository at [URL].
    Reason: [timeout / auth required / not found]
    
    Options:
    (A) Retry
    (B) Update workspace_manager URL in .wm-env.json
    (C) Set WM_GITLAB_TOKEN for private repo access
    (D) Cancel"
3. Wait for user choice before proceeding

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `.wm-env.json` missing | Show guide, stop |
| Network timeout | Retry once; if fails ask user: (A) retry (B) fix URL (C) set token (D) cancel |
| Converter not found | Skip that target, continue with others |
| Download fails for specific item | Skip, continue, report in final summary |
| All downloads fail | "No AWF assets could be downloaded. Check your network." |

---

## References

- **Dependency**: Requires `.wm-env.json` (created by `/init-wm`)
- **Related**: `/init-wm` (workspace initialization), `/sync-tool` (fci-skills sync)
- **AWF workflows**: `awf-workflows/` (plan-awf, design-awf, code-awf, ...)
- **AWF skills**: `skills/awf-skills/` (awf-adaptive-language, awf-auto-save, ...)
