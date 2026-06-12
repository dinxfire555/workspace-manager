---
name: awf-auto-save
description: >-
  Eternal Context System - Auto-save session to prevent context loss.
  Triggers: workflow end, user leaving, decisions, periodic checkpoint.
  Warns when context is getting full.
version: 1.0.0
---
# AWF Auto-Save (Eternal Context)

Automatically save session to never lose context.

## Trigger Conditions

### 1. Workflow End (Automatic)

After completing any workflow:

- `/plan` → Save decisions, specs
- `/code` → Save progress, files changed
- `/debug` → Save errors resolved
- `/test` → Save test results
- `/deploy` → Save deployment info

### 2. User Leaving Detection

Pattern matching in user messages:

```
patterns:
  - "bye", "goodbye", "taking a break"
  - "I'm off", "lunch time", "stopping for now"
  - "time's up", "continue tomorrow", "save"
  - "close app", "shutting down"
```

### 3. Decision Made Detection

When user makes a decision:

```
patterns:
  - "choose option", "use this one"
  - "ok", "agreed", "let's do that"
  - "decided on", "will use"
```

### 4. Periodic Checkpoint

Every 15 messages → Background save

### 5. Context Warning (80% estimate)

```
token_estimate = message_count * 150 + code_blocks * 300
if token_estimate > 100000:  # 80% of 128K
    trigger_emergency_save()
    show_warning()
```

## Execution Logic

### Step 1: Detect Trigger

```
on_message(user_input):
    increment message_count

    if matches_leaving_pattern(user_input):
        trigger = "user_leaving"
    elif matches_decision_pattern(user_input):
        trigger = "decision_made"
    elif message_count % 15 == 0:
        trigger = "periodic"
    elif estimate_tokens() > 100000:
        trigger = "emergency"
    else:
        return  # No save needed

    execute_save(trigger)
```

### Step 2: Generate Summary

```
summary = {
    project: brain.project.name,
    current_feature: session.working_on.feature,
    current_task: session.working_on.task,
    status: session.working_on.status,
    progress_percent: calculate_progress(),
    last_action: get_last_action(),
    next_step: suggest_next_step()
}
```

### Step 3: Save to Session

```
session.summary = summary
session.message_count = current_count
session.context_checkpoints.append({
    timestamp: now(),
    trigger: trigger_type,
    summary: compress_summary(summary),
    message_count: current_count
})
save_to_file(".brain/session.json")
```

### Step 4: Notify User (if enabled)

```
if trigger == "user_leaving":
    show: "💾 Detected you're leaving, session auto-saved."

if trigger == "workflow_end":
    show: "💾 Progress saved. You can safely close the app."

if trigger == "emergency":
    show: "⚠️ Context nearly full. Backup saved. Consider starting new session."

if trigger == "periodic" or "decision_made":
    # Silent save - no notification
```

## Token Estimation Heuristic

```
function estimate_tokens():
    base = message_count * 150
    code_blocks = count_code_blocks() * 300
    error_dumps = count_errors() * 200

    return base + code_blocks + error_dumps

function get_warning_level():
    tokens = estimate_tokens()
    if tokens > 115000: return "critical"  # 90%
    if tokens > 100000: return "warning"   # 80%
    if tokens > 80000: return "info"       # 60%
    return "safe"
```

## Snapshot Management

### Save Snapshot (7 days retention)

```
on_workflow_end():
    snapshot = {
        timestamp: now(),
        session: session.json,
        brain_summary: extract_brain_summary()
    }
    save_to(".brain/snapshots/{date}_{time}.json")

    # Cleanup old snapshots
    delete_snapshots_older_than(7_days)
```

### Restore from Snapshot

```
if session.json corrupted:
    latest_snapshot = get_latest_snapshot()
    restore_from(latest_snapshot)
    show: "Restored from latest backup."
```

## User Messages

```yaml
workflow_end:
  en: "💾 Progress saved. You can safely close the app."

user_leaving:
  en: "💾 Detected you're leaving, session auto-saved."

context_warning:
  en: "⚠️ Context nearly full. Backup saved. Consider starting new session."

emergency_save:
  en: "⚠️ Emergency save complete. Use /recap in new session to continue."
```

## Integration with Workflows

Every workflow MUST call auto-save on completion:

```markdown
# End of each workflow.md:

## Post-Workflow: Auto-Save

After completing the workflow:
1. Update session.summary
2. Append to context_checkpoints
3. Show message: "💾 Progress saved."
```

## Config Options

```json
{
  "auto_save_config": {
    "enabled": true,
    "notify_on_save": true,
    "checkpoint_interval": 15,
    "warn_threshold": 80,
    "snapshot_retention_days": 7
  }
}
```

## Error Handling

```
if save_fails:
    retry 3 times with exponential backoff
    if still fails:
        show: "⚠️ Cannot save session. Check file write permissions."
        log error to console

if disk_full:
    delete oldest snapshots
    retry save
```
