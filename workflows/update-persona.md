---
description: Update AI Agent Persona (AGENTS.md / CLAUDE.md)
---

# Workflow: Update Persona (/update-persona)

Update the AI assistant persona and user preferences for the workspace. This workflow creates or updates `AGENTS.md` (for Opencode) or `CLAUDE.md` (for Claude Code) with context-loading instructions, behavior rules, and greeting preferences.

---

## Overview

| Step | Description |
|------|-------------|
| 1 | Detect target platform (Opencode AGENTS.md / Claude CLAUDE.md) |
| 2 | Check for existing persona file |
| 3 | Ask greeting preference (F-30) |
| 4 | Load template for target platform |
| 5 | Gather behavior rules and output preferences |
| 6 | Generate persona content with context loading instructions (F-29) |
| 7 | Write file to workspace root |
| 8 | Announce success |

---

## Step 1: Target Detection

Determine which persona file to create/update:

```
Check for CLI/IDE target using path detection (reuse install.ps1 Step 1 logic):

1. Check: Does ~/.config/opencode/ exist?
  YES target = "AGENTS.md", template = "templates/AGENTS.md.template"
2. Else check: Does ~/.codex/ exist?
  YES target = "AGENTS.md", template = "templates/AGENTS.md.template"
3. Else check: Does ~/.gemini/config/ exist?
  YES target = "GEMINI.md", template = "templates/GEMINI.md.template"
4. Else check: Does ~/.claude/ exist?
  YES target = "CLAUDE.md", template = "templates/CLAUDE.md.template"
5. Else — ask user:
  "Which platform are you using? 1 Opencode 2 Claude Code 3 Codex 4 Antigravity"

Priority: Check Opencode FIRST (even if CLAUDE.md exists from prior install).
```

---

## Step 2: Check Existing File

```
if exists(target_file):
 Show summary of current persona
 Ask: "Update existing persona or recreate from scratch?"
 If update parse current file, pre-fill preferences
 If recreate continue to Step 3
else:
 Continue to Step 3
```

---

## Step 3: Greeting Preference (F-30)

Ask user how they'd like to be addressed:

```
"How would you like me to address you?

1 Sp (formal, Vietnamese)
2 Anh/Ch (respectful, Vietnamese)
3 Bn (casual, Vietnamese)
4 [Custom name] (your preferred name)
5 No greeting (skip)
```

Save selection as `{greeting}` variable.

---

## Step 4: Load Template

Load the appropriate template file:

```
if target == "AGENTS.md":
 template_content = read("templates/AGENTS.md.template")
elif target == "CLAUDE.md":
 template_content = read("templates/CLAUDE.md.template")
```

---

## Step 5: Gather Preferences

Ask user for behavior rules and output preferences:

```
"Customize how I behave:

 Persona Mode:
1 Mentor Explain WHY, teach as we go
2 Strict Coach Demand clean code, best practices
3 Default Senior Dev style, focus on delivery

 Technical Level:
1 Newbie Simple language, avoid jargon
2 Basic Some technical terms OK
3 Technical Full technical detail

 Language Preference:
1 English (technical output)
2 Vietnamese (if project requires)
```

Save selections as `{behavior_rules}` and `{output_preferences}`.

---

## Step 6: Generate Persona Content (F-28, F-29)

Perform template variable substitution:

```
persona_content = template_content
 .replace("{greeting}", greeting)
 .replace("{behavior_rules}", formatted_behavior_rules)
 .replace("{output_preferences}", formatted_output_preferences)
```

**Context loading instructions (F-29)** are already embedded in the template:
- Read L0 (business-context.md) first IMMUTABLE
- Read L1 (domain-context.md) must not conflict with L0
- Read L2 (project-context.md) when entering specific workspace
- Follow Gene Flow rules: L2 L1 L0 compliance

**Constraint handling** (from business context 6, 7, 9):
- All LLM calls must go through AI Gateway
- Brand disambiguation: "AI agent" (generic) "FPT AI Agents" (product)
- No negative comparison with competitors
- SCRUM team roles: PO, PM, BA, Dev FE/BE, Tester, SM

---

## Step 7: Write File

```
Write-Content(target_file, persona_content)
```

Write to workspace root:
- For Opencode: `[workspace]/AGENTS.md`
- For Claude Code: `[workspace]/CLAUDE.md`

---

## Step 8: Announce Success

```
" Persona updated successfully!

 Target: {target_file}
 Greeting: {greeting}
 Mode: {persona_mode}
 Level: {technical_level}

 Location: [workspace]/{target_file}

Next time you start a session, I'll load context in this order:
1 L0: Business Context (business-context.md)
2 L1: Domain Context (domain-context.md)
3 L2: Project Context (project-context.md)

Run /recap-wm to resume your previous session.
Run /help-wm to see all available commands."
```

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Template file missing | Fallback: generate content from inline defaults |
| Write permission denied | Suggest alternative location, offer to show content |
| Both AGENTS.md and CLAUDE.md exist | Ask which to update |
| Empty preferences | Use defaults: Mentor mode, Basic level, English |
| Custom name with special chars | Sanitize: strip markdown formatting characters |

---

## Reference Files

| File | Location |
|------|----------|
| AGENTS.md template | `templates/AGENTS.md.template` |
| CLAUDE.md template | `templates/CLAUDE.md.template` |
| Existing AGENTS.md | `[workspace]/AGENTS.md` |
| Existing CLAUDE.md | `[workspace]/CLAUDE.md` |
| User preferences | `templates/preferences.example.json` |
