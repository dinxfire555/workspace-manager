# Workspace Manager v1.0.3

**Enterprise AI Workspace Deployment Tool** — One command to deploy synchronized AI workflows, skills, and context across your entire organization.

[![Version](https://img.shields.io/badge/version-1.0.3-blue)](VERSION)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## Quick Install

### Step 1: Clone and install

**Windows (PowerShell):**

```powershell
git clone https://gitlab.fci.vn/dungnt261/workspace-manager.git
cd workspace-manager
.\install.ps1
```

**macOS / Linux (Bash):**

```bash
git clone https://gitlab.fci.vn/dungnt261/workspace-manager.git
cd workspace-manager
./install.sh
```

> ⚠️ **Windows ExecutionPolicy?** Run first: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

> The installer auto-detects local files and your CLI/IDE target.

**GitLab/GitHub users:** Replace the clone URL with your GitLab/GitHub repo URL.

### Step 2: Initialize workspace

**In your workspace root folder:**

- Run `/init-wm`
- The wizard auto-loads `.wm-env.json` from installed templates and validates connections.
- You are only prompted when a URL is unreachable — enter corrections if needed.
- Enter the requested personal info (Name, Email, Unit, Department, Role, Product) to continue.

(See [docs/QUICKSTART.md](docs/QUICKSTART.md) for details)

---

## What is Workspace Manager?

Workspace Manager (WM) is a Git-based CLI tool that helps organizations deploy AI-assisted development consistently. It provides:

- **Centralized Configuration** — `.wm-env.json` for all repository URLs
- **Layered Context** — L0 (Business) → L1 (Domain) → L2 (Project) context hierarchy
- **Role-Based Workspaces** — Auto-generated folder structures per role (Dev, PO, BA, etc.)
- **AWF Workflow Framework** — 17 structured AI development workflows (plan → deploy)
- **Tool Marketplace** — Sync tools from FCI Skills repository
- **Multi-Platform** — Claude Code, Opencode, Codex CLI, Antigravity
- **Multi-Role Support** — Comma-separated roles (e.g. "PO, BA, Tester") union folders automatically
- **Smart Workspace Creation** — `create-workspace.ps1` with role normalization, remote/local template fallback

---

## v2 New Features

| Feature              | Description                                                                              |
| -------------------- | ---------------------------------------------------------------------------------------- |
| `.wm-env.json`     | Centralized config — set GitHub/GitLab URLs once, all workflows use them                |
| 4 System Folders     | `00_System/` now includes `policy/`, `prompts/`, `standards/`, `tool-configs/` |
| AWF Separation       | AWF workflows/skills in dedicated folders — install on-demand via `/sync-awf`         |
| 4-Target Support     | Claude Code, Opencode, Codex CLI, Antigravity converters                                 |
| `wm-folder-naming` | Consistent folder (00_, 10_) and file (ISO 8601) naming conventions                      |
| Full English         | All code, workflows, and skills in English (Vietnamese docs available)                   |

---

## Architecture

```
workspace-manager/                  # The tool itself (this repo)
├── .wm-env.json                    # Centralized config template
├── install.ps1 / install.sh        # Installers (run from cloned repo)
├── workflows/                      # 10 WM workflows (init, sync, save, ...)
├── awf-workflows/                  # 17 AWF workflows (plan, code, test, ...)
├── skills/                         # 4 WM skills
│   └── awf-skills/                 # 6 AWF skills (on-demand via /sync-awf)
├── converters/                     # 4 target converters
├── scripts/                        # Utility scripts
├── schemas/                        # JSON schemas
└── templates/                      # Template files (incl. .wm-env.json config)
```

### Your Workspace After `/init-wm`

```
your-project/
├── .wm-env.json                    # Your config (GitHub/GitLab URLs)
├── AGENTS.md / CLAUDE.md           # AI persona file
├── 00_System/
│   ├── 01_context/                 # L0 + L1 context files
│   ├── 02_policies/                # Unit/Department policies
│   ├── 03_prompts/                 # Shared prompt templates
│   ├── 04_standards/               # Architecture standards
│   └── 05_tool-configs/            # Tool configurations
├── 10_YourProduct-wp/              # Your workspace (hub-synced)
│   ├── 00_context/                 # L2 project context
│   ├── 00_temp/                    # feature-context.md template
│   ├── src/ api/ models/ ...       # Role-based folders (auto-created)
│   └── docs/ tests/ ...            # (union for multi-role)
└── .brain/                         # Session memory
```

---

## Supported Targets

| Target                | Path                    | Workflows Dir         | Converter                      |
| --------------------- | ----------------------- | --------------------- | ------------------------------ |
| **Claude Code** | `~/.claude/`          | `commands/`         | `convert-to-claude.ps1`      |
| **Opencode**    | `~/.config/opencode/` | `awf-workflows/`    | `convert-to-opencode.ps1`    |
| **Codex CLI**   | `~/.codex/`           | `commands/`         | `convert-to-codex.ps1`       |
| **Antigravity** | `~/.gemini/config/`   | `global_workflows/` | `convert-to-antigravity.ps1` |

> Only targets detected on your system are shown during install.

---

## Commands Reference

### Workspace Manager (Always Available)

| Command                  | Description                                  |
| ------------------------ | -------------------------------------------- |
| `/init-wm`             | Initialize workspace — first-run wizard     |
| `/new-workspace`       | Create hub-synced workspace (prefix `10_`) |
| `/new-workspace-local` | Create local-only workspace (prefix `11_`) |
| `/update-persona`      | Update AGENTS.md / CLAUDE.md persona         |
| `/sync-awf`            | Download AWF workflows + skills              |
| `/sync-context`        | Sync context files from context-hub          |
| `/sync-tool`           | Sync tools from FCI Skills marketplace       |
| `/save-brain-wm`       | Save session state                           |
| `/recap-wm`            | Resume previous session                      |
| `/help-wm`             | Show help + command reference                |

### AWF Workflows (After `/sync-awf`)

| Phase      | Command             | Description                      |
| ---------- | ------------------- | -------------------------------- |
| Plan       | `/plan-awf`       | Feature design + planning        |
| Design     | `/design-awf`     | Technical design                 |
| Visualize  | `/visualize-awf`  | UI/UX mockup                     |
| Code       | `/code-awf`       | Write code to specification      |
| Run        | `/run-awf`        | Launch application               |
| Test       | `/test-awf`       | Run tests                        |
| Debug      | `/debug-awf`      | Find and fix bugs                |
| Audit      | `/audit-awf`      | Code + security audit            |
| Deploy     | `/deploy-awf`     | Deploy to production             |
| Refactor   | `/refactor-awf`   | Code cleanup                     |
| Review     | `/review-awf`     | Project overview                 |
| Rollback   | `/rollback-awf`   | Rollback changes                 |
| Brainstorm | `/brainstorm-awf` | Brainstorm ideas into concepts   |
| Customize  | `/customize-awf`  | Customize AI behavior settings   |
| Help       | `/help-awf`       | AWF-specific help                |
| Next       | `/next-awf`       | Smart next-step suggestion       |
| Init       | `/init-awf`       | Initialize AWF project structure |

---

## Context Layers

Workspace Manager uses a 4-layer context architecture:

| Layer        | File                                          | Scope             | Mutability                |
| ------------ | --------------------------------------------- | ----------------- | ------------------------- |
| **L0** | `00_System/01_context/business-context.md`  | Enterprise-wide   | 🔒 Immutable              |
| **L1** | `00_System/01_context/domain-context.md`    | Unit/Department   | Must not conflict with L0 |
| **L2** | `[workspace]/00_context/project-context.md` | Product/Project   | Delta context only        |
| **L3** | `.brain/brain.json`                         | Session knowledge | Auto-generated            |

**Gene Flow:** L2 → L1 → L0 compliance is always enforced.

---

## `.wm-env.json` Configuration

```json
{
  "version": "1.0.3",
  "context_hub": {
    "type": "gitlab",
    "raw_url": "https://raw.githubusercontent.com/your-org/context-hub/main",
    "project_url": "https://gitlab.fci.vn/internal/context-hub",
    "branch": "main",
    "unit": "ai",
    "department": "genai-center"
  },
  "fci_skills": {
    "type": "gitlab",
    "raw_url": "https://raw.githubusercontent.com/your-org/fci-skills/main",
    "project_url": "https://gitlab.fci.vn/internal/fci-skills",
    "branch": "master"
  },
  "workspace_manager": {
    "type": "gitlab",
    "raw_url": "https://raw.githubusercontent.com/your-org/workspace-manager/master",
    "project_url": "https://gitlab.fci.vn/dungnt261/workspace-manager",
    "branch": "master"
  }
}
```

- **type**: `github` or `gitlab`
- **GitLab auth**: Set `$env:WM_GITLAB_TOKEN` for private repos
- Created during `/init-wm` — edit anytime

---

## Folder & File Naming

| Aspect               | Rule                               | Example                        |
| -------------------- | ---------------------------------- | ------------------------------ |
| System folders       | `00_` prefix                     | `00_System/`                 |
| Hub-synced workspace | `10_` prefix + `-wp` suffix    | `10_OmniSupport-wp/`         |
| Local workspace      | `11_`+ prefix + `-wp` suffix   | `11_MyProject-wp/`           |
| Date-based files     | `YYYY-MM-DD-description-vNN.ext` | `2026-06-09-report-v01.md`   |
| User override        | Explicit name → use as-is         | User says `src/` → `src/` |

---

## Quick Start Flow

```
Clone + Install    Init              Sync AWF        Plan            Code
~~~~~~~~~~~~~~     ~~~~              ~~~~~~~~        ~~~~            ~~~~
git clone ...  →   /init-wm      →   /sync-awf  →   /plan-awf  →   /code-awf
.\install.ps1      (auto-config)     (on-demand)     (feature)       (implement)
```

[📖 Full Quick Start Guide →](docs/QUICKSTART.md)

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

See [SECURITY.md](SECURITY.md) for security policies.

---

## Documentation

| Document                               | Language   |
| -------------------------------------- | ---------- |
| [README.md](README.md)                    | English    |
| [README-vi.md](README-vi.md)              | Vietnamese |
| [QUICKSTART.md](docs/QUICKSTART.md)       | English    |
| [QUICKSTART-vi.md](docs/QUICKSTART-vi.md) | Vietnamese |

---

## License

MIT — Copyright (c) 2026 FPT Smart Cloud — GenAI Center
