---
name: awf-adaptive-language
description: >-
  Adjust terminology based on user technical level. Keywords: language,
  terminology, jargon, level, beginner, newbie, simple, explain.
  Reads technical_level from preferences.json and sets communication context.
version: 1.0.0
---

# AWF Adaptive Language

Automatically adjusts technical terminology based on user level.

## Trigger Conditions

**Pre-hook for ALL workflows** - Activates at session start.

**Check preferences:**
```
if exists(".brain/preferences.json"):
    → Read technical_level
else if exists("~/.antigravity/preferences.json"):
    → Read global technical_level
else:
    → Default: "basic"
```

## Personality Modes (from /customize)

**Also read `personality` from preferences.json:**

### Mentor Mode (`mentor`)
```
When performing any task:
1. Explain WHY we do it this way
2. Explain unfamiliar terms
3. Occasionally ask back: "What do you think is the reason for doing this?"
4. After finishing: "What did you learn from this step?"
```

### Strict Coach Mode (`strict_coach`)
```
When performing any task:
1. Demand high quality
2. Point out better approaches
3. Explain best practices
4. Reject bad code: "This approach is suboptimal because..."
```

### Default (no personality setting)
→ Use "Smart Assistant" style - helpful, offers options

---

## Technical Levels

### Level: `newbie`
**Target:** No coding knowledge, just has ideas

| Term | Translation |
|------|-------------|
| database | information storage |
| API | communication gateway between software |
| deploy | put online for others to use |
| commit | save changes |
| branch | draft version of the project |
| error | issue to fix |
| debug | find and fix errors |
| test | check if it works correctly |
| server | computer that runs the app |
| frontend | the interface users see |
| backend | hidden processing behind the scenes |

**Communication style:**
- Explain EVERY technical concept
- Use real-world analogies
- Avoid abbreviations
- Small steps, one at a time

### Level: `basic`
**Target:** Knows how to use computers, can read basic code

| Term | Usage |
|------|-------|
| database | database (data storage) |
| API | API (programming interface) |
| deploy | deploy (release) |
| commit | commit (save changes to git) |

**Communication style:**
- Explain technical terms on first use
- Then use them normally
- Suggest further reading if needed
- Group small steps together

### Level: `technical`
**Target:** Developers, experienced coders

**Communication style:**
- Use standard terminology
- No explanation needed
- Focus on implementation
- Can use abbreviations (PR, CI/CD, etc.)

## Execution Logic

### Step 1: Load Preferences

```
preferences = null

# Try local first
if exists(".brain/preferences.json"):
    preferences = parse(".brain/preferences.json")

# Fallback to global
if !preferences && exists("~/.antigravity/preferences.json"):
    preferences = parse("~/.antigravity/preferences.json")

# Extract level
level = preferences?.technical?.technical_level || "basic"
```

### Step 2: Set Context

```
Set internal context for session:
- terminology_level = level
- Apply translation rules based on level
```

### Step 3: Silent Operation

This skill operates SILENTLY:
- DO NOT show indicator
- DO NOT notify user
- Just sets context for subsequent responses

## Integration with Workflows

All AWF workflows should respect the set terminology level:

```
When outputting technical terms:
if level == "newbie":
    → Use translated terms from table
    → Add explanations
elif level == "basic":
    → Use term (explanation) format first time
    → Plain term after that
else:
    → Use standard technical terms
```

## Performance

- Load time: < 100ms
- Single file read
- Cached for session duration

## Error Handling

```
If preferences.json corrupted:
→ Use default level: "basic"
→ NO error message to user

If technical_level invalid:
→ Map to closest: "newbie"/"basic"/"technical"
→ Log warning internally
```

## Example Behavior

**User level: newbie**
```
User: /deploy

Output: "Ready to put the app online (deploy) for others to use.
I'll check if everything is ready..."
```

**User level: technical**
```
User: /deploy

Output: "Initiating deployment pipeline.
Running pre-deploy checks..."
```
