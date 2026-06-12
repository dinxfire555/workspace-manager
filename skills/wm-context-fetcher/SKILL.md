---
name: wm-context-fetcher
description: >-
 Fetch context from remote sources (GitLab context-hub, GitHub) and sync locally.
 Handles auth via environment variables and caches results for offline use.
 Supports L0/L1/L2 hierarchy, Gene Flow validation, and template fallback.
 Keywords: fetch, sync, context, remote, gitlab, download, cache, L0, L1, L2, gene-flow.
version: 2.0.0
---

# WM Context Fetcher (F-15, F-17, F-18)

Fetch and sync context files from remote sources (GitLab Context Hub, GitHub repositories). Supports the **4-Layer AI Context Architecture** with Gene Flow enforcement and offline fallback.

## Trigger Conditions

**Called from:** `/sync-context` workflow (Phase 04)
**Called from:** `/init-wm` Step 2c (Phase 02)
**Post-hook for:** `/new-workspace`, `/new-workspace-local`

## Purpose

Ensure the local workspace has the latest context from the central Context Hub repository. This skill handles the fetch, comparison, download, and cache operations that power the `/sync-context` workflow.

## Execution Logic

### Step 1: Determine Fetch Target

```
Ask: "Which layer to sync?"

L0 Business Context
 URL chain (tried in order):
  [1] context/[Unit]/business-context.md
  [2] context/[Unit]/[Unit]_business-context.md
 Local: 00_System/01_context/business-context.md (or legacy 00_System/context/business-context.md)
 IMMUTABLE: Never overwritten by lower layers
 Redirect detection: if content is a single .md filename → re-fetch target file.

L1 Domain Context
 URL chain (tried in order):
  [1] context/[Unit]/[Dept]/domain-context.md
  [2] context/[Unit]/[Dept]/[Dept]_business-context.md
 Local: 00_System/01_context/domain-context.md (or legacy 00_System/context/domain-context.md)
 Must trace compliance to L0

L2 Project Context
 URL chain (tried in order):
  [1] context/[Unit]/[Dept]/[Product]/project-context.md
  [2] context/[Unit]/[Dept]/[Product]_domain-context.md
  [3] context/[Unit]/project-context.md (block-level template)
 Local: [workspace]/00_context/project-context.md (or legacy [workspace]/context/project-context.md)
 Delta-only (must not repeat L0/L1 content)

L3 Feature Context
 URL: context/[Unit]/feature-context.md
 Local: [workspace]/00_temp/feature-context.md
```

**Resolution of Unit/Department/Product** (priority order):
1. From command arguments (most explicit)
2. From `.brain/user_info.json`
3. From current workspace folder name (parse pattern `10_[Product]-wp`)
4. From user prompt

### Step 2: Fetch from Remote

**Pre-step:** Fetch `context/context-manifest.md` to build the URL registry. Cache to `.brain/context_cache/`.

```
# Use Resolve-ContextUrl from fetch-context.ps1 (v2.1):
#  1. Tries manifest-preferred paths first
#  2. Falls back through chain (standard → {Unit}_business-context pattern)
#  3. HEAD-checks each URL, returns first 200
#  4. After download → redirect detection (single-line .md filename → re-fetch)

# Example chain for L0 (ai):
#  [1] context/ai/business-context.md      → redirect → FPT.AI_business-context.md
#  [2] context/ai/ai_business-context.md    (fallback, not reached)

# Example chain for L1 (ai, genai-center):
#  [1] context/ai/genai-center/domain-context.md  → redirect → GenAI-Center_business-context.md
#  [2] context/ai/genai-center/genai-center_business-context.md (fallback)

# Fetch with retry + redirect
$retries = 2
$success = $false
while ($retries -ge 0 -and -not $success) {
 try {
  $response = Invoke-WebRequest -Uri $url -Headers @{
  "Authorization" = "Bearer $token"
  } -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
  $content = $response.Content
  $success = $true
  } catch {
  $retries--
 if ($retries -ge 0) { Start-Sleep -Seconds 2 }
 }
}
```

**Success paths:**
- 200 OK Return content, update cache
- 404 Not Found Enter template fallback mode
- Timeout/Network error Enter offline mode

### Step 3: Compare with Local Version

```
For each level requested:
 Compute SHA256 hash of local file (if exists)
 Compute SHA256 hash of remote content
 Hashes match "Up-to-date" Skip (no download needed)
 Hashes differ Show diff summary:
 Lines added: N
 Lines removed: N
 Sections changed: [list ## headers]

Diff presentation:

 L0 Business Context: UPDATE AVAILABLE


 Current: 120 lines, 8 sections
 Remote: 145 lines, 9 sections (+25 lines, +1 section)

 Added section: "## Security Requirements"
 Modified: "## Compliance" (12 lines changed)

 Update? [y/N]

```

### Step 4: Download and Apply

```
For each level confirmed for update:
 Level is L0:
 Warning: "L0 is immutable enterprise context. Confirm update? [y/N]"
 If L0 file exists Create backup: 00_System/01_context/business-context.md.bak
  Write new content to 00_System/01_context/business-context.md

  Level is L1:
  Run Gene Flow validation (Step 5)
  Create backup if exists
  Write new content to 00_System/01_context/domain-context.md

  Level is L2:
  Run Gene Flow validation (Step 5)
  Create backup if exists
  Write new content to [workspace]/00_context/project-context.md
```

### Step 5: Gene Flow Validation (F-16)

```
After download, validate the context hierarchy:

L0:
 Must contain: <!-- IMMUTABLE --> markers on critical sections
 Must contain ## Overview, ## Compliance sections
 Must be placed at 00_System/01_context/ (never in workspace)

L1:
 Each section must reference L0 sections via [L0:section-id]
 Must not duplicate L0 content (delta-only rule)
 Must contain ## Dependencies section listing L0 sources
 Must be placed at 00_System/01_context/ (alongside L0)

L2:
 Must trace compliance to L0 rules
 Must list dependencies to L1 domain rules
 Must not repeat L0/L1 content
 Must be placed in [workspace]/00_context/ (separate from L0/L1)
```

**Validation failure responses:**
- Warning-only: "Section XYZ missing L0 reference"
- Blocking: "L0 file would be overwritten by L1 sync blocked"

### Step 6: Update Cache

```
After successful download, update local cache:
 .brain/context_cache/[level]/
 business-context.md (L0)
 domain-context.md (L1)
 project-context.md (L2)
 .brain/context_cache/version.json
 {
 "last_sync": "2026-06-07T12:00:00Z",
 "levels": ["L0","L1"],
 "hashes": {"L0":"sha256:abc..."},
 "source": "gitlab.context-hub"
 }
```

### Step 7: Handle Missing Context (F-18)

When a context file is not found on the hub:

```
1. Check for template in repositories/context-hub/context/[Unit]/
2. If template exists:
 Load template content
 Add warning header: " Auto-generated from template needs review"
 Use template as content
3. If no template:
 Show notification with missing path
 Offer options:
 1. Create from scratch (empty template with guide)
 2. Skip this level
 3. Ask for help in #context-hub Slack channel
 Record in sync log as "MISSING"
```

### Step 8: Log Results

```powershell
# Append to .brain/session_log.txt
$logEntry = "[$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')] SYNC-CONTEXT: L0=updated, L1=up-to-date, L2=template-fallback"
Add-Content -Path ".brain/session_log.txt" -Value $logEntry -Encoding UTF8
```

---

## Offline / Cache Mode

When GitLab is unreachable:

```
1. Test connectivity: HEAD request (3s timeout)
2. If offline:
 Load cached context from .brain/context_cache/
 Show: " Offline mode using cache from [date]"
 If cache > 7 days: " Cache is stale consider retrying"
 Offer: "Retry now? [y/N]" or "Continue with cached version?"
```

---

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| level | string | Yes | | L0, L1, or L2 |
| unit | string | Yes | | Business unit (ai, cloud) |
| department | string | L1/L2 | | Department name |
| product | string | L2 | | Product name |
| force | bool | No | false | Skip diff prompt, overwrite |
| offline | bool | No | false | Force offline mode |
| output | string | No | auto | Custom output path |

---

## Error Handling

| Scenario | Action |
|----------|--------|
| GitLab timeout (10s) | Retry x2; fallback to cache or template |
| No token set | Proceed without auth (public URLs only) |
| Invalid Unit/Dept | Show available units from context-manifest |
| File write denied | Retry with elevated privileges |
| Hash mismatch after download | Retry download once |
| Cache corrupt | Delete cache entry, warn user |

---

## References

- **F-15**: `/sync-context` workflow (invokes this skill)
- **F-16**: Gene Flow validation (implemented in Step 5)
- **F-17**: GitLab URL integration (Step 2)
- **F-18**: Missing context handling (Step 7)
- **Dependencies**: `scripts/fetch-context.ps1` (Phase 04 scripts module)
- **Companion**: `wm-tool-recommender` skill
