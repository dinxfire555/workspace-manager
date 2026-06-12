---
description: Create a new project workspace with local-only context
---

# Workflow: /new-workspace-local

Create a new project workspace when the project or its context does not exist on the company's GitLab context-hub. Useful for offline setups, new products not yet registered on the hub, or air-gapped environments.

---

## Preconditions

- `/init-wm` has been run at least once OR user is setting up context for the first time
- User knows their Role, Product name, and whether they share context with existing Unit/Department

---

## Pipeline

### Step 4a: Confirm Workspace Info

1. Check if user info (Role, Product) was already collected in the current session:
   - If YES → show summary, ask for confirmation
   - If NO → ask:
     - What **Product/Project** are you creating?
     - What is your **Role**?
     - Does this Product share the same **Unit and Department context** as existing `00_System/01_context/` (or legacy `00_System/context/`) files?

2. Based on context scope answer:
   - **Same context** (shares Unit/Dept) → skip to Step 4c (folder creation)
   - **Different context** (new Unit or Dept) → proceed to Step 4b

### Step 4b: Initialize Unit & Department Context

1. Ask user for their new **Unit** (e.g. "ai", "cloud") and **Department** (e.g. "genai-center").

2. Check if these Unit/Department match what's already in `00_System/01_context/` (or legacy `00_System/context/`):
   - If **already exists** → notify user. Ask:
     - "Context for this Unit/Department already exists. Do you want to use it, merge into it, or replace it?"
     - **Use existing** → skip to Step 4c
     - **Merge** → send template → user fills → call `wm-merge-context` skill → 4c
     - **Replace** → send template → user fills → overwrite → 4c

   - If **not on local but exists on context-hub**:
     - Ask: merge into existing local context or replace?
     - **Merge** → download from hub → call `wm-merge-context` → 4c
     - **Replace** → download from hub → overwrite → 4c

   - If **does not exist anywhere** → notify user. Ask:
     - Send template for Unit (`business-context.md`) and/or Department (`domain-context.md`)
     - User fills in content and submits
     - **Merge** into existing → call `wm-merge-context` → 4c
     - **Replace** existing → overwrite → 4c
     - **Keep existing** (use current context) → 4c

### Step 4c: Create Local Workspace (Automated)

> **Note**: Prefix `11_` indicates local-only workspace (vs `10_` for hub-synced).

**IMPORTANT**: This step is automated via `create-workspace.ps1`.

**Locate script** (search in order):
  1. `$env:USERPROFILE\.config\opencode\scripts\create-workspace.ps1`
  2. `$env:USERPROFILE\.claude\scripts\create-workspace.ps1`
  3. `$env:USERPROFILE\.codex\scripts\create-workspace.ps1`
  4. `$env:USERPROFILE\.gemini\config\scripts\create-workspace.ps1`
  On macOS/Linux: replace `$env:USERPROFILE` with `$HOME`

**Join roles** (if user has multiple roles):
  Join primary + secondary roles into comma-separated string: e.g. "PO, BA, Tester"

**Run script**:
```powershell
& "$scriptPath" -Role "$allRoles" -Product "$Product" -Prefix "11" -Unit "$Unit"
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
     - If `11_[Product]-wp/` exists → abort with message: "Workspace already exists. Use /sync-context to update instead."
  2. Create folder `11_[Product]-wp/`, `11_[Product]-wp/00_context/`, `11_[Product]-wp/00_temp/`
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
   Local workspace created: 11_[Product]-wp/
      ├── 00_context/project-context.md  (user-provided)
      ├── 00_temp/feature-context.md    (feature template)
      ├── [role folders...]
   ```

---

## Example: New Product, Same Department

```
User: Role = "PO", Product = "AI Mentor"
User: Shares context with existing Unit "ai", Dept "genai-center"
System: No project-context.md for "ai-mentor" on hub
System: Sending template... (user fills and submits)
System: Creating workspace...
✅ Local workspace created: 11_AI Mentor-wp/
   ├── 00_context/project-context.md
   ├── 01_docs/prd/
   ├── 01_docs/roadmap/
   └── 01_docs/backlog/
```

## Example: New Department, Merge Context

```
User: Role = "Dev FE", Product = "New Platform"
User: Different Unit/Dept from existing context
User: Unit = "cloud", Dept = "new-dept" (not on hub)
System: Sending business-context.md + domain-context.md templates...
System: User submitted content. Merging with existing...
System: Merge complete (wm-merge-context).
✅ Local workspace created: 11_New Platform-wp/
```

---

## Error Handling

| Error | Handling |
|-------|----------|
| No context files at all | Walk user through creating L0 + L1 from templates |
| Invalid Unit/Dept name | Ask user to verify spelling; show examples |
| User cancels mid-flow | Save partial state; offer to resume via `/recap-wm` |
| Folder creation fails | Show error with path; offer retry |
| Merge context fails | Show diff; ask user to manually resolve |

---

## Notes

- Folder prefix `11_` distinguishes local-only workspaces from hub-synced (`10_`).
- System sub-folders inside workspace: `00_context/` (L2 project context), `00_temp/` (feature template).
- Role sub-folders use numeric prefixes: `01_docs/`, `02_src/`, `03_tests/`, etc. See `role-folders.json` for full mapping.
- The numbering allows room for future workspace types (e.g. `12_` for team-shared).
- The `wm-merge-context` skill is called at 4+ decision points in this pipeline.
- If no GitLab access, templates are served from bundled files in the WM repo.
- Legacy workspaces without numeric sub-folder prefixes remain compatible (dual-path check).

---

**Next**: `/new-workspace` for hub-synced workspace creation.
