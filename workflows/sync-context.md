---
description: Sync context from GitLab Context Hub L0/L1/L2 with Gene Flow enforcement
---

# Workflow: /sync-context

Synchronize context files from the remote GitLab Context Hub, with L0L1L2 hierarchy enforcement and user-prompted recovery on auth/network failure.

## Overview

Keep workspace context up-to-date by fetching the latest versions from the centralized Context Hub repository. This workflow enforces the **4-Layer AI Context Architecture (L0-L3)** and validates Gene Flow compliance.

**Features**: F-15 (sync-context), F-16 (Gene Flow), F-17 (GitLab integration), F-18 (missing context handling)

---

## Pipeline

> ⚠️ This workflow is for STANDALONE use — when user types /sync-context directly.
> The /init-wm pipeline downloads context INLINE during Step 2c.
> Do NOT spawn this workflow as a sub-agent from /init-wm.

### Step 1: Ask Sync Target

```
Ask user: "Which context layer would you like to sync?"

1 L0 Business Context (enterprise-wide, immutable)
2 L1 Domain Context (unit/department rules)
3 L2 Project Context (project-specific, delta-only)
4 All layers (L0 + L1 + L2)

 If L2 ask: "Which Product?"

   - Scan root for workspace folders: `10_*-wp/`, `11_*-wp/` (both prefix types)
   - If exactly one workspace found → auto-detect Product from folder name
   - If multiple workspaces found → list them all:
     ```
     Available workspaces:
     1. OmniSupport  (10_OmniSupport-wp/)
     2. AI-Agent     (10_AI-Agent-wp/)
     Select the Product to sync context for:
     ```
   - If no workspace found → ask user to type Product name
   - Confirm with user: "Sync L2 context for Product [X]?"
 If workspace has no product detected prompt user to enter Product name
```

**Input**: User selection (1-4)
**Output**: `$syncTarget` variable (L0/L1/L2/all)

---

### Step 1b: Fetch Context Manifest

```
Fetch context/context-manifest.md from context-hub:
 - Use Get-ResourceUrl(source, "context/context-manifest.md")
 - Parse §1 tree → available blocks (ai, cloud)
 - Parse §3 mapping → block→domain→L0_path→L1_path registry
 - Cache to .brain/context_cache/context-manifest.md

If manifest is unreachable:
 - Fall back to directory scan (API listing)
 - Continue with fallback chains only
```

---

### Step 2: Fetch from Context Hub

```
Read .wm-env.json for context-hub configuration.
Use Get-ResourceUrl(source, subPath) helper:
  if source.type == "gitlab":
    return "{project_url}/-/raw/{branch}/{subPath}?private_token={token}"
  else:
    return "{raw_url}/{subPath}"

URL patterns (fallback chain — tried in order, first 200 wins):
 L0: [1] context/[Unit]/business-context.md
      [2] context/[Unit]/[Unit]_business-context.md
 L1: [1] context/[Unit]/[Department]/domain-context.md
      [2] context/[Unit]/[Department]/[Department]_business-context.md
 L2: [1] context/[Unit]/[Department]/[Product]/project-context.md
      [2] context/[Unit]/[Department]/[Product]_domain-context.md
      [3] context/[Unit]/project-context.md (block template)

After download → redirect detection: if content is a single .md filename,
rebuild URL with that filename and re-fetch (max 2 redirects).
```

**Template routing for Unit types (F-18):**
| Unit | Dept template | Product template |
|------|---------------|------------------|
| `ai` | `context/ai/[dept]/[dept]_business-context.md` | `context/ai/[dept]/[product]_domain-context.md` |
| `cloud` | `context/cloud/[dept]/domain-context.md` | `context/cloud/project-context.md` |
| *other* | Fallback to `context/ai/` templates | Fallback to `context/ai/` templates |

```
Auth: $env:WM_GITLAB_TOKEN (Bearer token or token query param)
Timeout: 10 seconds per request

For each level requested:
 URL = build_gitlab_url(level, unit, dept, product)
 Response = GET(url, auth)
 200 OK content = response body
 404 Not Found use template fallback (Step 2b)
 Timeout/Network error use offline cache (Step 2c)
 Store in $remoteContent[level]
```

**Input**: Unit, Department, Product from workspace config or user prompt
**Output**: `$remoteContent` map with fetched content

---

### Step 2b: Template Fallback (F-18)

When a context file is missing on the GitLab hub:

```
1. Check if a template exists locally (templates/feature-context.md)
   or use the template fallback URL from context-hub
 business-context.md (for L0)
 project-context.md (for L2 generic template)
 feature-context.md (for L3)

2. If template exists:
 Load template content
 Notify user: " [level] context not found on hub.
 Using template from local fallback."
 Use template as $remoteContent

3. If no template exists:
 Notify user: " [level] context not found on hub
 and no template available locally."
 Suggest: create context manually via /new-workspace or /new-workspace-local
 Skip this level, continue to next
```

**Missing context notification (F-18):**
```

 CONTEXT NOT FOUND


 Level: L2 Project Context
 Path: context/ai/genai-center/omni-support/

 This context does not exist on the GitLab hub yet.

 Options:
 1 Use template (get started with boilerplate)
 2 Create manually (via /new-workspace)
 3 Skip this level (continue without)


```

---

### Step 2c: Handle Unreachable Context Hub

When context-hub is unreachable:

```
1. Detect error type:
   - 401/403 → auth error
   - Timeout → network error
   - 404 → not found
   - DNS/other → network error

2. DO NOT automatically fall back to cache or skip.

3. Present options based on error type:

   Auth error (401/403):
   "🔐 Cannot access context-hub — authentication required.
    Options:
    (A) Set WM_GITLAB_TOKEN — provide your personal access token
    (B) Update context_hub URL in .wm-env.json → retry
    (C) Use offline cache from [date] (if available)
    (D) Cancel sync"

   Network error (timeout/DNS):
   "❌ Cannot reach context-hub. Check your network.
    Options:
    (A) Retry now
    (B) Update context_hub URL in .wm-env.json
    (C) Use offline cache from [date] (if available)
    (D) Cancel sync"

4. Only use cached version if user explicitly chooses option (C).
   If no cache available → note this and only show (A)(B)(D).
```

**Cache structure**: `.brain/context_cache/` with per-level subdirectories
**Cache invalidation**: Replaced on every successful online sync

---

### Step 3: Compare with Local Version

```
For each level requested:
 Local path (check in order):
 L0: 00_System/01_context/business-context.md
     (legacy: 00_System/context/business-context.md)
 L1: 00_System/01_context/domain-context.md
     (legacy: 00_System/context/domain-context.md)
 L2: [workspace]/00_context/project-context.md
     (legacy: [workspace]/context/project-context.md)

 Compare local vs remote (by content hash SHA256):
 Identical " L0: up-to-date" Skip
 Different Show diff summary:
 Lines added: X
 Lines removed: Y
 Sections changed: [list ## headers]
 Ask: "Update to latest version?"
 Yes Download (Step 4)
 No Skip, keep local version

 If local file doesn't exist:
 " L0: new file will be created"
 Auto-download (no comparison needed)
```

**Input**: Local filesystem + remote content
**Output**: Decision per level (update/skip/create)

---

### Step 4: Download & Overwrite Local Context (Gene Flow F-16)

```
For each level marked for update:

L0 Business Context (IMMUTABLE base):
 Target: 00_System/01_context/business-context.md (or legacy 00_System/context/business-context.md)
 IMPORTANT: L0 is IMMUTABLE never overwritten by L1/L2
 Only updated when user explicitly confirms:
 " L0 (Business Context) is the enterprise foundation.
 Are you sure you want to update it? [y/N]"
 On confirm Write file, preserve <!-- IMMUTABLE --> sections

L1 Domain Context:
 Target: 00_System/01_context/domain-context.md (or legacy 00_System/context/domain-context.md)
 Validate: Each section must reference L0 section IDs
 If Gene Flow validation fails warn user:
 " L1 sections missing L0 cross-references:
 - [section names]
 Continue anyway? [y/N]"
 On confirm Write file

L2 Project Context (delta-only):
 Target: [workspace]/00_context/project-context.md (or legacy [workspace]/context/project-context.md)
 Validate:
 Must trace compliance to L0 (business rules)
 Must list dependencies to L1 (domain rules)
 Must NOT repeat L0/L1 content (delta-only)
 If validation fails warn with specific gaps
 On confirm Write file
```

**Gene Flow validation rules (F-16):**
| Rule | Check | Action on failure |
|------|-------|-------------------|
| L0 is never overwritten by L1/L2 | Compare source level vs target | Block write, warn user |
| L2 traces compliance to L0 | Each L2 rule references L0 section | Warning with section names |
| L2 lists dependencies to L1 | Dependencies section references L1 | Warning with missing refs |
| Delta-only L2 | No content duplication from L0/L1 | Warning, suggest removal |
| Cross-references maintained | `[L0:xxx]` / `[L1:xxx]` markers | Warning with broken refs |

---

### Step 5: Update Cache

```
After successful download:
 Save to .brain/context_cache/:
 business-context.md
 domain-context.md
 project-context.md
 Save version metadata:
 .brain/context_cache/version.json
 { "last_sync": "ISO8601", "levels": ["L0","L1","L2"],
 "hashes": {"L0":"sha256...", ...} }
 Log to .brain/session_log.txt:
 [timestamp] SYNC: L0 (updated), L1 (up-to-date), L2 (new)
```

---

### Step 6: Report Sync Result

```

 SYNC CONTEXT COMPLETE


 Results:
 L0 (Business Context): Updated (3 sections new)
 L1 (Domain Context): Up-to-date
 L2 (Project Context): Created (new file)

 Offline mode: cache from 2026-06-05 (2 days old)

 Gene Flow: All validations passed

 Context files synced to 00_System/01_context/


```

---

## Script Integration

This workflow relies on these scripts (built alongside in Phase 04):

| Script | Purpose | Called in Step |
|--------|---------|----------------|
| `scripts/fetch-context.ps1` | Fetch context from GitLab raw URL | Step 2 |
| `scripts/fetch-tools.ps1` | Fetch tool list from fci-skills | Step 2 (indirect) |
| `scripts/compare-skills.ps1` | Compare local vs remote resources | Step 3 (tools variant) |

**Call examples**:
```powershell
# Fetch L0 business context
.\scripts\fetch-context.ps1 -Level "L0" -Unit "ai" -OutputPath "temp/business-context.md"

# Fetch L1 domain context
.\scripts\fetch-context.ps1 -Level "L1" -Unit "ai" -Department "genai-center" -OutputPath "temp/domain-context.md"

# Fetch L2 project context
.\scripts\fetch-context.ps1 -Level "L2" -Unit "ai" -Department "genai-center" -Product "omni-support" -OutputPath "temp/project-context.md"
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| GitLab timeout (10s) | Retry once; if fails ask user to fix URL, set token, or use cache |
| No network at all | Ask user: (A) retry (B) fix URL/token (C) use cache (D) cancel |
| GitLab auth error (401/403) | Guide user to set WM_GITLAB_TOKEN; offer cache fallback |
| 404 on all levels | Notify user, offer template creation guide |
| Invalid Unit/Department | Re-prompt user with available options from manifest |
| File write permission denied | Retry with admin prompt |
| SHA256 hash mismatch after download | Retry download once |
| Large diff (>50% lines changed) | Warn user: "Large update detected. Review recommended." |

## Gene Flow Violation Scenarios

| Violation | Detection | Response |
|-----------|-----------|----------|
| L1 references broken L0 section | Scan for `[L0:xxx]` markers, verify L0 has `## xxx` | Warn + list broken refs |
| L2 duplicates L0 content | Content similarity > 30% with L0 | Warn: "Consider removing duplicate content" |
| L2 has no L0 compliance section | Check for `## Compliance` or `## Alignment` header | Warn: "Missing L0 compliance section" |
| L1 L0 (orphan domain) | Domain name not listed in L0 business units | Soft warning: "Domain not listed in L0" |

---

## References

- **F-15**: `/sync-context` workflow (this file)
- **F-16**: L0-L1-L2 Gene Flow enforcement
- **F-17**: GitLab context-hub URL integration
- **F-18**: Missing context templates and notifications
- **ADR-3**: curl/Invoke-WebRequest with env var auth
- **Dependencies**: `scripts/fetch-context.ps1`, Phase 02 merge-context skill
- **Companion**: `/sync-tool` workflow (Phase 04)
