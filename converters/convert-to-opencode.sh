#!/bin/bash
# Workspace Manager - Bash converter for Opencode
# Usage: bash convert-to-opencode.sh <source_dir> <target_path>
# Example: bash convert-to-opencode.sh ./setup-wm ~/.config/opencode
# Requires: jq (for config registration)

set -e

SOURCE_DIR="${1:?Missing source directory}"
TARGET_PATH="${2:?Missing target path}"

WORKFLOWS_DIR="$TARGET_PATH/awf-workflows"
SKILLS_DIR="$TARGET_PATH/awf-skills"
SCHEMAS_DIR="$TARGET_PATH/schemas"
TEMPLATES_DIR="$TARGET_PATH/templates"
CONFIG_FILE="$TARGET_PATH/opencode.jsonc"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

# Helper: extract description from workflow markdown frontmatter
get_description() {
    local file="$1"
    local name="$2"
    local desc
    desc=$(grep -m1 '^description:' "$file" 2>/dev/null | sed 's/^description:\s*//' | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//")
    if [ -z "$desc" ]; then
        echo "WM workflow: $name"
    else
        echo "$desc"
    fi
}

# Helper: strip JSONC comments (// ...)
strip_jsonc_comments() {
    sed -E 's|^[[:space:]]*//.*$||' | sed -E 's|([,{])[[:space:]]*//[^"]*$|\1|'
}

# Copy workflows -> awf-workflows/
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

# Copy skills -> awf-skills/
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
    echo -e "   ${YELLOW}   Then re-run: bash convert-to-opencode.sh $SOURCE_DIR $TARGET_PATH${NC}"
else
    # Read existing config or create empty
    if [ -f "$CONFIG_FILE" ]; then
        json=$(strip_jsonc_comments < "$CONFIG_FILE" | jq '.' 2>/dev/null || echo '{}')
    else
        json='{}'
    fi

    # Ensure agent and command sections exist
    json=$(echo "$json" | jq 'if .agent == null then .agent = {} else . end | if .command == null then .command = {} else . end')

    # Register workflows as agents + commands
    if [ -d "$WORKFLOWS_DIR" ]; then
        for wf in "$WORKFLOWS_DIR/"*.md; do
            [ -f "$wf" ] || continue
            wf_name=$(basename "$wf" .md)
            desc=$(get_description "$wf" "$wf_name")
            prompt="You are the WM $wf_name workflow executor.\n\nRead the complete instructions from:\n$wf\n\nFollow all stages sequentially."

            # Add agent entry if not exists
            json=$(echo "$json" | jq --arg n "$wf_name" --arg d "$desc" --arg p "$prompt" \
                'if .agent[$n] == null then .agent[$n] = {"description": $d, "mode": "subagent", "prompt": $p, "maxSteps": 80, "permission": {"external_directory": "allow"}} else . end')

            # Add command entry if not exists
            json=$(echo "$json" | jq --arg n "$wf_name" \
                'if .command[$n] == null then .command[$n] = {"template": "Run the WM \($n) workflow. Input: {{input}}", "description": "WM workflow: \($n)", "agent": $n, "subtask": true} else . end')
        done
    fi

    # Register skills as agents
    if [ -d "$SKILLS_DIR" ]; then
        for sd in "$SKILLS_DIR/"*/; do
            [ -d "$sd" ] || continue
            skill_name=$(basename "$sd")
            skill_md="$sd/SKILL.md"
            prompt="You are the $skill_name skill. Read: $skill_md"

            json=$(echo "$json" | jq --arg n "$skill_name" --arg p "$prompt" \
                'if .agent[$n] == null then .agent[$n] = {"description": "WM skill: \($n)", "mode": "subagent", "prompt": $p, "maxSteps": 80, "permission": {"external_directory": "allow"}} else . end')
        done
    fi

    echo "$json" > "$CONFIG_FILE"
    echo -e "   ${GREEN}Updated config: $CONFIG_FILE${NC}"
fi

echo -e "${GRAY}Conversion complete for target: Opencode${NC}"
