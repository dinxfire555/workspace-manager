#!/bin/bash
# Workspace Manager Installer for macOS / Linux
# One-line: curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/workspace-manager/main/install.sh | bash

set -e

REPO_BASE="https://gitlab.fci.vn/dungnt261/workspace-manager/-/raw/master"
REPO_WORKFLOWS="$REPO_BASE/workflows"
REPO_SKILLS="$REPO_BASE/skills"
REPO_SCHEMAS="$REPO_BASE/schemas"
REPO_TEMPLATES="$REPO_BASE/templates"
REPO_CONVERTERS="$REPO_BASE/converters"

# Auth token for private repos (GitLab: ?private_token=; GitHub: ignored)
WM_TOKEN="${WM_GITLAB_TOKEN:+?private_token=$WM_GITLAB_TOKEN}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Local repo detection (same logic as install.ps1)
IS_LOCAL_REPO=false
if [ -n "${BASH_SOURCE[0]}" ] && [ "${BASH_SOURCE[0]}" != "bash" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/skills/wm-merge-context/SKILL.md" ]; then
        IS_LOCAL_REPO=true
    fi
fi

# Detect version — read local VERSION file if available, otherwise fetch remote
if [ "$IS_LOCAL_REPO" = true ] && [ -f "$SCRIPT_DIR/VERSION" ]; then
    WM_VERSION=$(cat "$SCRIPT_DIR/VERSION" | tr -d '\r\n ')
else
    WM_VERSION=$(curl -fsSL "$REPO_BASE/VERSION$WM_TOKEN" 2>/dev/null || echo "1.0.0")
    WM_VERSION=$(echo "$WM_VERSION" | tr -d '\r\n ')
fi

WORKING_DIR=$(pwd)
SETUP_DIR="$WORKING_DIR/setup-wm"

# Helper: copy from local repo or download from remote
copy_or_download() {
    local rel_path="$1"
    local dest="$2"
    local label="$3"

    # Try local first
    if [ "$IS_LOCAL_REPO" = true ] && [ -f "$SCRIPT_DIR/$rel_path" ]; then
        mkdir -p "$(dirname "$dest")"
        cp "$SCRIPT_DIR/$rel_path" "$dest"
        echo -e "      ${GREEN}✅ $label (local)${NC}"
        return 0
    fi

    # Fallback to remote download
    if curl -fsSL "$REPO_BASE/$rel_path$WM_TOKEN" -o "$dest" 2>/dev/null; then
        echo -e "      ${GREEN}✅ $label${NC}"
        return 0
    else
        echo -e "      ${YELLOW}⚠️  $label (not found)${NC}"
        return 1
    fi
}

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     🚀 Workspace Manager v$WM_VERSION                           ║${NC}"
echo -e "${CYAN}║     Enterprise AI Workspace Deployment Tool              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ═══════════════════════════════════════════════════
# STEP 1: Detect Targets
# ═══════════════════════════════════════════════════
echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Step 1/7: Detect CLI/IDE Target${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

declare -a DETECTED_TARGETS
declare -a DETECTED_NAMES
declare -a DETECTED_IDS

check_target() {
    local path="$1"
    local name="$2"
    local id="$3"

    # Only show targets with available converters
    local available=("claude" "opencode" "codex" "antigravity")
    local found=false
    for aid in "${available[@]}"; do
        if [ "$id" == "$aid" ]; then found=true; break; fi
    done

    if [ "$found" = true ] && [ -d "$path" ]; then
        echo -e "   ${GREEN}✅ Detected: $name at $path${NC}"
        DETECTED_TARGETS+=("$path")
        DETECTED_NAMES+=("$name")
        DETECTED_IDS+=("$id")
    fi
}

check_target "$HOME/.claude" "Claude Code" "claude"
check_target "$HOME/.config/opencode" "Opencode" "opencode"
check_target "$HOME/.codex" "Codex CLI" "codex"
check_target "$HOME/.gemini/config" "Antigravity" "antigravity"

if [ ${#DETECTED_TARGETS[@]} -eq 0 ]; then
    echo -e "   ${YELLOW}ℹ️  No target detected. Defaulting to Claude Code.${NC}"
    DETECTED_TARGETS=("$HOME/.claude")
    DETECTED_NAMES=("Claude Code")
    DETECTED_IDS=("claude")
fi

SELECTED_TARGETS=("${DETECTED_TARGETS[@]}")
SELECTED_NAMES=("${DETECTED_NAMES[@]}")
SELECTED_IDS=("${DETECTED_IDS[@]}")
echo -e "   ${GREEN}✅ Using ${#SELECTED_TARGETS[@]} target(s)${NC}"

mkdir -p "$SETUP_DIR"

# ═══════════════════════════════════════════════════
# STEP 2: Download Skills
# ═══════════════════════════════════════════════════
echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Step 2/7: Download Default Skills${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SKILLS_DIR="$SETUP_DIR/skills"
mkdir -p "$SKILLS_DIR"

SKILL_LIST=(
    "wm-merge-context" "wm-context-fetcher" "wm-tool-recommender" "wm-folder-naming"
)

for skill in "${SKILL_LIST[@]}"; do
    skill_dir="$SKILLS_DIR/$skill"
    mkdir -p "$skill_dir"
    copy_or_download "skills/$skill/SKILL.md" "$skill_dir/SKILL.md" "$skill" || true
done

# ═══════════════════════════════════════════════════
# STEP 3: Download Workflows
# ═══════════════════════════════════════════════════
echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Step 3/7: Download Workflows${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

WORKFLOWS_DIR="$SETUP_DIR/workflows"
mkdir -p "$WORKFLOWS_DIR"

MAIN_WORKFLOWS=(
    "init-wm.md" "new-workspace.md" "new-workspace-local.md"
    "sync-context.md" "sync-tool.md" "sync-awf.md" "update-persona.md"
    "save-brain-wm.md" "recap-wm.md" "help-wm.md"
)

for wf in "${MAIN_WORKFLOWS[@]}"; do
    copy_or_download "workflows/$wf" "$WORKFLOWS_DIR/$wf" "$wf" || true
done

echo -e "   ${GRAY}AWF workflows are available via /sync-awf after workspace init${NC}"
echo -e "   ${GREEN}📦 Workflows downloaded to $WORKFLOWS_DIR${NC}"

# ═══════════════════════════════════════════════════
# STEP 4: Download Schemas
# ═══════════════════════════════════════════════════
echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Step 4/7: Download Schemas${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SCHEMAS_DIR="$SETUP_DIR/schemas"
mkdir -p "$SCHEMAS_DIR"

for s in brain.schema.json session.schema.json preferences.schema.json; do
    copy_or_download "schemas/$s" "$SCHEMAS_DIR/$s" "$s" || true
done

# ═══════════════════════════════════════════════════
# STEP 5: Download Templates
# ═══════════════════════════════════════════════════
echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Step 5/7: Download Templates${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

TEMPLATES_DIR="$SETUP_DIR/templates"
mkdir -p "$TEMPLATES_DIR"

for t in brain.example.json session.example.json preferences.example.json AGENTS.md.template CLAUDE.md.template role-tools.json role-folders.json feature-context.md .wm-env.json; do
    copy_or_download "templates/$t" "$TEMPLATES_DIR/$t" "$t" || true
done

# ═══════════════════════════════════════════════════
# STEP 6: Convert Resources
# ═══════════════════════════════════════════════════
echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Step 6/7: Download Scripts + Convert Resources${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

SCRIPTS_DIR="$SETUP_DIR/scripts"
mkdir -p "$SCRIPTS_DIR"

for sf in fetch-context.ps1 fetch-tools.ps1 install-tool.ps1 compare-skills.ps1 create-workspace.ps1; do
    copy_or_download "scripts/$sf" "$SCRIPTS_DIR/$sf" "$sf" || true
done

CONVERTERS_DIR="$SETUP_DIR/converters"
mkdir -p "$CONVERTERS_DIR"

CONVERTER_FILES="target-mapping.json convert-to-opencode.ps1 convert-to-claude.ps1 convert-to-codex.ps1 convert-to-antigravity.ps1 convert-to-claude.sh convert-to-opencode.sh convert-to-codex.sh convert-to-antigravity.sh"
for cf in $CONVERTER_FILES; do
    copy_or_download "converters/$cf" "$CONVERTERS_DIR/$cf" "$cf" || true
done

echo -e "   ${YELLOW}ℹ️  Bash converters handle config registration on macOS/Linux.${NC}"
echo ""

for i in "${!SELECTED_TARGETS[@]}"; do
    TARGET_PATH="${SELECTED_TARGETS[$i]}"
    TARGET_NAME="${SELECTED_NAMES[$i]}"
    TARGET_ID="${SELECTED_IDS[$i]}"
    echo -e "   ${CYAN}🎯 Converting for target: $TARGET_NAME${NC}"

    # Copy scripts (pre-converter)
    TARGET_SCRIPTS="$TARGET_PATH/scripts"
    if [ -d "$SCRIPTS_DIR" ]; then
        mkdir -p "$TARGET_SCRIPTS"
        cp -r "$SCRIPTS_DIR"/* "$TARGET_SCRIPTS" 2>/dev/null || true
        echo -e "      ${GREEN}✅ Scripts copied${NC}"
    fi

    # Copy templates (pre-converter)
    TARGET_TEMPLATES="$TARGET_PATH/templates"
    if [ -d "$TEMPLATES_DIR" ]; then
        mkdir -p "$TARGET_TEMPLATES"
        shopt -s dotglob 2>/dev/null || true
        cp -r "$TEMPLATES_DIR"/* "$TARGET_TEMPLATES" 2>/dev/null || true
        shopt -u dotglob 2>/dev/null || true
        echo -e "      ${GREEN}✅ Templates copied${NC}"
    fi

    # Run bash converter
    CONVERTER="$CONVERTERS_DIR/convert-to-$TARGET_ID.sh"
    if [ -f "$CONVERTER" ]; then
        bash "$CONVERTER" "$SETUP_DIR" "$TARGET_PATH"
        echo -e "      ${GREEN}✅ Conversion complete: $TARGET_NAME${NC}"
    else
        echo -e "      ${YELLOW}⚠️  No bash converter for $TARGET_NAME${NC}"
    fi
done

# ═══════════════════════════════════════════════════
# STEP 7: Save Version
# ═══════════════════════════════════════════════════
echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Step 7/7: Save Version${NC}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

for i in "${!SELECTED_TARGETS[@]}"; do
    TARGET_PATH="${SELECTED_TARGETS[$i]}"
    TARGET_NAME="${SELECTED_NAMES[$i]}"
    VERSION_FILE="$TARGET_PATH/wm-version"
    mkdir -p "$(dirname "$VERSION_FILE")"
    cat > "$VERSION_FILE" << EOF
Workspace Manager v$WM_VERSION
Installed: $(date '+%Y-%m-%d %H:%M:%S')
Target: $TARGET_NAME
Repo: $REPO_BASE
EOF
    echo -e "   ${GREEN}✅ Version saved: $VERSION_FILE${NC}"
done

# ═══════════════════════════════════════════════════
# COMPLETE
# ═══════════════════════════════════════════════════
echo ""
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🎉 WORKSPACE MANAGER INSTALLATION COMPLETE!${NC}"
echo -e "${CYAN}📦 Version: $WM_VERSION${NC}"
echo -e "${GREEN}📂 Resources downloaded to: $SETUP_DIR${NC}"
echo ""
echo -e "${CYAN}👉 To initialize your workspace, open your IDE and run: /init-wm${NC}"
echo -e "👉 Quick start: https://github.com/YOUR_ORG/workspace-manager${NC}"
echo ""
