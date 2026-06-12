---
description: WM Folder & File Naming Convention
---

# WM Folder & File Naming Convention

## Overview
This skill defines naming conventions for folders and files in Workspace Manager projects. Apply these rules whenever creating folders or files autonomously.

---

## Naming Rules

### Folders (Numeric Prefix for Ordering)

- Use 2-digit numeric prefix: `00`, `10`, `20`, `30`... `90`, `99`
- Separator: underscore (`_`)
- Pattern: `{NN}_{Name}/`

| Prefix | Purpose | Example |
|--------|---------|---------|
| `00_` | System / meta | `00_System/` |
| `10_` | Hub-synced workspace | `10_OmniSupport-wp/` |
| `11_` | Local-only workspace | `11_SupportDesk-wp/` |
| `30_`+ | Additional workspaces | `30_QMS-wp/` |

**Workspace suffix:** Workspace folders should end with `-wp` to distinguish them from regular folders.

### Sub-folders (Numeric Prefix for Ordering)

Sub-folders inside `00_System/`, `10_*-wp/`, and `11_*-wp/` also use numeric prefix for ordering. The numbering restarts per parent scope.

**`00_System/` sub-folders:**

| Prefix | Folder | Purpose |
|--------|--------|---------|
| `01_` | `context/` | L0 + L1 context files |
| `02_`+ | `policy/`, `prompts/`, ... | System folders from context-hub |

**Workspace sub-folders (category-to-prefix mapping):**

| Prefix | Category | Used by roles |
|--------|----------|--------------|
| `00_` | `context`, `temp` | System folders inside workspace |
| `01_` | `docs` | PO, PM, BA, Dev, SM, Sales, Operations |
| `02_` | `src` | Dev FE, Dev BE |
| `03_` | `tests` | Tester, Dev FE, Dev BE |
| `04_` | `design` | Designer |
| `05_` | `deploy` | DevOps |
| `06_` | `metrics` | SM, Operations |
| `07_` | `test-plans` | Tester |
| `08_` | `test-cases` | Tester |
| `09_` | `test-reports` | Tester |
| `10_` | `bugs` | Tester |
| `11_` | `monitoring` | DevOps |
| `12_` | `ci` | DevOps |

### Files (ISO 8601 Date-Based)

- Format: `YYYY-MM-DD-description-vNN.ext`
- Version starts at `01`, increments each revision
- Pattern: `{Date}-{description}-v{version}.{ext}`

| Example | Meaning |
|---------|---------|
| `2026-06-08-sprint-review-v01.md` | Sprint review, version 1, created June 8 2026 |
| `2026-06-09-meeting-notes-v02.md` | Meeting notes, version 2, created June 9 2026 |
| `2026-06-08-report-v01.md` | Report, version 1 |

### User Override

- **If user specifies an exact name** → use it as-is without modification
- **Only apply rules** when generating names autonomously (no user input)
- Examples of user overrides:
  - User: "Create folder `src/`" → Create `src/` (not `10_src/`)
  - User: "Create file `README.md`" → Create `README.md` (not date-prefixed)

---

## Usage

### When Creating Folders

```
1. Is the folder user-requested with a specific name?
   → YES: Use the exact name given
   → NO: Check if there's an existing numeric sequence to continue

2. For autonomous folder creation:
    - System folders → 00_ prefix
    - Workspace folders → 10_ or 11_ prefix (hub-synced vs local)
    - Project sub-folders → match existing project prefix
    - Workspace system sub-folders → 00_ prefix (context, temp)

 3. Examples:
    - New workspace "MyApp" → 10_MyApp-wp/
    - Next workspace → 11_Another-wp/ (if 10_ taken)
    - Inside workspace, user says "create docs/" → docs/ (user override)
    - Workspace context folder → 00_context/ (autonomous)
    - Role docs folder → 01_docs/ (autonomous)
```

### When Creating Files

```
1. Is the file user-requested with a specific name?
   → YES: Use the exact name given
   → NO: Generate using ISO 8601 date format

2. For autonomous file creation:
   - Today's date + descriptive name + v01
   - If file already exists → increment version (v02, v03...)

3. Examples:
    - "Create a report" → 2026-06-09-report-v01.md
    - User: "Create TODO.md" → TODO.md (user override)
    - Second report same day → 2026-06-09-report-v02.md

---

## Legacy Path Compatibility

When reading existing folder structures, check both the new numbered path and the legacy unnumbered path:

```
1. Check 00_System/01_context/ first; if not found, try 00_System/context/
2. Check [workspace]/00_context/ first; if not found, try [workspace]/context/
3. Check [workspace]/01_docs/ first; if not found, try [workspace]/docs/
4. Check [workspace]/02_src/ first; if not found, try [workspace]/src/
5. Check [workspace]/03_tests/ first; if not found, try [workspace]/tests/
```

This ensures existing workspaces created before WM v1.1.0 remain functional. Do NOT automatically rename legacy folders.
```
