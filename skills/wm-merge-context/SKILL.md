---
name: wm-merge-context
description: >-
 Merge context from multiple layers (L0-L3) into unified workspace context.
 Handles section-based merge with conflict markers, IMMUTABLE section preservation,
 and Gene Flow compliance tracking.
 Keywords: merge, context, layers, combine, integrate, gene-flow, compliance, sections, conflict.
version: 2.0.0
---

# WM Merge Context (F-20)

Merge context files from multiple AI Context Architecture layers into a single unified workspace context. Used when a user changes Unit/Department and needs to merge old + new context files.

## Trigger Conditions

- **Called from**: `/init-wm` Step 2b (when user moves to different Unit/Department)
- **Called from**: `/new-workspace` and `/new-workspace-local` (Phase 03)
- **Standalone**: User can invoke manually when they have multiple context files to merge

## Purpose

When a user moves from one Unit/Department to another, their old context (business-context.md or domain-context.md) may contain project-specific knowledge that should be preserved. This skill merges two context files of the same type (L0 with L0, L1 with L1) while:

1. Preserving **IMMUTABLE sections** from the preferred layer
2. Detecting **conflicts** between matching sections
3. Adding **merge history** for auditability
4. Maintaining **Gene Flow compliance** traceability

---

## Algorithm (Section-Based Merge ADR-2)

```
INPUT: File A (existing/old context), File B (new context)
OUTPUT: Merged file + merge log

PROCEDURE:

1. PARSE ## HEADERS
 Read File A, extract sections: [{"header": "Overview", "content": "..."}, ...]
 Read File B, extract sections: [{"header": "Overview", "content": "..."}, ...]

2. IDENTIFY IMMUTABLE SECTIONS
 IMMUTABLE sections are marked with: <!-- IMMUTABLE --> in the source file
 These sections MUST be preserved from their original layer
 If both files have the same IMMUTABLE section File A (existing) wins

3. MATCH SECTIONS BY HEADER
 For each section header in File B:
 If header exists in File A:
 Content identical Keep from File A
 Content different CONFLICT Ask user:
 Option 1: Keep old (File A)
 Option 2: Use new (File B)
 Option 3: Keep both (mark as merged)
 Section is IMMUTABLE Force keep File A
 If header NOT in File A Add section from File B

 For sections only in File A Keep as-is
 For sections only in File B Add (append at appropriate position)

4. SORT SECTIONS IN STANDARD ORDER
 Overview
 Objectives / Goals
 Scope
 Requirements
 Architecture / Technical
 Rules / Constraints
 IMMUTABLE sections (preserved)
 Appendices
 Merge History (auto-generated, always last)

5. ADD MERGE HISTORY COMMENT
 Appended at bottom of merged file:
 <!-- MERGE HISTORY
 Merged: [timestamp]
 Source A: [filename] (existing)
 Source B: [filename] (new)
 Sections merged: [count]
 Conflicts resolved: [count]
 IMMUTABLE sections preserved: [count]
 -->
```

---

## Conflict Markers

When a conflict is detected, the merge inserts HTML comment markers into the output:

```markdown
## Section Title

<!-- CONFLICT START: "Section Title"
 Option A (existing):
 [Content from File A]
 ---
 Option B (new):
 [Content from File B]
-->

<!-- User selected: Option X (keep old / use new / keep both) -->

[Selected content]

<!-- CONFLICT END -->
```

If user chooses **Keep both**, both contents are included with a divider:

```markdown
## Section Title

[Content from File A]

---

*[Merged content from new context see merge history below]*

[Content from File B]
```

---

## IMMUTABLE Section Handling

Sections marked with `<!-- IMMUTABLE -->` at the start of their content are **forced preserved** from their original layer:

```markdown
## Compliance Requirements

<!-- IMMUTABLE -->
This section must not be changed during merge operations.
```

Rules:
- IMMUTABLE sections from Layer 0 (Business Context) take highest priority
- If both files have the same IMMUTABLE section File A (existing) wins
- The merge log records which IMMUTABLE sections were preserved

---

## Gene Flow Compliance

The merged output must maintain Gene Flow traceability:

| Requirement | Check |
|-------------|-------|
| L2 compliance traceability to L0 | Each L2 rule must reference L0 section IDs |
| L1 dependency references to L0 | Each L1 dependency must list L0 source |
| No orphan sections | Every section must have a layer origin recorded in merge history |

---

## Output

### Merged File

Written to the original file path with `.merged` suffix during review, then renamed once user confirms:

- `00_System/01_context/business-context.md.merged` (pending review)
- Renamed to `00_System/01_context/business-context.md` (on user confirm)

### Merge Log

Appended to `.brain/merge_log.txt`:

```
[2026-06-07T10:30:00Z] MERGE: business-context.md
 Source A: Unit=A, Dept=X (existing)
 Source B: Unit=B, Dept=Y (new)
 Sections: 12 total, 3 merged, 1 conflict resolved
 IMMUTABLE: 2 sections preserved
 Result: OK
```

---

## Error Handling

| Scenario | Action |
|----------|--------|
| File A not found | Error: "Cannot find existing context file" |
| File B not found | Error: "Cannot find new context file" |
| No sections found in either file | Error: "No parseable sections found" |
| Invalid YAML frontmatter | Parse as plain text, warn user |
| User cancels during conflict resolution | Keep all conflicts as markers, write partial merge |

---

## References

- **F-20**: Merge context skill (this file)
- **ADR-2**: Section-based merge with conflict markers
- **Phase 02 requirement**: Called at 6+ positions in full pipeline
- **Gene Flow rules**: L0 > L1 > L2 > L3 priority enforcement
