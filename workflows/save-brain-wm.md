---
description: 💾 Save workspace knowledge
---

# WORKFLOW: /save-brain-wm - Workspace Memory Keeper v2.0

You are the **Workspace Manager Librarian**. Mission: Fight "Context Drift" — ensure AI never forgets.

**Principle:** "Code changes → Docs change IMMEDIATELY"

---

## ⚡ PROACTIVE HANDOVER 🆕

> **When context > 80% full, AUTO-create Handover Document**

### Proactive Handover Triggers:
- Context window > 80% (AI self-detects)
- Conversation length > 50 messages
- Before asking a complex question

### Handover Document Format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 HANDOVER DOCUMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Working on: [Feature name]
🔢 At step: Phase [X], Task [Y]

✅ DONE:
   - Phase 01: Setup ✓
   - Phase 02: Database ✓ (3/3 tasks)
   - Phase 03: Backend (2/5 tasks)

⏳ REMAINING:
   - Task 3.3: Create order API
   - Task 3.4: Payment integration
   - Phase 04, 05, 06

🔧 KEY DECISIONS:
   - Using Supabase (user wanted free tier)
   - Skipping dark mode (deferred to phase 2)
   - Prisma instead of raw SQL

⚠️ NOTES FOR NEXT SESSION:
   - File src/api/orders.ts is partially edited
   - API /payments not yet tested
   - SPECS-03 has special acceptance criteria

📁 KEY FILES:
   - docs/SPECS.md (main scope)
   - .brain/session.json (progress)
   - .brain/session_log.txt (details)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Saved! To continue: Type /recap-wm
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Actions after Proactive Handover:
1. Save handover to `.brain/handover.md`
2. Update session.json with current state
3. Notify user: "Context is nearly full, I've saved your progress. You can continue right away or type /recap-wm in a new session."

---

## 🎯 Non-Tech Mode (v4.0)

**Read preferences.json to adjust language:**

```
if technical_level == "newbie":
    → Hide JSON structure
    → Explain in terms of benefits: "Next time you come back, I'll remember everything!"
    → Only ask: "Save what I just learned about this project?"
```

### Explanation for non-tech users:

```
❌ DON'T: "Update brain.json with tech_stack and database_schema"
✅ DO:    "I'm remembering about your project:
          ✅ Technologies being used
          ✅ How data is stored
          ✅ APIs that have been created

          Next time you come back, I'll remember everything!"
```

### Simple questions:

```
❌ DON'T: "Update session.json or brain.json?"
✅ DO:    "What would you like me to remember:
          1️⃣ What you're working on today (to continue tomorrow)
          2️⃣ Overall project knowledge
          3️⃣ Both"
```

### Progress indicator:

```
🧠 Remembering...
   ✅ Technologies used
   ✅ Data structure
   ✅ API endpoints
   ✅ Current progress

💾 Saved! Next time type /recap-wm and I'll recall everything.
```

### Explaining database_schema to newbies:

```
When saving database structure, do NOT only save technical JSON:
{
  "tables": [{"name": "users", "columns": ["id", "email"]}]
}

INSTEAD, include everyday descriptions in brain.json:

"database_schema": {
  "summary": "The app stores: user info, orders, products",
  "tables": [...],
  "relationships_explained": "1 user has many orders, 1 order has many products"
}
```

### Explaining API endpoints to newbies:

```
Do NOT only save:
"api_endpoints": [{"method": "POST", "path": "/api/auth/login"}]

INSTEAD, include descriptions:
"api_endpoints": [
  {
    "path": "/api/auth/login",
    "explained": "Login — send email + password, receive a token back"
  }
]
```

---

## Stage 1: Change Analysis

### 1.1. Ask User
*   "What important changes did we make today?"
*   Or: "Should I auto-scan recently modified files?"

### 1.2. Auto-analyze
*   Check files changed during the session
*   Categorize:
    *   **Major:** New modules, DB changes → Update Architecture
    *   **Minor:** Bug fixes, refactors → Note in log only

---

## Stage 2: Documentation Update

### 2.1. System Architecture
*   File: `docs/architecture/system_overview.md`
*   Update if there are:
    *   New modules
    *   New third-party APIs
    *   Database changes

### 2.2. Database Schema
*   File: `docs/database/schema.md`
*   Update when there are:
    *   New tables
    *   New columns
    *   New relationships

### 2.3. API Documentation (⚠️ SDD Requirement) 🆕

#### 2.3.0. Ask User about API Docs

```
"📄 Would you like to create API documentation?

1️⃣ Markdown format (easy to read, easy to edit)
   → Creates docs/api/endpoints.md

2️⃣ OpenAPI/Swagger format (industry standard)
   → Creates docs/api/openapi.yaml
   → Can import into Postman, Swagger UI

3️⃣ Both (recommended for larger projects)

4️⃣ Skip (simple API, no docs needed)"
```

#### 2.3.1. Markdown API Docs

Scan all API routes in the project and create `docs/api/endpoints.md`:

```markdown
# API Documentation

Last updated: [Date]
Base URL: [https://api.example.com]

---

## 🔐 Authentication

### POST /api/auth/login
Log into the system

**Request:**
```json
{ "email": "user@example.com", "password": "xxx" }
```

**Response (200):**
```json
{ "token": "eyJ...", "user": { "id": 1, "email": "..." } }
```

**Errors:**
- 401: Wrong email or password
- 422: Missing email or password

---

## 👤 Users

### GET /api/users
Get user list (Admin permission required)

**Headers:** `Authorization: Bearer {token}`

**Query Parameters:**
| Param | Type | Default | Description |
|-------|------|---------|-------------|
| page | number | 1 | Current page |
| limit | number | 10 | Items/page |

**Response (200):**
```json
{ "users": [...], "total": 100, "page": 1 }
```
```

#### 2.3.2. OpenAPI/Swagger Format

Create `docs/api/openapi.yaml` in OpenAPI 3.0 standard:

```yaml
openapi: 3.0.0
info:
  title: [App Name] API
  version: 1.0.0
  description: API documentation for [App Name]

servers:
  - url: http://localhost:3000/api
    description: Development
  - url: https://api.example.com
    description: Production

paths:
  /auth/login:
    post:
      summary: Login
      tags: [Authentication]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                email: { type: string, format: email }
                password: { type: string, minLength: 6 }
      responses:
        '200':
          description: Login successful
        '401':
          description: Invalid credentials
```

#### 2.3.3. Sync API Docs

When new APIs are added, auto-append to existing docs files.

### 2.4. Business Logic Documentation
*   File: `docs/business/rules.md`
*   Save business rules:
    *   "Reward points expire after 1 year"
    *   "Orders over 500k get free shipping"
    *   "Admin can override prices"

### 2.5. Spec Status Update
*   Move Specs from `Draft` → `Implemented`
*   Update if there are changes from the original plan

### 2.6. Context Sync Check
*   Check if `00_System/01_context/` (or legacy `00_System/context/`) has changed
*   If L0 or L1 context changed → suggest `/sync-context`
*   If system folders changed → suggest `/sync-context`

---

## Stage 3: Codebase Documentation

### 3.1. README Update
*   Update setup instructions if new dependencies exist
*   Update new environment variables

### 3.2. Inline Documentation
*   Check if complex functions have JSDoc
*   Suggest adding comments if missing

### 3.3. Changelog (⚠️ Important for teams)
*   Create/update `CHANGELOG.md`:

```markdown
# Changelog

## [2026-01-15]
### Added
- Customer loyalty points feature
- API `/api/points/redeem`

### Changed
- Updated Dashboard UI

### Fixed
- Bug: confirmation emails not sending
```

---

## Stage 4: Knowledge Items Sync

### 4.1. Update KI if there is new knowledge
*   New patterns used
*   Gotchas/Bugs encountered and how to fix
*   Integration with third-party services

---

## Stage 5: Deployment Config Documentation

### 5.1. Environment Variables
*   Update `.env.example` with new variables
*   Document the meaning of each variable
*   Note: `WM_GITLAB_TOKEN` must not be committed

### 5.2. Infrastructure
*   Record server/hosting configuration
*   Record scheduled tasks

---

## Stage 6: Structured Context Generation ⭐ v3.3

> **Purpose:** Separate static knowledge from dynamic session so AI can parse faster

### 6.1. `.brain/` folder structure

```
.brain/                            # WORKSPACE-ROOT (per-project)
├── brain.json                     # 🧠 Static knowledge (rarely changes)
├── session.json                   # 📍 Dynamic session (constantly changes)
├── session_log.txt                # 📝 Append-only activity log
└── preferences.json               # ⚙️ Workspace-specific preferences
```

### 6.2. brain.json file (Static Knowledge)

Contains rarely-changing information:

```json
{
  "meta": { "schema_version": "1.1.0", "wm_version": "2.0.0" },
  "project": { "name": "...", "type": "...", "status": "..." },
  "tech_stack": { "frontend": {...}, "backend": {...}, "database": {...} },
  "database_schema": { "tables": [...], "relationships": [...] },
  "api_endpoints": [...],
  "business_rules": [...],
  "features": [...],
  "knowledge_items": { "patterns": [...], "gotchas": [...], "conventions": [...] }
}
```

### 6.3. session.json file (Dynamic Session) ⭐ NEW

Contains constantly-changing information:

```json
{
  "updated_at": "2026-01-17T18:30:00Z",
  "working_on": {
    "feature": "Revenue Reports",
    "task": "Implement daily revenue chart",
    "status": "coding",
    "files": ["src/features/reports/components/revenue-chart.tsx"],
    "blockers": [],
    "notes": "Using recharts"
  },
  "pending_tasks": [
    { "task": "Add date filter", "priority": "medium", "notes": "User request" }
  ],
  "recent_changes": [
    { "timestamp": "...", "type": "feature", "description": "...", "files": [...] }
  ],
  "errors_encountered": [
    { "error": "...", "solution": "...", "resolved": true }
  ],
  "decisions_made": [
    { "decision": "Use recharts", "reason": "Better React integration" }
  ]
}
```

### 6.4. Update rules

| Trigger | File to update |
|---------|----------------|
| New API added | `brain.json` → api_endpoints |
| DB change | `brain.json` → database_schema |
| Bug fix | `session.json` → errors_encountered |
| New dependency | `brain.json` → tech_stack |
| New feature | `brain.json` → features |
| Working on task | `session.json` → working_on |
| Task completed | `session.json` → pending_tasks, recent_changes |
| End of day | Both |

### 6.5. Create/update steps

**Step 1: Update brain.json (if project changes exist)**
- Scan `package.json` → tech_stack
- Scan `prisma/schema.prisma` → database_schema
- Scan `src/app/api/**` → api_endpoints
- Scan `docs/specs/*.md` → features

**Step 2: Update session.json (always update)**
- Modified files → recent_changes
- Current task → working_on
- Errors encountered → errors_encountered
- Decisions made → decisions_made

**Step 3: Validate**
- Schema: `schemas/brain.schema.json`, `schemas/session.schema.json`
- Ensure valid JSON before saving

**Step 4: Save**
- `.brain/brain.json` - add to `.gitignore` or commit if shared with team
- `.brain/session.json` - always in `.gitignore` (local state)

---

## Stage 7: Confirmation

1.  Report: "I've updated the memory. Files updated:"
    *   `docs/architecture/system_overview.md`
    *   `docs/api/endpoints.md`
    *   `.brain/brain.json` ⭐
    *   `CHANGELOG.md`
    *   ...
2.  "I've now saved this knowledge permanently."
3.  "You can safely shut down. Tomorrow just use `/recap-wm` and I'll remember everything."

### 7.1. Quick Stats
```
📊 Brain Stats:
- Tables: X | APIs: Y | Features: Z
- Pending tasks: N
- Last updated: [timestamp]
```

---

## ⚠️ NEXT STEPS (Numbered menu):
```
1️⃣ Done for the day? Time to rest!
2️⃣ Coming back tomorrow? /recap-wm to recall context
3️⃣ Want to keep going? /plan-awf or /code-awf
```

## 💡 BEST PRACTICES:
*   Run `/save-brain-wm` after each major feature
*   Run `/save-brain-wm` at end of each work day
*   Run `/save-brain-wm` before a long vacation

---

## 🛡️ RESILIENCE PATTERNS (Hidden from User)

### When file write fails:
```
1. Retry attempt 1 (wait 1s)
2. Retry attempt 2 (wait 2s)
3. Retry attempt 3 (wait 4s)
4. If still failing → Tell user:
   "Couldn't save the file 😅

   What would you like to do:
   1️⃣ Retry
   2️⃣ Save temporarily to clipboard
   3️⃣ Skip this file, save the rest"
```

### When JSON is invalid:
```
If brain.json/session.json is corrupted:
→ Create backup: brain.json.bak
→ Create new file from template
→ Tell user: "The old file was corrupted, I've created a new one and backed up the old"
```

### Simple error messages:
```
❌ "ENOENT: no such file or directory"
✅ "No .brain/ folder yet, let me create one!"

❌ "EACCES: permission denied"
✅ "No write permission. Can you check folder permissions?"
```
