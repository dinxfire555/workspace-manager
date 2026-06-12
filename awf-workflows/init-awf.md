---
description: Initialize New Project
---
# WORKFLOW: /init-awf - Project Initialization

**Role:** Project Initializer
**Goal:** Capture the idea and create a basic workspace. Do NOT install packages, do NOT set up a database.

**LANGUAGE: Always respond in Vietnamese.**

---

## Flow Position

```
[/init-awf] ← YOU ARE HERE
   ↓
/brainstorm-awf (if the idea is not yet clear)
   ↓
/plan-awf (plan features)
   ↓
/design-awf (technical design)
   ↓
/code-awf (write code)
```

---

## Stage 1: Capture Vision (ASK BRIEFLY)

### 1.1. Project name

"What's the project name? (e.g.: my-coffee-app)"

### 1.2. One-line description

"Briefly describe what the app does? (1-2 sentences)"

### 1.3. Location

"Create in the current folder or somewhere else?"

**DONE. Ask nothing more.**

---

## Stage 2: Create Workspace (ONLY CREATE FOLDERS)

Only create the basic folder structure:

```
{project-name}/
├── .brain/
│   └── brain.json      # Project context (empty template)
├── docs/
│   └── ideas.md        # Record ideas
└── README.md           # Name + description
```

### brain.json template:

```json
{
  "project": {
    "name": "{project-name}",
    "description": "{description}",
    "created_at": "{timestamp}"
  },
  "tech_stack": [],
  "features": [],
  "decisions": []
}
```

### README.md template:

```markdown
# {Project Name}

{One-line description}

## Status: 🚧 Planning

The project is in the idea exploration phase.

## Next Steps

1. Type `/brainstorm-awf` to explore ideas
2. Or `/plan-awf` if you already know what you want to build
```

---

## Stage 3: Confirmation & Guidance

```
✅ Workspace created for "{project-name}"!

📁 Location: {path}

🚀 NEXT STEPS:

Choose one:

1️⃣ /brainstorm-awf - If you're not yet sure what to build and need to explore ideas
2️⃣ /plan-awf - If you already know what features you need

💡 Tip: Newbies should pick /brainstorm-awf first!
```

---

## IMPORTANT - DO NOT DO

❌ Do NOT install packages (leave for /code)
❌ Do NOT set up database (leave for /design)
❌ Do NOT create code files (leave for /code)
❌ Do NOT run npm/yarn/pnpm
❌ Do NOT ask about tech stack (AI will decide later)

---

## First-time User

If `.brain/preferences.json` does not exist:

```
👋 Welcome to AWF!

This is your first time. Would you like to:
1️⃣ Use defaults (Recommended)
2️⃣ Customize (/customize-awf)
```

---

## Error Handling

### Folder already exists:

```
⚠️ Folder "{name}" already exists.
1️⃣ Use this folder (may overwrite)
2️⃣ Pick a different name
```

### No permission to create folder:

```
❌ Couldn't create folder. Check your write permissions!
```
