# Quick Start Guide — Works in 5 Minutes

Get started with Workspace Manager v2 in under 5 minutes.

---

## Prerequisites

- **Git** 2.x or later
- **PowerShell 5.1+** (Windows) or **Bash** (macOS/Linux)
- GitHub account

---

## Step 1: Install (30 seconds)

### Windows (PowerShell):

git clone https://gitlab.fci.vn/dungnt261/workspace-manager.git
cd workspace-manager
.\install.ps1

> ⚠️ ExecutionPolicy blocked? Run: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### macOS / Linux (Bash):

git clone https://gitlab.fci.vn/dungnt261/workspace-manager.git
cd workspace-manager
./install.sh

The installer detects your CLI/IDE (Claude Code, Opencode, Codex, Antigravity) and sets up workflows, skills, schemas, templates, and scripts.

**GitLab/GitHub users:** Replace the clone URL with your GitLab/GitHub repo URL. The template config is auto-loaded.

---

## Step 2: Initialize Workspace (2 minutes)

Open your project folder in your IDE and run:

```
/init-wm
```

The wizard auto-loads `.wm-env.json` from your installed templates and validates all connections. It only prompts when a URL is unreachable.

The wizard asks:

1. Validates context-hub, fci-skills, workspace-manager — prompts for corrections if needed
2. Your name and email
3. Your Unit (e.g., "AI Division")
4. Your Department (e.g., "GenAI Center")
5. Your Role (e.g., "Dev BE", "PO", "BA", "Tester", "SM" — full list: PO, PM, BA, Dev FE, Dev BE, Tester, SM, DevOps, Designer, Sales, Operations, Other)

- For multiple roles, enter comma-separated: "PO, BA, Tester" (folders union automatically)

6. Your Product (e.g., "Omni Support")

Workspace Manager automatically:

- Creates `.wm-env.json` with your config
- Downloads L0 + L1 context files
- Creates `00_System/` with policy, prompts, standards, tool-configs
- Creates your workspace folder (`10_YourProduct-wp/`)
- Creates role-based folders automatically (union for multi-role)
- Downloads feature-context.md template to `temp/`
- Sets up persona file (AGENTS.md or CLAUDE.md)

---

## Step 3: Sync AWF Workflows (30 seconds)

AWF workflows (plan, code, test, deploy, etc.) are not installed by default. Download them on-demand:

```
/sync-awf
```

This downloads 17 AWF workflows + 6 AWF skills and installs them for your CLI/IDE.

---

## Step 4: Sync Team Tools (30 seconds)

Download tools recommended for your role from FCI Skills marketplace:

```
/sync-tool
```

The workflow compares installed tools against the marketplace, recommends tools for your role, and installs with one click.

---

## Step 5: Verify (30 seconds)

```bash
# Check context files
ls 00_System/01_context/
# Expected: business-context.md  domain-context.md

# Check system folders
ls 00_System/
# Expected: 01_context/  02_policies/  03_prompts/  04_standards/  05_tool-configs/

# Check your workspace
ls 10_*-wp/

# Check persona
ls AGENTS.md   # or CLAUDE.md
```

---

## Common Next Steps

| Goal             | Command            |
| ---------------- | ------------------ |
| Save session     | `/save-brain-wm` |
| Resume later     | `/recap-wm`      |
| See all commands | `/help-wm`       |
| Start planning   | `/plan-awf`      |
| Start coding     | `/code-awf`      |
| Sync context     | `/sync-context`  |

---

## Working on a New Feature

When starting a new feature, use the feature context template to give AI full awareness of your requirements:

```bash
# 1. Copy the template from your workspace
cp 10_YourProduct-wp/00_temp/feature-context.md docs/features/my-feature.md

# 2. Fill in feature details (name, description, scope, acceptance criteria)
# 3. Prompt AI with the file
```

> "Read docs/features/my-feature.md and help implement this feature"

The template is auto-copied to `[workspace]/00_temp/` during workspace creation. Place filled files anywhere in your project — AI reads on demand.

---

## Troubleshooting

| Symptom                              | Fix                                                                                                                                                                                                   |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `install.ps1` blocked              | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`                                                                                                                                        |
| `/init-wm` not found               | Run install script again                                                                                                                                                                              |
| Context files empty                  | Run `/sync-context` or re-run `/init-wm`                                                                                                                                                          |
| `/sync-awf` says "not initialized" | Run `/init-wm` first                                                                                                                                                                                |
| AWF commands not found               | Run `/sync-awf` after `/init-wm`                                                                                                                                                                  |
| GitLab token needed                  | Set `$env:WM_GITLAB_TOKEN` environment variable                                                                                                                                                     |
| Role folders not created             | Verify role name matches valid list (PO, PM, BA, Dev FE, Dev BE, Tester, SM, DevOps, Designer, Sales, Operations). Re-run `/init-wm` to recreate workspace via `create-workspace.ps1` automation. |
| feature-context.md missing           | Script auto-downloads from context-hub. If offline, local template is used. Run `/sync-context` to update.                                                                                          |

---

## What You Get

```
your-project/
├── .wm-env.json                    # v2 centralized config
├── AGENTS.md / CLAUDE.md           # AI persona
├── 00_System/
│   ├── 01_context/                 # L0 + L1 context
│   ├── 02_policies/                # Unit policies
│   ├── 03_prompts/                 # Prompt templates
│   ├── 04_standards/               # Architecture standards
│   └── 05_tool-configs/            # Tool configs
├── 10_YourProduct-wp/              # Your workspace
│   ├── 00_context/                 # L2 project context
│   ├── 00_temp/                    # Feature context template
│   ├── src/ api/ models/ ...       # Role-based folders (auto)
│   ├── docs/                       # PO/PM/BA folders (auto)
│   └── tests/                      # Tester folders (auto)
└── .brain/                         # Session memory
```

---

## Getting Help

- Full docs: [README.md](../README.md)
- Report issues: https://gitlab.fci.vn/dungnt261/workspace-manager/-/issues
- AI help: run `/help-wm` in any workspace
