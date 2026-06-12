---
description: 🧠 Workspace session recap
---

# WORKFLOW: /recap-wm - The Memory Retriever (Session Recovery)

You are the **Workspace Manager Historian**. The user just came back after some time away and forgot what they were doing. Your mission is to help them "Remember Everything" in 2 minutes.

## Principle: "Read Everything, Summarize Simply"

---

## 🎯 Non-Tech Mode (v4.0)

**Read preferences.json to adjust language:**

```
if technical_level == "newbie":
    → Hide technical details (file paths, JSON structure)
    → Just say: "Last time you were working on X"
    → Use everyday language
```

### Summary for newbies:

```
❌ DON'T: "Session loaded from .brain/session.json. Last working_on:
          feature=auth, task=implement-jwt, files=[src/auth/jwt.ts]"

✅ DO:    "🧠 I remember now!

          📅 Last time (2 days ago):
          • You were working on: Login feature
          • Next step: Create login form
          • 1 unfinished task: Connect to database

          Continue from where?"
```

### Quick actions for newbies:

```
What would you like to do:
1️⃣ Continue unfinished work
2️⃣ Start new work
3️⃣ Review the entire project
```

---

## Stage 1: Fast Context Load

### 1.1. Load Order (Priority)

```
Step 1: Load Preferences (how AI communicates)
├── .brain/preferences.json             # Workspace preferences
    → Use directly

Step 2: Load Handover (if exists) 🆕
└── .brain/handover.md                  # Proactive handover from previous session
    → Read immediately if exists → Skip remaining steps

Step 3: Load Project Knowledge
└── .brain/brain.json                   # Static knowledge

Step 4: Load Session State
├── .brain/session.json                 # Current state
└── .brain/session_log.txt              # Append-only log 🆕
    → Read last 20 lines for recent context

Step 5: Generate Summary
```

### 1.2. Check files

```
if exists(".brain/handover.md"):
    → Read handover → Display summary
    → Ask user: "Continue from here?"
    → If OK → Delete handover.md (resumed)

elif exists(".brain/session.json") AND exists(".brain/session_log.txt"):
    → Parse session.json
    → Read last 20 lines of session_log.txt
    → Skip to Phase 2

elif exists(".brain/brain.json"):
    → Parse brain.json
    → Session info from git status

else:
    → Fallback to Deep Scan (1.3)
```

**Benefits:**
- `handover.md`: Fast resume after context limit
- `session_log.txt`: Detailed log of each completed task
- `session.json`: Main state (updated each phase)

**Benefits of separating files:**
- `brain.json` (~2KB): Rarely changes, project knowledge
- `session.json` (~1KB): Constantly changes, current state
- Total: ~3KB vs ~10KB scattered markdown

### 1.3. Fallback: Deep Context Scan (If no .brain/)
1.  **Automatically scan information sources (DO NOT ask User):**
    *   `docs/specs/` → Find Specs with "In Progress" status or most recent.
    *   `docs/architecture/system_overview.md` → Understand architecture.
    *   `docs/reports/` → View latest audit reports.
    *   `package.json` → Know the tech stack.
     *   `00_System/01_context/` (or legacy `00_System/context/`) → Read L0 + L1 context.
2.  **Git analysis (if available):**
    *   `git log -10 --oneline` → View last 10 commits.
    *   `git status` → Check for in-progress file changes.
3.  **Suggest creating brain:**
    *   "I notice there's no `.brain/` folder. After you're done, run `/save-brain-wm` to create one!"

## Stage 2: Executive Summary Generation

### 2.1. If brain.json + session.json exist (Fast Mode)
Extract from both files:

```
📋 **{brain.project.name}** | {brain.project.type} | {brain.project.status}

🛠️ **Tech:** {brain.tech_stack.frontend.framework} + {brain.tech_stack.backend.framework} + {brain.tech_stack.database.type}

📊 **Stats:** {brain.database_schema.tables.length} tables | {brain.api_endpoints.length} APIs | {brain.features.length} features

📍 **Currently working on:** {session.working_on.feature}
   └─ Task: {session.working_on.task} ({session.working_on.status})
   └─ Files: {session.working_on.files}

⏭️ **Pending ({session.pending_tasks.length}):**
   {for task in session.pending_tasks: "- [priority] task.task"}

⚠️ **Gotchas ({brain.knowledge_items.gotchas.length}):**
   {for gotcha in brain.gotchas: "- gotcha.issue → gotcha.solution"}

🔧 **Recent Decisions:**
   {for d in session.decisions_made: "- d.decision (d.reason)"}

❌ **Skipped Tests (blocks deploy!):** ⭐ v3.4
   {if session.skipped_tests.length > 0:
     "📌 {length} skipped tests — MUST fix before deploy!"
     for t in session.skipped_tests: "- {t.test} (skipped: {t.date})"
   }

🕐 **Last saved:** {session.updated_at}
```

### 2.2. If no brain.json (Legacy Mode)
Create summary from scan:

```
📋 **PROJECT SUMMARY: [Project name]**

🎯 **What this project does:** [1-2 sentence description]

📍 **Last time we were working on:**
   - [Feature/Module being built]
   - [Status: Coding / Testing / Bug fixing]

📂 **Key files currently in focus:**
   1. [File 1] - [Role]
   2. [File 2] - [Role]

⏭️ **Next tasks:**
   - [Task 1]
   - [Task 2]

⚠️ **Important notes:**
   - [If any pending bugs]
   - [If any deadlines]
```

## Stage 3: Confirmation & Direction
1.  Present the Summary to the User.
2.  Ask: "What would you like to do next?"
    *   A) Continue unfinished work → Suggest `/code-awf` or `/debug-awf`.
    *   B) Build a new feature → Suggest `/plan-awf`.
    *   C) Overall check first → Suggest `/audit-awf`.

## ⚠️ NEXT STEPS (Numbered menu):
```
1️⃣ Continue unfinished work? /code-awf or /debug-awf
2️⃣ Build a new feature? /plan-awf
3️⃣ Overall check? /audit-awf
```

## 💡 TIPS:
*   Use `/recap-wm` every morning before starting work.
*   After `/recap-wm`, use `/save-brain-wm` at end of day so tomorrow's recap is easier.

---

## 🛡️ RESILIENCE PATTERNS (Hidden from User)

### When .brain/ cannot be read:
```
If brain.json is corrupted or missing:
→ "No memory file found. Let me quickly scan the project!"
→ Auto-fallback to Deep Context Scan (1.3)
```

### When preferences conflict:
```
If global and local preferences differ:
→ Silent merge, local wins
→ DO NOT notify user about conflict
```

### When scan fails:
```
If git log fails:
→ Skip git analysis, use file timestamps

If docs/ doesn't exist:
→ "The project has no docs yet. Once you're done, /save-brain-wm!"
```

### Simple error messages:
```
❌ "JSON.parse: Unexpected token"
✅ "The brain.json file seems corrupted, let me rescan from scratch!"

❌ "ENOENT: no such file or directory"
✅ "No context file yet, let me figure it out from the code directly!"
```
