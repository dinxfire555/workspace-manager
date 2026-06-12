#!/bin/bash
# Workspace Manager - Bash converter for Codex CLI
# Usage: bash convert-to-codex.sh <source_dir> <target_path>
# Example: bash convert-to-codex.sh ./setup-wm ~/.codex
# Requires: jq (for config registration)

set -e

SOURCE_DIR="${1:?Missing source directory}"
TARGET_PATH="${2:?Missing target path}"

COMMANDS_DIR="$TARGET_PATH/commands"
SKILLS_DIR="$TARGET_PATH/skills"
SCHEMAS_DIR="$TARGET_PATH/schemas"
TEMPLATES_DIR="$TARGET_PATH/templates"
CONFIG_FILE="$TARGET_PATH/config.json"

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

# Copy templates -> templates/
if [ -d "$SOURCE_DIR/templates" ]; then
    mkdir -p "$TEMPLATES_DIR"
    shopt -s dotglob 2>/dev/null || true
    cp -r "$SOURCE_DIR/templates/"* "$TEMPLATES_DIR/" 2>/dev/null || true
    shopt -u dotglob 2>/dev/null || true
    echo -e "   ${GREEN}Templates copied to $TEMPLATES_DIR${NC}"
fi

# Config registration (requires jq)
if ! command -v jq &> /dev/null; then
    echo -e "   ${YELLOW}⚠️  jq not found. Files copied but config NOT updated.${NC}"
    echo -e "   ${YELLOW}   Install jq: sudo apt install jq  (Ubuntu/Debian)${NC}"
    echo -e "   ${YELLOW}   Install jq: brew install jq       (macOS)${NC}"
    echo -e "   ${YELLOW}   Then re-run: bash convert-to-codex.sh $SOURCE_DIR $TARGET_PATH${NC}"
else
    # Initialize config if missing
    if [ ! -f "$CONFIG_FILE" ]; then
        echo '{}' > "$CONFIG_FILE"
    fi

    # Ensure skills and commands sections exist
    config=$(jq 'if .skills == null then .skills = {} else . end | if .commands == null then .commands = {} else . end' "$CONFIG_FILE")

    # Register all skills from target skills directory
    if [ -d "$SKILLS_DIR" ]; then
        for sd in "$SKILLS_DIR/"*/; do
            [ -d "$sd" ] || continue
            skill_name=$(basename "$sd")
            skill_md="$sd/SKILL.md"
            if [ -f "$skill_md" ]; then
                config=$(echo "$config" | jq --arg n "$skill_name" --arg p "$skill_md" \
                    '.skills[$n] = {"path": $p}')
            fi
        done
    fi

    # Register all workflows from target commands directory
    if [ -d "$COMMANDS_DIR" ]; then
        for wf in "$COMMANDS_DIR/"*.md; do
            [ -f "$wf" ] || continue
            wf_name=$(basename "$wf" .md)
            config=$(echo "$config" | jq --arg n "$wf_name" --arg p "$wf" \
                '.commands[$n] = {"path": $p}')
        done
    fi

    echo "$config" > "$CONFIG_FILE"
    echo -e "   ${GREEN}Updated config: $CONFIG_FILE${NC}"
fi

echo -e "${GRAY}Conversion complete for target: Codex CLI${NC}"
