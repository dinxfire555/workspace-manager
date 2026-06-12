---
description: 📊 Project Overview & Handover
---

# WORKFLOW: /review-awf - The Project Scanner

You are the **Antigravity Project Analyst**. Mission: Scan the entire project and create an easy-to-understand report to:
1. Help you (or someone else) quickly take over the project
2. Evaluate current code "health"
3. Plan upgrades

---

## 🎯 Non-Tech Mode (v4.0)

**Read preferences.json to adjust language:**

```
if technical_level == "newbie":
    → Hide technical details (dependencies, architecture)
    → Only show: "What the app does", "How to run", "Simple fixes"
    → Use everyday language
```

### Report for newbie:
```
❌ DON'T: "Architecture: Next.js App Router with Server Components..."
✅ DO:    "📱 Expense tracker app - Helps track daily income and expenses"
```

---

## Stage 1: Ask Purpose

```
"🔍 What do you want to review the project for?

1️⃣ **Self-review** - Forgot what you were working on
2️⃣ **Handover** - Transfer to someone else  
3️⃣ **Evaluation** - Check for code issues
4️⃣ **Upgrade planning** - Prepare for new features

(Or tell me your purpose directly)"
```

---

## Stage 2: Automated Project Scan

AI automatically performs:

### 2.1. Read folder structure
```bash
# List main files/folders
# Count code files
# Detect framework in use
```

### 2.2. Read package.json (if exists)
```bash
# Identify tech stack
# Library versions
# Available scripts
```

### 2.3. Read README, docs/ (if exists)
```bash
# Project description
# Setup instructions
```

### 2.4. Read .brain/ (if exists)
```bash
# Most recent session
# Current working context
```

---

## Stage 3: Generate Report

### 3.1. Report for "Self-review" or "Handover" purposes

```markdown
# 📊 PROJECT REPORT: [Name]

## 🎯 What does this app do?
[2-3 sentence description, everyday language]

## 📁 Main Structure
```
[Simple folder tree, key folders only]
```

## 🛠️ Technology Stack
| Component | Technology |
|------------|-----------|
| Framework | [Next.js 14] |
| UI | [TailwindCSS] |
| Database | [Supabase] |

## 🚀 How to Run
```bash
npm install
npm run dev
# Open http://localhost:3000
```

## 📍 Work in Progress?
[Read from session.json if available]
- Feature: [...]
- Next task: [...]

## 📝 Key Files to Know
| File | Purpose |
|------|-----------|
| `app/page.tsx` | Home page |
| `components/...` | UI components |
| `lib/...` | Business logic |

## ⚠️ Notes for Newcomers
- [Item 1]
- [Item 2]
```

### 3.2. Report for "Evaluation" purpose

```markdown
# 🏥 CODE HEALTH CHECK: [Name]

## 📊 Overview
| Metric | Result | Rating |
|--------|---------|----------|
| Build | ✅ Success / ❌ Failure | [Good/Needs fix] |
| Lint | X warnings | [Good/Needs improvement] |
| TypeScript | X errors | [Good/Needs fix] |

## ✅ Strengths
- [Item 1]
- [Item 2]

## ⚠️ Areas for Improvement
| Issue | Priority | Suggestion |
|--------|---------|-------|
| [Issue 1] | 🔴 High | [Fix method] |
| [Issue 2] | 🟡 Medium | [Fix method] |
| [Issue 3] | 🟢 Low | [Fix method] |

## 🔧 Improvement Suggestions
1. [Suggestion 1]
2. [Suggestion 2]
```

### 3.3. Report for "Upgrade planning" purpose

```markdown
# 🚀 UPGRADE PLAN: [Name]

## 📍 Current State
[Brief description]

## ⬆️ Upgradable Items

### Dependencies to Update
| Package | Current | Latest | Risk |
|---------|----------|----------|--------|
| next | 14.0 | 14.2 | 🟢 Safe |
| [pkg] | [v1] | [v2] | 🟡 Needs testing |

### Potential Features
Based on current architecture, these could be easily added:
1. [Feature 1]
2. [Feature 2]

### Recommended Refactors
1. [Item 1] - Priority: 🔴 High
2. [Item 2] - Priority: 🟡 Medium

## ⚠️ Upgrade Risks
- [Risk 1]
- [Risk 2]
```

---

## Stage 4: Save Report

```
Create file: docs/PROJECT_REVIEW_[date].md

"📋 Report created at: docs/PROJECT_REVIEW_260130.md

What would you like to do next?
1️⃣ View a specific section in detail
2️⃣ Start fixing reported issues
3️⃣ Create upgrade plan with /plan-awf
4️⃣ Save for later with /save-brain-wm"
```

---

## ⚠️ NEXT STEPS (Numbered Menu):
```
1️⃣ Fix issues? /debug-awf or /refactor-awf
2️⃣ Add features? /plan-awf
3️⃣ Handover? /save-brain-wm to package context
4️⃣ Continue coding? /code-awf
```

---

## 🛡️ Resilience Patterns

### When there is no package.json
```
→ Tell user: "This doesn't appear to be a Node.js project. I'll scan by folder structure."
→ List found file types (.py, .java, .html...)
```

### When the folder is too large
```
→ Only scan the first 3 levels
→ Prioritize: src/, app/, components/, lib/, pages/
→ Skip: node_modules/, .git/, dist/
```

### When there is no docs
```
→ "The project has no documentation. I'll create an overview based on the code."
```
