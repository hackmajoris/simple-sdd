#!/bin/bash
set -e

BASE_URL="https://github.com/hackmajoris/simple-sdd/releases/latest/download"
SKILLS_DIR=".claude/commands"
TEMPLATES_DIR=".claude/templates"
CLAUDE_MD=".claude/CLAUDE.md"

mkdir -p "$SKILLS_DIR"
mkdir -p "$TEMPLATES_DIR"

install_file() {
  local name="$1"
  local dest="$2"
  if [ -f "$dest" ]; then
    echo "  skipped: $dest (already exists)"
  else
    curl -sSL "$BASE_URL/$name" -o "$dest"
    echo "  installed: $dest"
  fi
}

inject_claude_md() {
  local marker="<!-- simple-sdd -->"
  if [ -f "$CLAUDE_MD" ] && grep -q "$marker" "$CLAUDE_MD"; then
    echo "  skipped: $CLAUDE_MD (simple-sdd section already present)"
    return
  fi
  cat >> "$CLAUDE_MD" <<'EOF'

<!-- simple-sdd -->
## simple-sdd

At the end of every `/simple-sdd-*` skill, you MUST ask the user:

> "Context should be cleared for best results before the next step. Run `/clear` when ready — or type 'skip' to continue in this session."

Wait for the user to confirm before proceeding. Do not run the next skill or start any implementation until they respond.
<!-- /simple-sdd -->
EOF
  echo "  updated: $CLAUDE_MD"
}

echo "Installing simple-sdd skills..."

install_file "simple-sdd-setup.md"            "$SKILLS_DIR/simple-sdd-setup.md"
install_file "simple-sdd-feature-new.md"      "$SKILLS_DIR/simple-sdd-feature-new.md"
install_file "simple-sdd-feature-implement.md" "$SKILLS_DIR/simple-sdd-feature-implement.md"
install_file "simple-sdd-feature-update.md"   "$SKILLS_DIR/simple-sdd-feature-update.md"
install_file "simple-sdd-feature-complete.md" "$SKILLS_DIR/simple-sdd-feature-complete.md"

echo ""
echo "Installing templates..."

install_file "plan-template.md" "$TEMPLATES_DIR/plan-template.md"

echo ""
echo "Configuring .claude/CLAUDE.md..."

inject_claude_md

echo ""
echo "Done. Available commands:"
echo "  /simple-sdd-setup         — start SDD (new or existing project)"
echo "  /simple-sdd-feature-new — start a new feature"
