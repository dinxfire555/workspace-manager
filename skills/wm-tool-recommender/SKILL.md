---
name: wm-tool-recommender
description: >-
 Recommend appropriate AI tools and skills from the FCI marketplace based on
 the user's role, project tech stack, and current workspace context.
 Supports role-based filtering, version comparison, and guided install.
 Keywords: tool, recommend, AI, role, marketplace, gitlab, skills, suggest, compare.
version: 2.0.0
---

# WM Tool Recommender (F-21, F-22, F-23)

Analyze project context, user role, and local tool inventory to recommend the best AI tools from the FCI Skills marketplace. Supports role-based filtering, version comparison, and guided installation workflow.

## Trigger Conditions

**Called from:** `/sync-tool` workflow (Phase 04)
**Called from:** `/init-wm` Step 6 (Phase 02 placeholder F-22 full logic in Phase 04)
**Post-hook for:** user role change, workspace creation

## Purpose

Help users discover and install the right AI tools for their specific role and project needs. The recommender considers:
- **User role** (Dev, PO, PM, BA, Tester, SM, Sales, Ops)
- **Project tech stack** (detected from workspace files)
- **Current tools** (already installed local skills)
- **Market offerings** (FCI Skills marketplace manifest)

## Execution Logic

### Step 1: Detect Context

```
Gather context factors:

1. USER ROLE (from highest priority):
 .brain/user_info.json role field
 preferences.json role field
 Command-line argument: -Role "Dev"
 Prompt: "Which role are you in today?"

2. WORKSPACE TECH STACK (auto-detect):
 Check for: package.json (Node), requirements.txt (Python),
 pom.xml (Java), go.mod (Go), *.csproj (C#)
 Check for: Dockerfile, docker-compose.yml
 Check for: .github/, .gitlab-ci.yml (CI/CD)
 Return detected stack tags: ["node","react","docker","python"]

3. INSTALLED TOOLS:
 Opencode: scan ~/.config/opencode/awf-skills/
 Claude: scan ~/.claude/skills/
 Return list of installed tool names + versions
```

### Step 2: Fetch Marketplace Data

```
Fetch from FCI Skills GitLab:
 URL: https://raw.githubusercontent.com/YOUR_ORG/fci-skills/main/.claude-plugin/marketplace.json
 Auth: $env:WM_GITLAB_TOKEN
 Parse: plugins[] {name, description, author, category, source}
 Cache: .brain/tool_cache/marketplace.json
 Return: [plugin objects]

Fallback on failure:
 Use cached marketplace.json
 Warn: "Using cached data from [date]"
 If no cache "Market unreachable. Try /sync-tool later."
```

### Step 3: Apply Filters

```
FILTER 1 Role-based (F-23):

 Role Recommended Tools

 Dev ctx-init, guideline-conv-ui,
 prototype-generator, task-adr,
 task-arch-proposal, cloud-mui-to-v2
 PO company-docsmith, prototype-generator
 PM company-docsmith, prototype-generator
 BA guideline-conv-ui, company-docsmith
 Tester (none specific)
 SM init-zhcc

FILTER 2 Tech Stack match:
 Node/Python/Java project prioritize dev tools
 Docker project recommend dev + ops tools
 Frontend (React) guideline-conv-ui
 Documentation company-docsmith

FILTER 3 Deduplication:
 Already installed skip (or flag for update)
 Already in queue skip
 Maintain priority order: role-match > stack-match > generic
```

### Step 4: Generate Comparison (F-22)

```
Output structured comparison:

CATEGORIES:
 RECOMMENDED FOR YOUR ROLE
 Tools matching role *and* not installed
 AVAILABLE (OTHER ROLES)
 Tools for other roles, or general-purpose
 NEEDS UPDATE
 Installed tools with newer version on market
 UP-TO-DATE
 Same version local and market
 LOCAL-ONLY
 Custom tools not in marketplace

For each tool entry:
 Name (with version if available)
 One-line description
 Category tag
 Install status: [Not installed] / [v1.2.3 v2.0.0]
```

### Step 5: Present Recommendations

```

 TOOL RECOMMENDATIONS FOR Dev


 RECOMMENDED (3):
 [1] ctx-init Bootstrap AI context
 [2] guideline-conv-ui AI Conversation UI guide
 [3] prototype-generator UI prototype generator

 OTHER (2):
 [4] company-docsmith Documentation builder
 [5] init-zhcc Zero Human Code Commit

 UPDATE (1):
 [6] wm-merge-context 1.0.0 2.0.0

 SYNCED (5): awf-adaptive-language, awf-auto-save, ...

 Enter numbers to install (e.g., 1,3,5) or A for all:

```

### Step 6: Execute Install

```
For each selected tool:
 DOWNLOAD:
 From GitLab raw source URL (marketplace.source)
 Tool metadata + skill files
 Save to temporary directory

 CONVERT (via convert engine):
 Detect target (Opencode, Claude Code, or both)
 Run appropriate converter script
 Register in config file

 VERIFY:
 Check SKILL.md exists in target directory
 Check config entry registered
 Report success/failure
```

### Step 7: Log and Report

```
Log to .brain/session_log.txt:
[timestamp] TOOL-RECOMMEND: installed=3, updated=1, skipped=1

Report:

 TOOL SYNC COMPLETE

 Installed: ctx-init, guideline-conv-ui, prototype
 Updated: wm-merge-context (2.0.0)
 Skipped: company-docsmith (not found in market)

```

---

## RoleTool Mapping Reference

See `templates/role-tools.json` for the full mapping definition.

```json
{
 "Dev": ["code", "test", "debug", "refactor", "review"],
 "PO": ["plan", "brainstorm"],
 "PM": ["plan", "design", "visualize"],
 "BA": ["brainstorm", "design"],
 "Tester": ["test"],
 "SM": ["plan", "next"]
}
```

Each role has:
- **`recommended_tools`**: Plugin names from the marketplace to install
- **`required_skills`**: AWF skills that should be active for this role
- **`optional_skills`**: Nice-to-have skills

---

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| role | string | No | auto-detect | Override role detection |
| target | string | No | "opencode" | Target platform (opencode/claude/both) |
| list-only | bool | No | false | Show recommendations without installing |
| auto-install | bool | No | false | Skip user prompt, install all recommended |
| refresh-cache | bool | No | false | Force re-fetch marketplace data |

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Marketplace unreachable | Use cache; disable install; show warning |
| Role unknown | Prompt user with list of valid roles |
| No recommendations for role | Show all available tools as generic list |
| Install fails for one tool | Skip, continue with remaining, report at end |
| Convert engine missing | "Install convert engine first via Phase 01 setup" |
| Token expired | "GitLab token invalid. Run /sync-tool to re-authenticate." |

---

## References

- **F-21**: `/sync-tool` workflow (invokes this skill)
- **F-22**: Skills comparison engine (scripts/compare-skills.ps1)
- **F-23**: Role-based tool recommendation (templates/role-tools.json)
- **F-24**: FCI Skills GitLab integration (scripts/fetch-tools.ps1)
- **F-25**: One-click tool install (convert engine)
- **Dependencies**: `scripts/fetch-tools.ps1`, `scripts/compare-skills.ps1`
- **Companion**: `wm-context-fetcher` skill
