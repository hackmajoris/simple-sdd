#!/bin/bash
set -e

BASE_URL="https://github.com/hackmajoris/simple-sdd/releases/latest/download"

COMMANDS=(
  "simple-sdd-setup"
  "simple-sdd-feature-new"
  "simple-sdd-feature-implement"
  "simple-sdd-feature-update"
  "simple-sdd-feature-complete"
  "simple-sdd-feature-status"
  "simple-sdd-constitution-sync"
  "simple-sdd-help"
)

usage() {
  echo "Usage: $0 [--tool claude|copilot|opencode]"
  echo ""
  echo "  --tool  AI tool to install for (auto-detected if omitted)"
  exit 1
}

# Parse args
TOOL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) TOOL="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# Auto-detect tool from existing project config
if [ -z "$TOOL" ]; then
  if [ -d ".claude" ]; then
    TOOL="claude"
  elif [ -d ".opencode" ] || [ -f "RULES.md" ]; then
    TOOL="opencode"
  elif [ -d ".github" ] && [ -f ".github/copilot-instructions.md" ]; then
    TOOL="copilot"
  fi
fi

# Prompt if still unknown
if [ -z "$TOOL" ]; then
  echo "Which AI tool are you installing for?"
  echo "  1) Claude Code"
  echo "  2) GitHub Copilot"
  echo "  3) OpenCode"
  printf "Enter 1, 2, or 3: "
  read -r choice
  case "$choice" in
    1) TOOL="claude" ;;
    2) TOOL="copilot" ;;
    3) TOOL="opencode" ;;
    *) echo "Invalid choice."; exit 1 ;;
  esac
fi

# Validate tool value
case "$TOOL" in
  claude|copilot|opencode) ;;
  *) echo "Unknown tool: $TOOL. Must be claude, copilot, or opencode."; exit 1 ;;
esac

# Set tool-specific paths and config
case "$TOOL" in
  claude)
    COMMANDS_DIR=".claude/commands"
    TEMPLATES_DIR=".claude/templates"
    CMD_EXT=".md"
    ;;
  copilot)
    COMMANDS_DIR=".github/prompts"
    TEMPLATES_DIR=".github/prompts"
    CMD_EXT=".prompt.md"
    ;;
  opencode)
    COMMANDS_DIR=".opencode/commands"
    TEMPLATES_DIR=".opencode/templates"
    CMD_EXT=".md"
    ;;
esac

mkdir -p "$COMMANDS_DIR"
mkdir -p "$TEMPLATES_DIR"

install_file() {
  local src="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    echo "  skipped: $dest (already exists)"
  else
    curl -sSL "$BASE_URL/$src" -o "$dest"
    echo "  installed: $dest"
  fi
}

echo "Installing simple-sdd for $TOOL..."
echo ""
echo "Installing commands..."

for cmd in "${COMMANDS[@]}"; do
  install_file "${cmd}.md" "$COMMANDS_DIR/${cmd}${CMD_EXT}"
done

echo ""
echo "Installing templates..."
install_file "plan-template.md" "$TEMPLATES_DIR/plan-template.md"

echo ""

# Tool-specific instructions injection
inject_claude() {
  local dest=".claude/CLAUDE.md"
  local marker="<!-- simple-sdd -->"
  if [ -f "$dest" ] && grep -q "$marker" "$dest"; then
    echo "  skipped: $dest (simple-sdd section already present)"
    return
  fi
  mkdir -p ".claude"
  cat >> "$dest" <<'EOF'

<!-- simple-sdd -->
## simple-sdd

At the end of every `/simple-sdd-*` skill, you MUST ask the user:

> "Context should be cleared for best results before the next step. Run `/clear` when ready — or type 'skip' to continue in this session."

Wait for the user to confirm before proceeding. Do not run the next skill or start any implementation until they respond.
<!-- /simple-sdd -->
EOF
  echo "  updated: $dest"
}

inject_copilot() {
  local dest=".github/copilot-instructions.md"
  local marker="<!-- simple-sdd -->"
  if [ -f "$dest" ] && grep -q "$marker" "$dest"; then
    echo "  skipped: $dest (simple-sdd section already present)"
    return
  fi
  mkdir -p ".github"
  cat >> "$dest" <<'EOF'

<!-- simple-sdd -->
## simple-sdd

After completing any simple-sdd prompt, remind the user:

> "For best results, start a new chat before the next step. Type 'skip' to continue in this session."

Wait for the user to confirm before proceeding to the next step.
<!-- /simple-sdd -->
EOF
  echo "  updated: $dest"
}

inject_opencode() {
  local dest="RULES.md"
  local marker="<!-- simple-sdd -->"
  if [ -f "$dest" ] && grep -q "$marker" "$dest"; then
    echo "  skipped: $dest (simple-sdd section already present)"
    return
  fi
  cat >> "$dest" <<'EOF'

<!-- simple-sdd -->
## simple-sdd

After completing any simple-sdd command, remind the user:

> "For best results, start a new session before the next step. Type 'skip' to continue in this session."

Wait for the user to confirm before proceeding to the next step.
<!-- /simple-sdd -->
EOF
  echo "  updated: $dest"
}

case "$TOOL" in
  claude)  inject_claude ;;
  copilot) inject_copilot ;;
  opencode) inject_opencode ;;
esac

echo ""
echo "Done. Commands installed to $COMMANDS_DIR/"
echo ""
echo "Available commands:"
echo "  simple-sdd-setup             — initialize SDD for this project"
echo "  simple-sdd-feature-new       — start a new feature"
echo "  simple-sdd-feature-implement — implement the next task"
echo "  simple-sdd-feature-update    — apply a change mid-feature"
echo "  simple-sdd-feature-status    — check progress"
echo "  simple-sdd-feature-complete  — close a finished feature"
echo "  simple-sdd-constitution-sync — sync mission.md / tech-stack.md"
echo "  simple-sdd-help              — show this reference"
