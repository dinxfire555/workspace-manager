---
description: Initialize Workspace Manager 7-step init pipeline with context layers
---

# Workflow: /init-wm Workspace Manager Initialization

Initialize the Workspace Manager system in the current project directory. This is the main entry point for new and returning users.

## Overview

The `/init-wm` pipeline walks through 9 steps (Step 0 through Step 8) to bootstrap a fully configured AI workspace:

0. **ENSURE ENV** Check/create .wm-env.json (v1→v2 migration)
1. **CHECK ROOT FOLDER** Detect existing context and workspaces
2. **COLLECT USER INFO** New or returning user flow (name, email, Unit, Dept, Role, Product)
3. **CHECK CONTEXT-HUB** Download L0 (business-context.md) + L1 (domain-context.md) + 4 system folders
4. **CREATE WORKSPACE** Call `/new-workspace` if needed (conditional)
5. **CREATE LOCALLY** Call `/new-workspace-local` if Unit/Dept/Product don't exist yet
 6. **SYNC TOOLS** Call `/sync-tool` to fetch, compare, and install tools (Phase 04)
 7. **UPDATE PERSONA** Create AGENTS.md or CLAUDE.md with greeting, context loading, Gene Flow rules, best practices
 8. **ONBOARDING SUMMARY** Show all actions performed, guide next steps

---

## Pipeline

### Step 0: ENSURE .wm-env.json (v1→v2 Migration)

```
Check if .wm-env.json exists in the project root:
 YES Validate JSON structure (version, context_hub, fci_skills, workspace_manager)
  Valid Continue to Step 1
  Invalid/corrupt Offer to recreate from defaults
 NO Detect if this is a v1 workspace (has 00_System/context/ but no .wm-env.json)
  V1 UPGRADE PATH:
  "Your workspace was created with WM v1 and needs an environment config."
  Ask user to provide:
  - Source type (github/gitlab) for context-hub, fci-skills, workspace-manager
  - Project URLs or use defaults
  - Branch (main or custom)
  - Unit + Department
  Create .wm-env.json from user input (or defaults if user accepts)
  NEW USER PATH (template-driven):

  1. Find template .wm-env.json from installed target:
     Search in order (replace $HOME with $env:USERPROFILE on Windows):
     - $HOME/.config/opencode/templates/.wm-env.json
     - $HOME/.claude/templates/.wm-env.json
     - $HOME/.codex/templates/.wm-env.json
     - $HOME/.gemini/config/templates/.wm-env.json
     If no template found → ask user for all config (type github/gitlab + URLs + Unit/Dept)

  2. Copy template → project root as .wm-env.json

     IMPORTANT: After copying, work exclusively with the COPY at project root.
     NEVER modify the source template file.

  3. Validate each env — MANDATORY URL CHECK (context_hub, fci_skills, workspace_manager):
     
     Test-fetch EACH URL by running ACTUAL HTTP commands:
     
     context_hub:    Invoke-WebRequest "<url>/VERSION" -UseBasicParsing -TimeoutSec 10
     fci_skills:     Invoke-WebRequest "<url>/.claude-plugin/marketplace.json" -UseBasicParsing -TimeoutSec 10
     workspace_mgr:  Invoke-WebRequest "<url>/VERSION" -UseBasicParsing -TimeoutSec 10
     (Bash: curl -s -o /dev/null -w "%{http_code}" "<url>")
     
     Show ACTUAL HTTP status BEFORE asking user:
     - 200 → ✅ reachable
     - 401/403 → ❌ authentication required
     - timeout → ❌ unreachable
     
     For each env:
     - OK (HTTP 200) → ✅ Mark as validated
     - Auth required (401/403) → ❌ STOP. Show:
       "🔐 [env_name] requires authentication at [URL].
        Options:
        (A) Set WM_GITLAB_TOKEN — I'll guide you to create a personal access token
        (B) Change repository type from gitlab ↔ github
        (C) Enter a new URL
        (D) Skip validation — WARNING: sync-context/sync-tool will fail later"
     - Timeout / 404 / DNS error → ❌ STOP. Show:
       "❌ [env_name] is unreachable at [URL].
        Options:
        (A) Enter a new URL
        (B) Change repository type (github/gitlab)
        (C) Skip validation — WARNING: sync will fail later"
     
     🚫 CRITICAL: DO NOT proceed to Step 1 until ALL URLs pass validation
        OR user explicitly confirms skip (option D/C) for EACH failed URL.
     
     Display validation summary before continuing.

  4. Ask Unit + Department (stored once, used by all workflows):
     - Unit (e.g. "ai", "cloud")
      - Department (e.g. "genai-center")
    
    After user provides Unit and Department, normalize BEFORE saving:
      - Convert to lowercase
      - Replace spaces with hyphens
      - Strip special characters
      - Examples: "AI" → "ai", "Gen AI" → "gen-ai"
      - Confirm with user: "Saving Unit='ai', Department='gen-ai'. OK?"
      - Only write to .wm-env.json after user confirms
  
  > ⚠️ IMPORTANT: DO NOT add name, email, or role fields to .wm-env.json.
  > Identity (name, email, role) is saved ONLY in Step 2a → .brain/user_info.json.
  > .wm-env.json contains ONLY: version, context_hub, fci_skills, workspace_manager, unit, department.

  5. Save finalized .wm-env.json with all confirmed values

  6. Proceed to Step 1 (CHECK ROOT FOLDER)
  
  > 🚫 CRITICAL — DO NOT STOP HERE. The pipeline has 9 steps (0-8).
  > Immediately continue to Step 1 (CHECK ROOT FOLDER). All steps must execute sequentially.
  
  > ✅ CHECKPOINT — verify you have completed:
  > ☐ Test-fetched ALL 3 URLs, shown HTTP results to user
  > ☐ Collected + normalized Unit and Department
  > ☐ Saved .wm-env.json with validated values (NO identity fields)
  > ☐ Not added name/email/role to .wm-env.json
  > If any ☐ is unchecked → STOP, complete it, then proceed to Step 1.
```

**Input**: Filesystem scan for .wm-env.json
**Output**: .wm-env.json at project root

### Step 1: CHECK ROOT FOLDER

```
Check for existing WM structure in the current directory:
 Does 00_System/01_context/ exist? (or legacy 00_System/context/)
 Does business-context.md + domain-context.md exist? (in either path)
 YES Check for existing workspace folders
 Pattern: 10_*-wp/, 11_*-wp/

 Workspaces found:
   - List all existing workspaces to user
   - Display user_info summary if .brain/user_info.json exists
   - Ask: "What Product would you like to create a new workspace for?"
   - Collect: Role + Product (quick, minimal)
   - Save/update .brain/user_info.json
   - Call /new-workspace with collected Product + Role
   - After /new-workspace completes → go to Step 7 (onboarding)

 No workspaces found → Go to Step 2b (returning user)
 NO (no existing WM structure) → Go to Step 2a (new user)
```

**Input**: Filesystem scan of current directory
**Output**: Branching decision (new user / returning user / existing workspace)

---

### Step 2a: COLLECT USER INFO (New User)

**IMPORTANT**: Scan context-hub FIRST to present only real options. Never suggest made-up Unit, Department, or Product names.

```
1. Scan context-hub for available Units:
   PRIME: Fetch context/context-manifest.md → parse §1 tree for block names
   FALLBACK: Build API URL from .wm-env.json context_hub config:
     - GitHub: https://api.github.com/repos/{owner}/{repo}/contents/context/
     - GitLab: {base_url}/api/v4/projects/{project_id}/repository/tree?path=context&per_page=50
   - Parse response → extract directory names under context/
   - Example: ["ai", "cloud"]
   - Display: "Available Units: ai, cloud. Select one or enter a new Unit name."
   - If API fails → fall back to asking user to type freely; warn "Unable to verify against context-hub."

2. After Unit selected → scan for Departments:
   - URL: context/{Unit}/ (e.g. context/ai/)
   - Parse → extract directory names
   - Display: "Departments in '{Unit}': genai-center. Select one or enter a new Department name."

3. After Department selected → scan for Products:
   PRIME: List subdirectories in context/{Unit}/{Dept}/
   IF no subdirectories found:
     - List files matching *_domain-context.md
     - Exclude: domain-context.md (exact name, general L1)
               {Dept}_business-context.md (L1 center context, not product)
     - Extract product name = filename minus _domain-context.md suffix
   - Display: "Products in '{Unit}/{Dept}': [list]. Select one or enter a new Product name."

4. Collect remaining user info:
   - Full Name (required, 2-100 chars)
   - Email (required, valid email format)
    - Role (valid: PO, PM, BA, Dev FE, Dev BE, Tester, SM, DevOps, Designer, Sales, Operations, Other)
    - Product (e.g. "Omni Support")
  
  > ⚠️ Role normalization:
  > - Accept any format from user, then normalize:
  > - Convert "&", "/", "and" → comma
  > - Split by comma, resolve each role individually
  > - Save as comma-separated: e.g. "PO, BA"

5. Save all to .brain/user_info.json
6. Go to Step 2c
```

**Multiple roles handling**: If user says "I have multiple roles", ask for primary role first, note secondary roles in `user_info.secondary_roles`.

**Input**: User answers to 6 questions
**Output**: `user_info.json` saved to `.brain/user_info.json`

---

### Step 2b: COLLECT USER INFO (Returning User)

```
1. If context-hub is reachable, scan for available Products:
   - URL: context/{existing_Unit}/{existing_Dept}/
   - Display: "Products in your Unit/Dept: omni-support, ai-agent. Select one or enter a new Product name."

2. Ask for minimal info:

 Field Validation

 Role Required (valid: PO, PM, BA, Dev FE, Dev BE, Tester, SM, DevOps, Designer, Sales, Operations, Other)
 Product Required (from scan or user input)

Then CHECK: Is Product within the existing Unit/Dept context?

 YES (same context) Go to Step 2c

 NO (different Unit/Dept) Ask: "Have you moved to a different Unit/Department?"

 Option A: Keep current context (warn about mismatch)
 User confirms keep Go to Step 2c
 User wants merge Call merge-context skill Go to Step 2c

 Option B: Change context
 Merge new context? Call merge-context skill Go to Step 2c
 Replace context? Delete old context, download new Go to Step 2c
```

**Input**: Role + Product from user, existing context files
**Output**: Updated or preserved context, branch decision

---

### Step 2c: CHECK CONTEXT-HUB + SYSTEM FOLDERS

> 🚫 CRITICAL: Download context files DIRECTLY within this step.
> Do NOT spawn /sync-context as a sub-agent or background task.
> /sync-context is a STANDALONE workflow for manual use later.
> All downloads in this step must be done INLINE.

```
Read .wm-env.json for context-hub configuration.
Build URLs using Get-ResourceUrl helper:
  function Get-ResourceUrl(source, subPath):
    if source.type == "gitlab":
      return "{project_url}/-/raw/{branch}/{subPath}?private_token={token}"
    else:
      return "{raw_url}/{subPath}"

Check these paths exist on context-hub (fallback chain — first 200 wins):
 L0: [1] context/[Unit]/business-context.md
      [2] context/[Unit]/[Unit]_business-context.md
 L1: [1] context/[Unit]/[Dept]/domain-context.md
      [2] context/[Unit]/[Dept]/[Dept]_business-context.md
 L2: [1] context/[Unit]/[Dept]/[Product]/project-context.md
      [2] context/[Unit]/[Dept]/[Product]_domain-context.md
      [3] context/[Unit]/project-context.md (block template)

Template routing based on Unit:
 Unit   L0 template                          L1 template                              L2 template
 ai     context/ai/FPT.AI_business-context.md context/ai/[dept]/[dept]_business-context.md context/ai/[dept]/[product]_domain-context.md
 cloud  context/cloud/business-context.md     context/cloud/[dept]/domain-context.md   context/cloud/project-context.md
 other  Fallback to ai/                      Fallback to ai/                          Fallback to ai/

REDIRECT DETECTION: After downloading any context file, check if content is a single
 .md filename (e.g. "FPT.AI_business-context.md"). If so, rebuild URL using the target
 filename in the same directory and re-fetch (max 2 redirects).

Scenarios:
 ALL FOUND Confirm with user Download L0 + L1 Process System Folders (below) Go to Step 3
 Folder exists but no file Download template from WM repo Process System Folders Go to Step 3
 Folder doesn't exist Ask: "Create new context structure?"
 Yes Go to Step 4 (create locally)
 No Ask user to re-enter info or cancel

SYSTEM FOLDERS — Dynamic scan from context-hub root:

1. List all directories at the root of the context-hub repository:
   - GitHub API: GET https://api.github.com/repos/{owner}/{repo}/contents/
   - GitLab API: GET {base}/api/v4/projects/{id}/repository/tree?path=&per_page=100
   - Filter: type == "dir" (GitHub) or type == "tree" (GitLab)

2. EXCLUDE these directories:
   - context — already handled separately for L0/L1/L2 context
   - archives — explicitly excluded per user requirement
   - .git or any hidden directory

3. Assign numeric prefix to each remaining directory:
   - 01_ is reserved for context (always created by L0/L1 download)
   - Sort remaining directories alphabetically
   - Assign 02_, 03_, 04_... in order
   - Target path: 00_System/{NN}_{folder-name}/

4. For each directory, download all files:
   - Fetch file listing from API
   - Download each file individually using raw URL
   - Write to 00_System/{NN}_{folder-name}/{filename}
    - If directory is empty on hub → create .gitkeep
  
  > After creating SYSTEM FOLDERS, verify with ls:
  >   ls 00_System/
  > Expected: 01_context/  02_policies/  03_prompts/  04_standards/  05_tool-configs/
  > If any folder is missing → create it now with .gitkeep.
  > .gitkeep folders are normal (no content yet, will sync later).

5. If API is unreachable (auth error / timeout / network):
   
   🚫 DO NOT silently fall back to cache, templates, or skip.
   
   Instead, STOP and present options based on error type:
   
   Auth error (401/403):
   "🔐 context-hub requires authentication.
    Your WM_GITLAB_TOKEN may be missing, invalid, or expired.
    Options:
    (A) Set $env:WM_GITLAB_TOKEN — run: $env:WM_GITLAB_TOKEN = 'glpat-xxxxxxxxxxxx'
    (B) Update context_hub URL in .wm-env.json → re-validate
    (C) Update repository type (gitlab/github) in .wm-env.json
    (D) Continue offline with local templates (NOT recommended: you will miss real org context)
    (E) Skip context-hub entirely (NOT recommended: no L0/L1 context)"
   
   Timeout / network error:
   "❌ Cannot reach context-hub at [URL].
    Check your network connection.
    Options:
    (A) Retry
    (B) Update context_hub URL in .wm-env.json
    (C) Continue offline with local templates
    (D) Skip context-hub setup"
   
   Only proceed after user explicitly chooses an option.
   If user chooses (D)/(E), create empty context files with placeholder content.

> ⚠️ CRITICAL: Save content EXACTLY as downloaded — byte-for-byte.
> Do NOT translate, summarize, paraphrase, or modify content in any way.
> Preserve original language, formatting, encoding, and line endings.

Context files are stored in 00_System/01_context/:
  - business-context.md (L0)
  - domain-context.md (L1)
  - Do NOT place project-context.md here (L2 lives in workspace/00_context/)
  
  > ⚠️ ONLY download these 2 files for L0/L1 context:
  > 1. business-context.md (L0)
  > 2. domain-context.md (L1)
  > Do NOT download README.md, context-manifest.md, or any other files.
  > If an extra file appears → delete it immediately.
```

**Input**: Unit, Department, Product from Step 2a/2b, .wm-env.json
**Output**: `00_System/01_context/business-context.md` + `00_System/01_context/domain-context.md` + dynamic system folders

---

### Step 3: CREATE WORKSPACE (Always)

> 🚫 Do NOT spawn /new-workspace as a sub-agent. Execute INLINE.
> You MUST run create-workspace.ps1 directly — do NOT create folders manually.

IMPORTANT: If user has provided a Product name → ALWAYS create workspace:

1. Read role from `.brain/user_info.json` (saved in Step 2a).
   If user has multiple roles: join primary + secondary_roles as comma-separated.

2. Check: workspace `10_[Product]-wp/` already exists?
   - YES → Ask user:
     "(A) Update context – call /sync-context for L2"
     "(B) Create workspace with different prefix (10.1_, 10.2_)"
    - NO → Run create-workspace.ps1 INLINE:
      Locate script: ~/.config/opencode/scripts/create-workspace.ps1 (or ~/.claude/scripts/, etc.)
      PowerShell: & "<scriptPath>" -Role "$userRole" -Product "$Product" -Prefix "10"
      Result: 10_[Product]-wp/ + role folders + 00_temp/feature-context.md

3. After workspace created, verify:
   ☐ 10_[Product]-wp/ exists
   ☐ 00_context/project-context.md exists
   ☐ 00_temp/feature-context.md exists (REQUIRED template for feature context)
   ☐ Role sub-folders match templates/role-folders.json for user's roles
   If any ☐ is missing → fix it now. Then proceed to Step 5.

**Input**: Product name, existing workspace list
**Output**: New workspace folder `10_[Product]-wp/` (or skipped)

---

### Step 4: CREATE LOCAL STRUCTURE (If Needed)

Only triggered when the Unit/Department/Product path doesn't exist in the context-hub.

```
  Call /new-workspace-local workflow (F-11, built in Phase 03)
  Create local context structure:
  00_System/01_context/
  business-context.md # L0 from template
  domain-context.md # L1 from template
```

**Input**: Unit, Department, Product
**Output**: Local context files created from templates

---

### Step 5: SYNC TOOLS

> **Note**: This step calls `/sync-tool` workflow (built in Phase 04).

```
Call /sync-tool workflow:
 1. Detect locally installed AI tools (Opencode, Claude Code)
 2. Fetch marketplace manifest from FCI Skills GitLab
 3. Compare local vs remote (scripts/compare-skills.ps1)
 4. Filter by user role (templates/role-tools.json)
 5. Display recommendations
 6. Ask user: install recommended tools?
 7. For each selected tool download convert install
 8. Report results
```

**Input**: User info (role) from Step 2
**Output**: Installed tools, sync log entry

---

### Step 6: UPDATE PERSONA — Call /update-persona

```
Detect user's CLI/IDE target (path-based, Opencode first):
  ~/.config/opencode/  → AGENTS.md
  ~/.codex/            → AGENTS.md
  ~/.gemini/config/    → GEMINI.md
  ~/.claude/           → CLAUDE.md
  None detected        → Ask user to choose

1. Check if AGENTS.md or CLAUDE.md already exists at root:
   - If exists:
     a. Read and summarize current persona content
     b. Ask user: "Would you like to update your persona?"
        - Yes Ask what to update collect changes apply
        - No  Skip to Step 7
   - If not exists:
     a. Ask greeting preference:
        "How would you like me to address you?"
        Options: sep (boss), anh/chi (sir/maam), ban (friend),
                 [custom] user types their preference
       b. Read existing context files (read raw, do NOT translate content):
         - L0: 00_System/01_context/business-context.md (or legacy 00_System/context/business-context.md)
         - L1: 00_System/01_context/domain-context.md (or legacy 00_System/context/domain-context.md)
      c. Generate persona file using template:
         Content structure:
         - Greeting line (from step a)
         - Context loading instructions:
           "When starting a session, read:
            1. 00_System/01_context/business-context.md (L0)
            2. 00_System/01_context/domain-context.md (L1)
            3. [workspace]/00_context/project-context.md (L2)"
        - Gene Flow rules:
          "L0 is IMMUTABLE never override
           L1 must not conflict with L0
           L2 adds delta context only"
        - Best practices (humanlayer.dev):
          "Start each session by re-reading L0 + L1
           Explicitly confirm assumptions
           Use workspace folder structure for project files
           Refer to Gene Flow rules when resolving conflicts
           Cite context sections when answering
           Ask for clarification when rules conflict
           Save important decisions using /save-brain-wm"
     d. Write file to root folder as AGENTS.md or CLAUDE.md

2. Announce result:
   "Persona created/updated: [AGENTS.md / CLAUDE.md]"
```

**Input**: User greeting preference, existing context files (L0, L1)
**Output**: AGENTS.md or CLAUDE.md at project root

**Reference files**:
  - Templates: `templates/AGENTS.md.template`, `templates/CLAUDE.md.template`
  - Workflow: `workflows/update-persona.md`

---

### Step 7: ONBOARDING SUMMARY (F-51)

```
 
 WORKSPACE MANAGER INITIALIZATION COMPLETE
 
 
 User Info: [Name] [Role] @ [Dept]
 Environment: .wm-env.json configured (v2)
  Context: L0 + L1 files created in 00_System/01_context/
 System Folders: policy/ prompts/ standards/ tool-configs/
 Workspace: [Created / Skipped reason]
 Context Hub: [Downloaded / Fallback / Created locally]
 Persona: [AGENTS.md / CLAUDE.md] created at root
 
 
 Your workspace is ready: [path]
 
 
 
 NEXT STEPS:
 
 1 Save your session: /save-brain-wm
 2 Sync AWF workflows: /sync-awf
 3 Sync team tools: /sync-tool
 4 Recall later: /recap-wm
 5 Need help? /help-wm
 6 Start coding: /code
 
 
 
 SYSTEM READY Workspace Manager v2 is fully initialized!
 
```

**Input**: Results from all previous steps
**Output**: Summary displayed to user

---

## Error Handling

| Step | Error | Action |
|------|-------|--------|
| 1 | Cannot read directory | Retry with admin privileges |
| 2a | Invalid email | Re-prompt with format hint |
| 2c | GitLab timeout / auth error | Ask user: (A) retry (B) update URL in .wm-env.json (C) set token (D) skip |
| 2c | No network | Ask user: (A) retry (B) continue offline with local templates (C) cancel setup |
| 2c | 401/403 auth required | Guide user to create + set WM_GITLAB_TOKEN; offer to update URL or skip |
| 3 | /new-workspace fails | Retry 2 times → report detailed error → ask user: (A) retry (B) create manually (C) skip |
| 7 | Display failure | Fallback to plain text summary |

## Cancellation Handling

User can cancel at any step by typing `cancel` or pressing `Ctrl+C`:
- Progress made so far is saved to `.brain/session_log.txt`
- User can resume later with `/recap-wm`

---

## References

- **F-06**: Main init pipeline (this workflow)
- **F-07**: User info collection (Step 2a/2b)
- **F-08**: Context folder creation (Step 2c)
- **F-09**: Context template download (Step 2c)
- **F-51**: Onboarding summary (Step 7)
- **F-27**: Persona update (Step 6)
- **F-28**: Persona template engine (Step 6)
- **F-29**: Context auto-load instruction (Step 6)
- **F-30**: Custom greeting setup (Step 6)
- **F-20**: Merge context skill (called from Step 2b)
- **Dependencies**: Phase 03 (`/new-workspace`, `/new-workspace-local`), Phase 04 (`/sync-tool`), Phase 05 (`/update-persona`)
