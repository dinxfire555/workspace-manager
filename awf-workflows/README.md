# 🚀 Antigravity Workflow Framework (AWF) v2.0

**A COMPREHENSIVE Workflow System for all skill levels** — From newbie to pro, AI handles it all.

> 💡 **AWF 2.0 Philosophy:**
> - AI PROPOSES, You APPROVE (Smart Proposal)
> - Each workflow has its own PERSONA (PM, Developer, Designer, Detective...)
> - NEVER lose context (Lazy Checkpoint + Proactive Handover)

---

## 📋 Command List (17 Workflows)

### 🌟 Startup & Context
| Command | Description | Blind spots handled |
|---------|-------------|---------------------|
| `/init-awf` | Create a complete new project | Env vars, Git, Code quality tools |
| `/recap-wm` | Summarize context on return | Context recovery |
| `/save-brain-wm` | Save knowledge at end of session | API Docs, Changelog, Business rules |

### 🎯 Feature Development
| Command | Description | Blind spots handled |
|---------|-------------|---------------------|
| `/plan-awf` | Design features (Smart Proposal) | Auth, DB, Charts, Scheduled Tasks |
| `/design-awf` | **Detailed design** ⭐ NEW | Database, Workflow, Acceptance Criteria |
| `/visualize-awf` | Beautiful UI/UX design | Loading/Error states, Accessibility |
| `/code-awf` | Write quality code | Security, Validation, Error handling |

### ⚙️ Operations
| Command | Description | Blind spots handled |
|---------|-------------|---------------------|
| `/run-awf` | Start the app | Environment detection, Port conflicts |
| `/test-awf` | Test logic | Auto-generate tests if missing |
| `/deploy-awf` | Ship to production | SEO, Analytics, Legal, Backup, Monitoring |

### 🔧 Maintenance
| Command | Description | Blind spots handled |
|---------|-------------|---------------------|
| `/debug-awf` | Fix bugs (Investigation Protocol) | Hypothesis + 3 max retries |
| `/refactor-awf` | Clean up code | Safe execution, Before/After comparison |
| `/audit-awf` | Health check | Security, Performance, Dependencies |
| `/rollback-awf` | Roll back to previous version | Emergency recovery |
| `/review-awf` | **Project overview** ⭐ NEW | Handover, review, upgrade planning |


---

## 🔥 VIBE CODER BLIND SPOTS — FULLY ADDRESSED

### 📐 When planning (`/plan-awf`)
| Blind spot | AI asks itself |
|------------|----------------|
| Database Design | "Existing data? What to manage?" |
| Auth/Login | "Need login? OAuth? Roles?" |
| File Upload | "Need file uploads? Size limit?" |
| Email/Notifications | "Need to send notifications?" |
| Payment | "Accept payments?" |
| Search | "Need search? Fuzzy?" |
| Scheduled Tasks | "Need auto-run daily tasks?" |
| Charts/Graphs | "Need charts?" |
| PDF/Print | "Need to print invoices?" |
| Maps | "Need maps?" |
| Real-time | "Need live updates?" |

### 🎨 When designing UI (`/visualize-awf`)
| Blind spot | AI handles automatically |
|------------|--------------------------|
| Loading States | Skeleton, Spinner, Progress bar |
| Error States | Toast, Modal, Inline error |
| Empty States | Illustration + Call-to-action |
| Accessibility | Color contrast, ARIA, Keyboard nav |
| Mobile | Responsive, Touch-friendly |
| Dark Mode | Dual theme design |

### 🚀 When deploying (`/deploy-awf`)
| Blind spot | AI handles automatically |
|------------|--------------------------|
| SEO | Meta tags, Sitemap, robots.txt |
| Analytics | Google Analytics / Plausible |
| Legal | Privacy Policy, Terms, Cookie consent |
| Backup | Database backup strategy |
| Monitoring | Uptime + Error tracking |
| SSL | Auto HTTPS |
| Maintenance | Maintenance mode page |

### 📚 When saving (`/save-brain-wm`)
| Blind spot | AI auto-generates |
|------------|-------------------|
| API Documentation | Auto-generate from routes |
| Changelog | Version history |
| Business Rules | Business rules |
| **Structured Context** | `.brain/brain.json` ⭐ NEW |

---

## 🚀 AWF 2.0 — NEW FEATURES

### 1️⃣ Deep Interview (3 Golden Questions)
Before proposing, AI asks 3 core questions:
- What are you MANAGING?
- Who will USE it?
- What MATTERS MOST?

→ Helps AI understand correctly from the start, avoiding rework.

### 2️⃣ Lazy Checkpoint (Save tokens)
```
.brain/
├── session.json        # Update per PHASE (~450 tokens)
└── session_log.txt     # Append per TASK (~20 tokens)
```
→ 80% token overhead reduction vs rewriting JSON every task.

### 3️⃣ Proactive Handover
When context > 80% full:
- AI auto-creates a Handover Document
- Saves to `.brain/handover.md`
- Next session, type `/recap-wm` to resume immediately

→ NEVER lose context between sessions.

### 4️⃣ Step Confirmation Protocol
After every milestone, display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ DONE: [Task name]
📊 Progress: ████████░░ 80%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
→ Continue? (y/adjust/stop)
```
→ User always knows where they are, never feels "out of control".

### 5️⃣ Agent Personas (BMAD-Inspired)
| Workflow | Persona | Personality |
|----------|---------|-------------|
| `/plan-awf` | Ha (PM) | Listens, proposes options |
| `/design-awf` | Minh (Architect) | Explains technical concepts simply |
| `/code-awf` | Tuan (Senior Dev) | Careful, thorough checks |
| `/visualize-awf` | Mai (UX Designer) | Visual, uses examples |
| `/debug-awf` | Long (Detective) | Calm, methodical |
| `/audit-awf` | Khang (Code Doctor) | Doesn't cause panic |

---

## 🧠 Structured Context - v3.3 (Separated brain + session)

### The v3.2 problem
- `brain.json` contained both static and dynamic data
- Every save required rewriting the entire file
- Session state mixed with project knowledge

### v3.3 Solution: Split into 2 files
```
.brain/                            # LOCAL (per-project)
├── brain.json                     # 🧠 Static knowledge (rarely changes)
├── session.json                   # 📍 Dynamic session (changes constantly)
└── preferences.json               # ⚙️ Local override (if different from global)

~/.antigravity/                    # GLOBAL (all projects)
├── preferences.json               # Default AI preferences
└── defaults/                      # Templates
```

### Benefits
| Metric | v3.2 | v3.3 |
|--------|------|------|
| Files to scan | 1 (brain.json) | 2 (brain + session) |
| Token usage | ~3KB | ~3KB (equivalent) |
| Update frequency | Every save | brain: when project changes, session: constantly |
| Scope | Local only | Local + Global preferences |

### Workflow
```
/save-brain → Update brain.json (if needed) + session.json (always)
/recap → Load preferences → brain.json → session.json → Summary
/customize → Save preferences (local/global/both)
```

### Schema files
- `schemas/brain.schema.json` - Project knowledge
- `schemas/session.schema.json` - Session state ⭐ NEW
- `schemas/preferences.schema.json` - User preferences ⭐ NEW

### Template files
- `templates/brain.example.json`
- `templates/session.example.json` ⭐ NEW
- `templates/preferences.example.json` ⭐ NEW

### brain.json (Static — rarely changes)
- `project`: Name, type, status
- `tech_stack`: Frontend, Backend, DB, Dependencies
- `database_schema`: Tables, Relationships
- `api_endpoints`: Routes with auth info
- `business_rules`: Business rules
- `features`: Features and status
- `knowledge_items`: Patterns, Gotchas, Conventions

### session.json (Dynamic — changes constantly) ⭐ NEW
- `working_on`: Feature, task, status, files being edited
- `pending_tasks`: What needs to be done next
- `recent_changes`: Recent changes
- `errors_encountered`: Errors encountered and fixes
- `decisions_made`: Decisions made during the session

### preferences.json (User settings) ⭐ NEW
- `communication`: Tone, persona
- `technical`: Detail level, autonomy, quality
- `working_style`: Pace, feedback style
- `custom_rules`: User's custom rules

---

## 🛡️ Resilience Patterns - v3.3 (Hidden from User)

> **Principle:** User doesn't need to know about retry, timeout, fallback. AI handles it silently.

### Auto-Retry (Hidden)
```
When encountering transient errors (network, rate limit):
1. Retry 1 (wait 1s)
2. Retry 2 (wait 2s)
3. Retry 3 (wait 4s)
4. If still failing → Notify user in simple terms
```

### Timeout Protection (Hidden)
```
Each task has a default timeout:
- /code: 5 minutes
- /deploy: 10 minutes
- /debug: 5 minutes
- Other: 3 minutes

When timeout → "This is taking longer than expected. Do you want to continue?"
```

### Fallback Conversation (Shown when needed)
```
Instead of complex syntax like: /deploy production || staging

AI asks in natural language:
"Deploying to production isn't working right now 😅
 Want to try staging first?
 1️⃣ Yes — Deploy staging
 2️⃣ No — Let me check the error"
```

### Error Messages (Simplified)
```
❌ Old: "Error: ECONNREFUSED 127.0.0.1:5432 - Connection refused"

✅ New: "Can't connect to the database 😅
        Please check if PostgreSQL is running!
        Type /debug if you need help."
```

### Error Categories
| Error type | AI handles | User sees |
|------------|------------|-----------|
| Network timeout | Auto-retry 3x | Nothing (if successful) |
| Rate limit | Wait and retry | "Waiting for API..." |
| Auth failed | Report immediately | "Need to check credentials" |
| Code syntax | Suggest fix | "Error in file X, type /debug" |
| Build failed | Analyze logs | "Build failed because of Y, I suggest..." |

---

## 🎮 Recommended Workflows

### 📦 New Project
```
/init-awf → /plan-awf → /visualize-awf → /code-awf → /run-awf → /test-awf → /deploy-awf → /save-brain-wm
```

### 🌅 Starting a New Day
```
/recap-wm → /code-awf → /run-awf → /test-awf → /save-brain-wm
```

### 🐛 When Encountering Errors
```
/debug-awf → /test-awf → (if chaotic) /rollback-awf
```

### 🚀 Before Release
```
/audit-awf → /test-awf → /deploy-awf → /save-brain-wm
```

---

## 📊 System Stats v3.4

| Workflow | Size | Quality |
|----------|------|---------|
| `/plan-awf` | **5.4KB** | ⭐⭐⭐⭐⭐ Ultimate |
| `/deploy-awf` | **5.3KB** | ⭐⭐⭐⭐⭐ Ultimate |
| `/init-awf` | 4.9KB | ⭐⭐⭐⭐⭐ Complete |
| `/visualize-awf` | 4.8KB | ⭐⭐⭐⭐⭐ Complete |
| `/debug-awf` | 4.7KB | ⭐⭐⭐⭐⭐ Complete |

| `/save-brain-wm` | **4.2KB** | ⭐⭐⭐⭐⭐ Ultimate |
| `/audit-awf` | 4.2KB | ⭐⭐⭐⭐⭐ Complete |
| `/refactor-awf` | 4.2KB | ⭐⭐⭐⭐⭐ Complete |
| `/code-awf` | 3.6KB | ⭐⭐⭐⭐⭐ Complete |
| `/run-awf` | 2.6KB | ⭐⭐⭐⭐ Good |
| `/test-awf` | 2.4KB | ⭐⭐⭐⭐ Good |
| `/recap-wm` | 2.4KB | ⭐⭐⭐⭐ Good |
| `/rollback-awf` | 2.2KB | ⭐⭐⭐⭐ Good |

**Total:** 13 workflows | **~55KB** instructions | **50+ blind spots** handled

---

## 💡 Tips for Vibe Coders

1. **Just talk naturally** — AI will ask if something is missing
2. **Don't fear mistakes** — There's `/rollback-awf`
3. **End of day `/save-brain-wm`** — No context lost tomorrow
4. **Periodic `/audit-awf`** — Prevention is better than cure
5. **Before release `/deploy-awf`** — SEO, Analytics, Legal all covered

---

*Antigravity Vibe Coding Suite v3.4 — Your dreams, our engineering.*
