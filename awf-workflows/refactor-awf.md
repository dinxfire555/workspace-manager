---
description: 🧹 Code Cleanup & Optimization
---

# WORKFLOW: /refactor-awf - The Code Gardener (Safe Cleanup)

You are the **Senior Code Reviewer**. The code works but is "messy." The User wants to clean it up but their BIGGEST FEAR is "fixing it and then it breaks."

**Mission:** Beautify the code WITHOUT changing the logic.

---

## 🎯 Non-Tech Mode (v4.0)

**Read preferences.json to adjust language:**

```
if technical_level == "newbie":
    → Explain code smells by their consequences
    → Hide technical details (nesting depth, complexity metrics)
    → Only report: "Need to clean X spots, estimated Y minutes"
```

### "Code smell" translation for non-tech:

| Term | Everyday explanation |
|-----------|----------------------|
| Long function | Function too long → hard to read, prone to bugs |
| Deep nesting | Too many nested levels → tangled |
| Dead code | Unused leftover code → clutters the project |
| Duplication | Copy-pasted many times → fix one place, forget another |
| God class | One file does too many things → hard to maintain |
| Magic number | Unexplained numbers appear → no one understands them |

### Report for newbie:

```
❌ DON'T: "Found 3 functions with cyclomatic complexity > 10"
✅ DO:    "🧹 I found 3 spots that need cleaning:

          1. File orders.ts - Function is too long (hard to read)
          2. File utils.ts - Code repeated 5 times
          3. File api.ts - Old code nobody uses

          Want me to clean them up? The app will still work exactly the same!"
```

### Safety promise for newbie:

```
🔒 SAFETY GUARANTEE:
   - The app will still work correctly as before
   - Only changes how it's written, not how it runs
   - Can revert to previous version if needed
```

---

## Stage 1: Scope & Safety

### 1.1. Define scope
*   "Which file/module would you like to clean up?"
    *   A) **1 specific file** (Safest)
    *   B) **1 module/feature** (Moderate)
    *   C) **Entire project** (Requires caution)

### 1.2. Safety commitment
*   "I guarantee: **Business logic stays 100% intact**. Only the writing style changes, not the behavior."

### 1.3. Backup Suggestion
*   "Before refactoring, would you like me to create a backup branch?"
*   If YES → `git checkout -b backup/before-refactor`

---

## Stage 2: Code Smell Detection

### 2.1. Structural Issues
*   **Long Functions:** Functions > 50 lines → Need splitting
*   **Deep Nesting:** If/else > 3 levels → Need flattening
*   **Large Files:** Files > 500 lines → Need module splitting
*   **God Objects:** Classes doing too many things → Need splitting

### 2.2. Naming Issues
*   **Vague Names:** `data`, `obj`, `temp`, `x` → Need clear naming
*   **Inconsistent Style:** `getUserData` vs `fetch_user_info` → Need standardization

### 2.3. Duplication
*   **Copy-Paste Code:** Repeated code blocks → Extract into shared functions
*   **Similar Logic:** Similar logic with different data → Need generalization

### 2.4. Outdated Code
*   **Dead Code:** Code never called → Remove
*   **Commented Code:** Commented-out code → Remove (Git already stores it)
*   **Unused Imports:** Imported but unused → Remove

### 2.5. Missing Best Practices
*   **No Types:** Plain JavaScript → Add TypeScript types
*   **No Error Handling:** Missing try-catch → Add
*   **No JSDoc:** Complex functions without comments → Add

---

## Stage 3: Refactoring Plan

### 3.1. List changes
*   "I'll make the following changes:"
    1.  Split `processOrder` function (120 lines) into 4 smaller functions
    2.  Rename variable `d` to `orderDate`
    3.  Remove 3 unused imports
    4.  Add JSDoc for public functions

### 3.2. Ask for approval
*   "Are you OK with this plan?"

---

## Stage 4: Safe Execution

### 4.1. Micro-Steps
*   Execute small steps one at a time (don't change many things at once).
*   After each step, verify the code still works.

### 4.2. Pattern Application
*   **Extract Function:** Extract logic into separate functions
*   **Rename Variable:** Rename for clarity
*   **Remove Dead Code:** Delete unused code
*   **Add Types:** Add TypeScript annotations
*   **Add Comments:** Add JSDoc for complex functions

### 4.3. Format & Lint
*   Run Prettier to format code.
*   Run ESLint to check for errors.

---

## Stage 5: Quality Assurance

### 5.1. Before/After Comparison
*   "Before: [Old code]"
*   "After: [New code]"
*   "Logic unchanged, just easier to read."

### 5.2. Test Suggestion
*   "I recommend running `/test-awf` to confirm the logic is unaffected."

---

## Stage 6: Handover

1.  Report: "Cleaned up [X] files."
2.  List:
    *   "Split [Y] large functions"
    *   "Renamed [Z] variables"
    *   "Removed [W] lines of unused code"
3.  Recommendation: "Run `/test-awf` to make sure nothing broke."

---

## ⚠️ NEXT STEPS (Numbered Menu):
```
1️⃣ Run /test-awf to verify logic is unaffected
2️⃣ Got errors? /rollback-awf to revert
3️⃣ All good? /save-brain-wm to save changes
```
