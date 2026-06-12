---
name: awf-onboarding
description: >-
  First-time user onboarding experience. Keywords: new, first, start, begin,
  welcome, tutorial, guide, learn, help me.
  Activates on first /init or when .brain/preferences.json doesn't exist.
version: 1.0.0
---
# AWF Onboarding

Guide new users through getting started with AWF.

## Trigger Conditions

**Activates when:**

- User runs `/init-awf` for the first time (no `.brain/` folder)
- User runs `/help-awf` and no preferences exist
- User says "new to this", "guide", "don't know where to start"

**Check:**

```
if NOT exists(".brain/preferences.json") AND NOT exists("~/.antigravity/preferences.json"):
     Activate onboarding
else:
     Skip (returning user)
```

## Execution Logic

### Step 1: Welcome Message

```
👋 **WELCOME TO AWF!**

I'm your AI assistant, I'll help you turn ideas into real apps.

🎯 AWF can help you:
   • Create apps/websites from scratch
   • No coding required (I'll do it for you!)
   • Remember everything between sessions

⏱️ Give me 2 minutes for a quick guide?

1️⃣ Yes, guide me
2️⃣ No thanks, let's start right away
```

### Step 2: Quick Assessment (if option 1 chosen)

```
📊 **LET ME GET TO KNOW YOU A BIT:**

Have you made apps/websites before?

1️⃣ Never (newbie)
   → I'll explain everything simply

2️⃣ A little bit (basic)
   → I'll explain when needed

3️⃣ I'm an IT person (technical)
   → I'll talk like a colleague
```

### Step 3: 5 Commands Tour

```
🗺️ **5 MOST IMPORTANT COMMANDS:**

┌─────────────────────────────────────────┐
│ 1️⃣ /brainstorm-awf                     │
│    "I have an idea but it's not clear"   │
│    → AI helps clarify the idea           │
├─────────────────────────────────────────┤
│ 2️⃣ /plan-awf                                │
│    "I know what I want to do"            │
│    → AI creates a detailed plan          │
├─────────────────────────────────────────┤
│ 3️⃣ /code-awf                                │
│    "Start writing code"                  │
│    → AI codes according to the plan      │
├─────────────────────────────────────────┤
│ 4️⃣ /run-awf                                 │
│    "Let's run it and see"                │
│    → Launch the app to see the result    │
├─────────────────────────────────────────┤
│ 5️⃣ /debug-awf                               │
│    "There's an error, fix it please"     │
│    → AI finds and fixes errors           │
└─────────────────────────────────────────┘

💡 Tip: Don't need to memorize them all! Type /next anytime
   for me to suggest what to do next.
```

### Step 4: Quick Start Options

```
🚀 **LET'S GET STARTED!**

What would you like to do?

1️⃣ I have an app idea already → /plan-awf
2️⃣ Not sure, want to discuss first → /brainstorm-awf
3️⃣ More detailed guidance → /help-awf
4️⃣ Customize how AI talks → /customize-awf
```

### Step 5: Initialize .brain/ Folder

**Create folder structure:**

```
.brain/
├── preferences.json
├── session.json
├── session_log.txt
└── brain.json
```

**preferences.json:**

```json
{
  "communication": {
    "tone": "friendly",
    "personality": "assistant"
  },
  "technical": {
    "technical_level": "[user_choice]",
    "detail_level": "simple",
    "autonomy_level": "ask_often"
  },
  "onboarding_completed": true,
  "onboarding_date": "[timestamp]"
}
```

**session.json:**

```json
{
  "updated_at": "[timestamp]",
  "working_on": {
    "feature": null,
    "task": null,
    "status": "idle"
  },
  "pending_tasks": [],
  "errors_encountered": [],
  "decisions_made": [
    {
      "decision": "Technical level set to [level]",
      "reason": "User selection during onboarding"
    }
  ],
  "skipped_tests": []
}
```

**session_log.txt:**

```
[YYYY-MM-DD HH:MM] ONBOARDING COMPLETE
[YYYY-MM-DD HH:MM] Technical level: [level]
[YYYY-MM-DD HH:MM] Ready for first project
```

**brain.json:**

```json
{
  "meta": {
    "schema_version": "1.0.0",
    "awf_version": "4.0.2",
    "created_at": "[timestamp]"
  },
  "project": {
    "name": null,
    "type": null,
    "status": "not_started"
  },
  "updated_at": "[timestamp]"
}
```

### Step 6: Save & Complete

```
✅ **SETUP COMPLETE!**

I've created:
📁 .brain/
   ├── preferences.json  (your settings)
   ├── session.json      (progress tracking)
   ├── session_log.txt   (activity log)
   └── brain.json        (project knowledge)

💾 Everything will be auto-saved from now on!

────────────────────────

Now, what would you like to do?

1️⃣ Create first project → /init-awf
2️⃣ Brainstorm ideas first → /brainstorm-awf
3️⃣ Detailed guide → /help-awf
```

## Returning User Detection

```
if exists("preferences.json") AND preferences.onboarding_completed == true:

     If > 7 days since last use:
          "👋 Welcome back! Type /recap and I'll remind you what we were working on."

     If < 7 days:
          Skip welcome, go straight to workflow
```

## Error Handling

```
If cannot create .brain/ folder:
    Try create in current directory
    If still fail:
        Warning: "⚠️ I couldn't create a storage folder, but we can still work!"
        Continue in-memory mode

If user skips all steps:
    Use defaults: technical_level = "basic"
    Mark onboarding_completed = true
```

## Integration

**With /init-awf:**

```
/init-awf is called
    ↓
Check .brain/ folder
    ↓
├── Doesn't exist → Run onboarding FIRST
└── Exists → Run /init-awf normally
```

## Performance

- Total time: < 2 minutes
- No external API calls
- Minimal file I/O
