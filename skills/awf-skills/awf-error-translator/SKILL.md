---
name: awf-error-translator
description: >-
  Translate technical errors to human-friendly language. Keywords: error,
  translate, explain, help, fix, fail, broken, crash, bug.
  Activates on /debug, /code, /test when errors detected.
version: 1.0.0
---

# AWF Error Translator

Translate technical errors into everyday language for non-tech users.

## Trigger Conditions

**Post-hook for:** `/debug`, `/code`, `/test`

**When:** Error message detected in output

## Execution Logic

### Step 1: Detect Error

```
if output contains error patterns:
    → Activate translation
else:
    → Skip (no error)
```

### Step 2: Match & Translate

Match error against database, return human message + action.

### Step 3: Display

```
❌ Error: [human message]
💡 Suggestion: [action]
```

## Error Translation Database

### Database Errors

| Pattern | Human Message | Action |
|---------|---------------|--------|
| `ECONNREFUSED` | Database not running | Start PostgreSQL/MySQL |
| `ETIMEDOUT` | Database responding too slowly | Check network connection |
| `ER_ACCESS_DENIED` | Wrong database password | Check .env file |
| `relation .* does not exist` | Table does not exist | Run migration: `/run migrate` |
| `duplicate key` | Duplicate data | Check unique constraint |

### JavaScript/TypeScript Errors

| Pattern | Human Message | Action |
|---------|---------------|--------|
| `TypeError: Cannot read` | Reading a variable with no value | Check null/undefined |
| `ReferenceError` | Using undeclared variable | Check variable name |
| `SyntaxError` | Syntax error in code | Check brackets, semicolons |
| `Maximum call stack` | Infinite loop | Check stop condition |
| `Cannot find module` | Missing package | Run `npm install` |

### Network Errors

| Pattern | Human Message | Action |
|---------|---------------|--------|
| `fetch failed` | Cannot connect to server | Check URL and internet |
| `CORS` | Website blocking request | Configure CORS on server |
| `ERR_CERT` | SSL certificate error | Use HTTP instead of HTTPS (dev only) |
| `timeout` | Request taking too long | Increase timeout or check server |
| `ENOTFOUND` | Domain does not exist | Check URL again |

### Package Errors

| Pattern | Human Message | Action |
|---------|---------------|--------|
| `npm ERR!` | Package install failed | Delete node_modules, reinstall |
| `peer dep` | Version incompatibility | Update package.json |
| `EACCES` | No access permission | Run with sudo or fix permissions |
| `ENOSPC` | Disk full | Clean up disk |
| `gyp ERR!` | Native module build error | Install build tools |

### Test Errors

| Pattern | Human Message | Action |
|---------|---------------|--------|
| `Expected .* but received` | Test failed - wrong result | Fix code or update test |
| `Timeout` | Test running too long | Increase timeout or optimize |
| `before each hook` | Test setup error | Check beforeEach |
| `snapshot` | UI changed | Update snapshot if correct |
| `coverage` | Missing test coverage | Write more tests |

### Build Errors

| Pattern | Human Message | Action |
|---------|---------------|--------|
| `tsc.*error` | TypeScript error | Fix type errors |
| `ESLint` | Code style violation | Run lint fix |
| `Build failed` | Build failed | Read detailed log |
| `Out of memory` | Out of RAM | Increase memory limit |
| `FATAL ERROR` | Critical error | Restart and try again |

### Git Errors

| Pattern | Human Message | Action |
|---------|---------------|--------|
| `conflict` | Code conflict | Merge conflict manually |
| `rejected` | Push rejected | Pull before push |
| `detached HEAD` | Not on any branch | Checkout to a branch |
| `not a git repo` | Not a git repo yet | Run `git init` |

### Deploy Errors

| Pattern | Human Message | Action |
|---------|---------------|--------|
| `502 Bad Gateway` | Server not responding | Restart server |
| `503 Service` | Server overloaded | Scale up resources |
| `permission denied` | No deploy permission | Check credentials |
| `quota exceeded` | Quota exceeded | Upgrade plan |

## Output Format

```
🔍 Translating error...

❌ Error: [human_message]
   └─ Source: [original_error_snippet]

💡 Suggestion: [action]
   └─ Or run: /debug to learn more

────────────────────────────────
```

## Fallback

If no pattern matches:
```
❌ Error: Something went wrong
💡 Suggestion: Run /debug for detailed analysis
```

## Performance

- Translation: < 100ms
- Pattern matching: Simple regex
- No external API calls

## Security

- Sanitize error messages (remove credentials, paths)
- Never expose sensitive info in translations
