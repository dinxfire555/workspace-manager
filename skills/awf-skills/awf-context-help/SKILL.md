---
name: awf-context-help
description: >-
  Context-aware help based on current workflow state. Keywords: help, what,
  how, confused, stuck, lost, guide, tutorial, explain.
  Activates on /help or when user asks questions.
version: 1.0.0
---

# AWF Context Help

Intelligent help based on current context.

## Trigger Conditions

**Activates when:**
- User runs `/help`
- User types "?", "help", "how to"
- User seems confused (repeated errors, long pause)

## Execution Logic

### Step 1: Read Context

```
context = {}

if exists(".brain/session.json"):
    context.workflow = session.working_on.feature
    context.task = session.working_on.task
    context.status = session.working_on.status
    context.pending = session.pending_tasks

if exists(".brain/brain.json"):
    context.project = brain.project.name
    context.tech = brain.tech_stack
```

### Step 2: Detect State

| State | Detection | Response |
|-------|-----------|----------|
| `no_project` | No .brain/ folder | Show onboarding |
| `planning` | workflow contains "plan" | Planning help |
| `coding` | workflow contains "code" | Coding help |
| `debugging` | workflow contains "debug" | Debug help |
| `deploying` | workflow contains "deploy" | Deploy help |
| `stuck` | status = "blocked" or pending > 5 | Stuck help |
| `idle` | No active workflow | General help |

### Step 3: Show Contextual Help

## Help Templates

### No Project State
```
🆕 No project yet

You can:
1. /brainstorm - Brainstorm ideas first
2. /init - Create a new project
3. Tell me about your idea

I'll guide you step by step!
```

### Planning State
```
📋 Planning: {context.workflow}

You can:
1. Continue current plan
2. /code - Start first coding phase
3. Ask me about design

💡 Tip: Good plan = Faster coding!
```

### Coding State
```
💻 Coding: {context.task}
   Status: {context.status}

You can:
1. Continue coding
2. /test - Test the code you just wrote
3. /debug - If you hit an error
4. /save-brain - Save progress

💡 Pending tasks: {context.pending.length}
```

### Debugging State
```
🔧 Debugging: {context.task}

You can:
1. Describe the error in more detail
2. Paste error message
3. /code - Return to coding after fix

💡 Tip: Copy-paste the error helps me understand faster!
```

### Deploying State
```
🚀 Deploying: {context.workflow}

You can:
1. Continue deploy process
2. /rollback - Roll back to previous version if error
3. Check logs after deploy

⚠️ Remember to test thoroughly before production deploy!
```

### Stuck State
```
😅 Looks like you're stuck

Try these approaches:
1. /recap - Review what we're doing
2. /debug - If there are errors
3. Take a 5-minute break then come back
4. Ask me specifically about the issue

💡 {context.pending.length} tasks pending.
   Maybe skip the hard task, do something else first?
```

### Idle/General State
```
👋 How can I help?

Popular commands:
┌─────────────────────────────────────┐
│ /next       │ Suggest next action    │
│ /recap      │ Recall context         │
│ /brainstorm │ Discuss new ideas      │
│ /plan       │ Create a plan          │
│ /code       │ Write code             │
└─────────────────────────────────────┘

Or ask me anything!
```

## Adaptive Language

Help responses adapt to `technical_level`:

**newbie:**
- Use plain language
- Explain all concepts
- Small, detailed steps

**basic:**
- Mix plain and technical terms
- Explain terms on first use
- Moderate steps

**technical:**
- Use standard terms
- No explanation needed
- Focus on actions

## Fallback

If context unreadable:
```
👋 I'm here to help!

Type /next for me to suggest what to do next,
or describe your issue to me.
```

## Performance

- Context read: < 200ms
- Response generation: Instant
- No external API calls
