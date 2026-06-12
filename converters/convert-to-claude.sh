#!/bin/bash
# Workspace Manager - Bash converter for Claude Code
# Usage: bash convert-to-claude.sh <source_dir> <target_path>
# Example: bash convert-to-claude.sh ./setup-wm ~/.claude

set -e

SOURCE_DIR="${1:?Missing source directory}"
TARGET_PATH="${2:?Missing target path}"

COMMANDS_DIR="$TARGET_PATH/commands"
SKILLS_DIR="$TARGET_PATH/skills"
SCHEMAS_DIR="$TARGET_PATH/schemas"
TEMPLATES_DIR="$TARGET_PATH/templates"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

# Copy workflows -> commands/
if [ -d "$SOURCE_DIR/workflows" ]; then
    mkdir -p "$COMMANDS_DIR"
    count=0
    for f in "$SOURCE_DIR/workflows/"*.md; do
        [ -f "$f" ] || continue
        cp "$f" "$COMMANDS_DIR/$(basename "$f")"
        ((count++))
    done
    echo -e "   ${GREEN}Converted $count workflows to $COMMANDS_DIR${NC}"
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

# Copy templates -> templates/ (redundant but ensures completeness)
if [ -d "$SOURCE_DIR/templates" ]; then
    mkdir -p "$TEMPLATES_DIR"
    shopt -s dotglob 2>/dev/null || true
    cp -r "$SOURCE_DIR/templates/"* "$TEMPLATES_DIR/" 2>/dev/null || true
    shopt -u dotglob 2>/dev/null || true
    echo -e "   ${GREEN}Templates copied to $TEMPLATES_DIR${NC}"
fi

echo -e "${GRAY}Conversion complete for target: Claude Code${NC}"
