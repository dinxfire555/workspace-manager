#!/bin/bash
# Workspace Manager - Bash converter for Antigravity
# Usage: bash convert-to-antigravity.sh <source_dir> <target_path>
# Example: bash convert-to-antigravity.sh ./setup-wm ~/.gemini/config

set -e

SOURCE_DIR="${1:?Missing source directory}"
TARGET_PATH="${2:?Missing target path}"

WORKFLOWS_DIR="$TARGET_PATH/global_workflows"
SKILLS_DIR="$TARGET_PATH/skills"
SCHEMAS_DIR="$TARGET_PATH/schemas"
TEMPLATES_DIR="$TARGET_PATH/templates"
GEMINI_FILE="$HOME/.gemini/GEMINI.md"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

# Copy workflows -> global_workflows/
if [ -d "$SOURCE_DIR/workflows" ]; then
    mkdir -p "$WORKFLOWS_DIR"
    count=0
    for f in "$SOURCE_DIR/workflows/"*.md; do
        [ -f "$f" ] || continue
        cp "$f" "$WORKFLOWS_DIR/$(basename "$f")"
        ((count++))
    done
    echo -e "   ${GREEN}Converted $count workflows to $WORKFLOWS_DIR${NC}"
else
    echo -e "   ${YELLOW}No workflows directory at $SOURCE_DIR/workflows${NC}"
fi

# Copy skills -> skills/
if [ -d "$SOURCE_DIR/skills" ]; then
    mkdir -p "$SKILLS_DIR"
    count=0
    for d in "$SOURCE_DIR/skills/"*/; do
        [ -d "$d" ] || continue
        skill_name=$(basename "$d")
        if [ -f "$d/SKILL.md" ]; then
            mkdir -p "$SKILLS_DIR/$skill_name"
            cp "$d/SKILL.md" "$SKILLS_DIR/$skill_name/SKILL.md"
            ((count++))
        fi
    done
    echo -e "   ${GREEN}Converted $count skills to $SKILLS_DIR${NC}"
fi

# Copy schemas -> schemas/
if [ -d "$SOURCE_DIR/schemas" ]; then
    mkdir -p "$SCHEMAS_DIR"
    count=0
    for f in "$SOURCE_DIR/schemas/"*.json; do
        [ -f "$f" ] || continue
        cp "$f" "$SCHEMAS_DIR/$(basename "$f")"
        ((count++))
    done
    echo -e "   ${GREEN}Converted $count schemas to $SCHEMAS_DIR${NC}"
fi

# Copy templates -> templates/
if [ -d "$SOURCE_DIR/templates" ]; then
    mkdir -p "$TEMPLATES_DIR"
    shopt -s dotglob 2>/dev/null || true
    cp -r "$SOURCE_DIR/templates/"* "$TEMPLATES_DIR/" 2>/dev/null || true
    shopt -u dotglob 2>/dev/null || true
    echo -e "   ${GREEN}Templates copied to $TEMPLATES_DIR${NC}"
fi

# Update GEMINI.md
NOW=$(date '+%Y-%m-%d %H:%M:%S')
WM_SECTION="## Workspace Manager (installed $NOW)

### Available Commands
- /init-wm — Initialize workspace
- /sync-awf — Sync AWF workflows + skills
- /sync-context — Sync context files
- /sync-tool — Sync tools from marketplace
- /save-brain-wm — Save session state
- /recap-wm — Resume session
- /help-wm — Show help

### Available Skills
Skills installed to \`$SKILLS_DIR\`.
See \`/help-wm\` for skill descriptions.

### Context Loading
- L0: 00_System/01_context/business-context.md
- L1: 00_System/01_context/domain-context.md
- L2: [workspace]/00_context/project-context.md"

mkdir -p "$(dirname "$GEMINI_FILE")"

if [ -f "$GEMINI_FILE" ] && grep -q "## Workspace Manager (installed" "$GEMINI_FILE" 2>/dev/null; then
    # Remove existing WM section (from ## Workspace Manager to next ## or EOF)
    awk '/^## Workspace Manager \(installed/{skip=1; next} /^## /{skip=0} !skip' "$GEMINI_FILE" > "${GEMINI_FILE}.tmp"
    printf '\n%s\n' "$WM_SECTION" >> "${GEMINI_FILE}.tmp"
    mv "${GEMINI_FILE}.tmp" "$GEMINI_FILE"
    echo -e "   ${GREEN}Updated GEMINI.md: $GEMINI_FILE${NC}"
else
    printf '%s\n' "$WM_SECTION" >> "$GEMINI_FILE"
    echo -e "   ${GREEN}Created GEMINI.md section: $GEMINI_FILE${NC}"
fi

echo -e "${GRAY}Conversion complete for target: Antigravity${NC}"
