---
description: Create a new project workspace synced from context-hub
---

# Workflow: /new-workspace

Create a new project workspace by fetching project context (L2) from the company's GitLab context-hub and setting up role-based folder structure.

---

## Preconditions

- `/init-wm` has been run at least once (L0 + L1 context files exist in `00_System/01_context/` or legacy `00_System/context/`)
- `WM_GITLAB_TOKEN` environment variable is set for GitLab API access
- User knows their Role, Product name, Unit and Department

---

## Pipeline

### Step 3a: Detect User Context + List Existing Workspaces + Collect Product

1. Check if `.brain/user_info.json` exists:
   - If YES:
     - Load and display summary: "Current user: [Name], Role: [Role], Unit: [Unit], Department: [Dept]"
     - Note: DO NOT auto-use the Product from user_info. Proceed to workspace listing.
   - If NO (standalone mode):
     - Ask: "What is your Role in this project?" (show valid options: PO, PM, BA, Dev FE, Dev BE, Tester, SM, DevOps, Designer, Sales, Operations, Other)
     - Ask: "Do you have multiple roles? If yes, enter comma-separated (e.g. PO, BA)"

2. Scan root directory for existing workspace folders:
   - Pattern: `10_*-wp/` and `11_*-wp/`
   - Display all workspaces found:
     ```
     Existing workspaces:
     - 10_OmniSupport-wp/  (hub-synced)
     - 10_AI-Agent-wp/     (hub-synced)
     - 11_LocalProject-wp/ (local-only)
     No workspaces found.
     ```

3. Ask user: "Which Product would you like to create a workspace for?"
   - To suggest options: scan context-hub `context/{Unit}/{Dept}/` for existing products
   - If user_info has Unit/Dept: use those to scope the scan
   - If no Unit/Dept: ask user first, then scan
   - Display options from hub + "Enter a new Product name"
   - If user enters a new Product not on hub: warn "This Product does not exist on context-hub yet. A template will be provided."
   - If user enters blank: use Product from user_info.json (if available)

4. Validate L0 + L1 context exist (check in order):
   - `00_System/01_context/business-context.md` (v1.1+)
   - `00_System/context/business-context.md` (legacy v1.0)
   - Same logic for domain-context.md
   - If neither found → prompt user to run `/init-wm` first. Exit.

5. Check if workspace `{prefix}_{Product}-wp` already exists:
   - If YES:
     - Notify: "Workspace for [Product] already exists at [path]."
     - Offer options:
       - (A) Update project context via `/sync-context` for L2
       - (B) Enter a different Product name (loop back to step 3)
       - (C) Cancel
   - If NO: proceed to Step 3b.

### Step 3b: Verify context-hub Availability

1. Construct the context-hub URL from `.wm-env.json`:

 **URL resolution (fallback chain — first 200 wins):**
 ```
 Read context_hub from .wm-env.json.
 L2 fallback chain:
   [1] context/[Unit]/[Department]/[Product]/project-context.md
   [2] context/[Unit]/[Department]/[Product]_domain-context.md
   [3] context/[Unit]/project-context.md (block template)
 After download → redirect detection: if single .md filename → re-fetch.
 ```

 **Template routing by Unit:**
 | Unit | L2 template source |
 |------|----------------|
 | `ai` | `context/ai/[dept]/[product]_domain-context.md` |
 | `cloud` | `context/cloud/project-context.md` |
 | Other/new | `context/ai/project-context.md` (default) |

2. Attempt to fetch `project-context.md` from the context-hub:
 - If **found** confirm content length > 100 bytes. If valid use it.
 - If **not found** (404 or empty):
 - Notify user: "No project-context.md found on context-hub for [Product]."
 - Offer:
 - (A) Download template user fills in content submit back
 - (B) Proceed with empty project context (will be filled later)
 - (C) Cancel

3. **Unit/Department mismatch check**:
 - If the Product belongs to a **different Unit or Department** than what's in `00_System/01_context/` (or legacy `00_System/context/`):
 - Ask user: "This Product appears to be in a different Unit/Department. What would you like to do?"
 - (A) Keep current context (warn: context may be inaccurate)
 - User confirms keep proceed to Step 3c
 - User wants merge call `wm-merge-context` skill proceed to 3c
 - (B) Use new context
 - Merge new context? call `wm-merge-context` 3c
 - Replace context? delete old L0/L1, download new 3c
 - If Product is within the **same** Unit/Department proceed to Step 3c.

### Step 3c: Create Workspace (Automated)

**IMPORTANT**: This step is automated via `create-workspace.ps1`.

**Locate script** (search in order):
  1. `$env:USERPROFILE\.config\opencode\scripts\create-workspace.ps1`
  2. `$env:USERPROFILE\.claude\scripts\create-workspace.ps1`
  3. `$env:USERPROFILE\.codex\scripts\create-workspace.ps1`
  4. `$env:USERPROFILE\.gemini\config\scripts\create-workspace.ps1`
  On macOS/Linux: replace `$env:USERPROFILE` with `$HOME`

**Join roles** (if user has multiple roles):
  Read role from `.brain/user_info.json`.
  Normalize: convert "&", "/", "and" → comma, then split.
  Resolve each role individually, join as comma-separated: e.g. "PO, BA"

**Run script**:
```powershell
& "$scriptPath" -Role "$allRoles" -Product "$Product" -Prefix "10" -Unit "$Unit"
```

**Script handles automatically**:
  - Normalize all roles (alias map: "Dev" → "Dev BE", unknown → "Other")
  - Union unique folders from role-folders.json → create folders + .gitkeep
  - Create project-context.md placeholder (if not already present)
  - Download feature-context.md template (remote → local template → minimal fallback)
  - Report detailed results

**After script runs** — check result:
  - Exit code = 0 AND workspace folder exists → proceed to announcement
  - Exit code ≠ 0 OR workspace not found → use FALLBACK below

**FALLBACK (script not found or error)**:
  1. Check if workspace already exists BEFORE creating:
     - If `{prefix}_{Product}-wp/` exists → abort with message: "Workspace already exists. Use option (A) to update context instead."
  2. Create folder `{prefix}_{Product}-wp/`, `{prefix}_{Product}-wp/00_context/`, `{prefix}_{Product}-wp/00_temp/`
  3. Create `00_context/project-context.md` placeholder
  4. Find `role-folders.json` in (search order):
     - `~/.config/opencode/templates/role-folders.json`
     - `~/.claude/templates/role-folders.json`
     - `~/.codex/templates/role-folders.json`
     - `~/.gemini/config/templates/role-folders.json`
  5. Parse comma-separated roles → resolve each role → union unique folders → create + .gitkeep
  6. Download `feature-context.md` (remote context-hub → local template → placeholder)

After workspace is created (via script or fallback):
   ```
   Workspace created: 10_[Product]-wp/
   00_context/project-context.md
   00_temp/feature-context.md (feature template)
   [role folders...]
   ```

---

## Example

```
User: Role = "Dev BE", Product = "Omni Support"
System: L0 = Unit "ai", L1 = Department "genai-center"
System: Fetching context/ai/genai-center/omni-support/project-context.md...
System: Found! (2,341 bytes)
 System: Creating workspace...
  Workspace created: 10_Omni Support-wp/
  00_context/project-context.md
  00_temp/feature-context.md
  02_src/
 02_src/api/
 02_src/models/
 03_tests/
 03_tests/unit/
 01_docs/tech/
```

---

## Error Handling

| Error | Handling |
|-------|----------|
| Missing L0/L1 context | Prompt user to run `/init-wm` first |
| Workspace already exists | Offer update / create different / cancel |
| context-hub unreachable | Ask user: (A) fix URL in .wm-env.json (B) set token (C) use template (D) cancel |
| GitLab auth failure | Check `$env:WM_GITLAB_TOKEN`; guide user to set it |
| Invalid role | Ask user to pick from predefined list or describe manually |
| Folder creation fails | Show error with path; offer retry |

---

## Notes

- Folder prefix `10_` indicates hub-synced workspace.
- Workspace naming convention: `10_[Project]-wp` (e.g. `10_Omni Support-wp`).
- System sub-folders inside workspace: `00_context/` (L2 project context), `00_temp/` (feature template).
- Role sub-folders use numeric prefixes: `01_docs/`, `02_src/`, `03_tests/`, etc.
- The `wm-merge-context` skill is called when Unit/Department mismatch is detected during workspace creation.
- Legacy workspaces without numeric sub-folder prefixes remain compatible (dual-path check).

---

**Next**: `/new-workspace-local` for offline / air-gapped workspace creation.
