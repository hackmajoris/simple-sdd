#!/bin/bash
set -e

# SDD_VERSION controls which release is installed. Default: latest.
# Pin to a specific tag (e.g. SDD_VERSION=v1.2.3) for reproducible installs.
SDD_VERSION="${SDD_VERSION:-latest}"

if [ "$SDD_VERSION" = "latest" ]; then
  BASE_URL="https://github.com/hackmajoris/simple-sdd/releases/latest/download"
else
  BASE_URL="https://github.com/hackmajoris/simple-sdd/releases/download/${SDD_VERSION}"
fi

# SDD_BASE_URL overrides BASE_URL wholesale — handy for local testing
# (e.g. SDD_BASE_URL="file://$PWD" bash install.sh).
BASE_URL="${SDD_BASE_URL:-$BASE_URL}"

COMMANDS=(
  "simple-sdd-setup"
  "simple-sdd-feature-new"
  "simple-sdd-feature-implement"
  "simple-sdd-feature-update"
  "simple-sdd-feature-complete"
  "simple-sdd-feature-abandon"
  "simple-sdd-feature-status"
  "simple-sdd-constitution-sync"
  "simple-sdd-help"
)

usage() {
  cat <<EOF
Usage: $0 [--tool claude|copilot|opencode|all] [options]

  --tool TOOL   AI tool to install for (auto-detected if omitted).
                Can be passed multiple times, or use 'all' for every tool.
  --dry-run     Print the actions that would be taken without touching disk.
  --uninstall   Remove previously installed commands, templates, and the
                config-injection block for the selected tool(s).
  --yes         Skip interactive confirmation of auto-detected tool.
  -h, --help    Show this help.

Environment:
  SDD_VERSION   Release tag to install (default: latest). Set to e.g. v1.2.3
                for pinned, reproducible installs.
  SDD_BASE_URL  Override the download base URL (handy for local testing).
EOF
  exit 1
}

# Parse args
TOOLS=()
DRY_RUN=false
UNINSTALL=false
ASSUME_YES=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool) TOOLS+=("$2"); shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --uninstall) UNINSTALL=true; shift ;;
    --yes|-y) ASSUME_YES=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# Dry-run helper: echo in dry-run mode, execute otherwise.
run() {
  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] $*"
  else
    eval "$@"
  fi
}

# Auto-detect tool from existing project config if none specified
detect_tool() {
  local detected="" reason=""
  if [ -d ".claude" ]; then
    detected="claude"; reason="found .claude/ directory"
  elif [ -d ".opencode" ]; then
    detected="opencode"; reason="found .opencode/ directory"
  elif [ -f "RULES.md" ]; then
    detected="opencode"; reason="found RULES.md"
  elif [ -d ".github" ] && [ -f ".github/copilot-instructions.md" ]; then
    detected="copilot"; reason="found .github/copilot-instructions.md"
  fi
  if [ -n "$detected" ]; then
    echo "Detected: $detected ($reason)." >&2
    if [ "$ASSUME_YES" = false ] && [ "$DRY_RUN" = false ]; then
      printf "Proceed with %s? [Y/n] " "$detected" >&2
      read -r confirm
      case "$confirm" in
        ""|y|Y|yes|YES) ;;
        *) echo "Aborted." >&2; exit 1 ;;
      esac
    fi
  fi
  echo "$detected"
}

if [ ${#TOOLS[@]} -eq 0 ]; then
  auto="$(detect_tool)"
  if [ -n "$auto" ]; then
    TOOLS=("$auto")
  fi
fi

# Prompt if still unknown
if [ ${#TOOLS[@]} -eq 0 ]; then
  echo "Which AI tool are you installing for?"
  echo "  1) Claude Code"
  echo "  2) GitHub Copilot"
  echo "  3) OpenCode"
  echo "  4) All three"
  printf "Enter 1, 2, 3, or 4: "
  read -r choice
  case "$choice" in
    1) TOOLS=("claude") ;;
    2) TOOLS=("copilot") ;;
    3) TOOLS=("opencode") ;;
    4) TOOLS=("claude" "copilot" "opencode") ;;
    *) echo "Invalid choice."; exit 1 ;;
  esac
fi

# Expand 'all' and validate each entry
EXPANDED_TOOLS=()
for t in "${TOOLS[@]}"; do
  case "$t" in
    all) EXPANDED_TOOLS+=("claude" "copilot" "opencode") ;;
    claude|copilot|opencode) EXPANDED_TOOLS+=("$t") ;;
    *) echo "Unknown tool: $t. Must be claude, copilot, opencode, or all."; exit 1 ;;
  esac
done

# De-duplicate (preserve order)
SEEN=""
TOOLS=()
for t in "${EXPANDED_TOOLS[@]}"; do
  case " $SEEN " in
    *" $t "*) ;;
    *) TOOLS+=("$t"); SEEN="$SEEN $t" ;;
  esac
done

# Set tool-specific paths and config. Populates globals; called per tool.
set_paths_for_tool() {
  case "$1" in
    claude)
      COMMANDS_DIR=".claude/commands"
      TEMPLATES_DIR=".claude/templates"
      CMD_EXT=".md"
      CONFIG_DEST=".claude/CLAUDE.md"
      CONFIG_PARENT=".claude"
      ;;
    copilot)
      COMMANDS_DIR=".github/prompts"
      TEMPLATES_DIR=".github/prompts"
      CMD_EXT=".prompt.md"
      CONFIG_DEST=".github/copilot-instructions.md"
      CONFIG_PARENT=".github"
      ;;
    opencode)
      COMMANDS_DIR=".opencode/commands"
      TEMPLATES_DIR=".opencode/templates"
      CMD_EXT=".md"
      CONFIG_DEST="RULES.md"
      CONFIG_PARENT="."
      ;;
  esac
}

# Injection body per tool — kept in a function so --dry-run can preview it.
injection_body() {
  case "$1" in
    claude)
      cat <<'EOF'

<!-- simple-sdd -->
## simple-sdd

At the end of every `/simple-sdd-*` skill, remind the user:

> "Recommended: run `/clear` for a fresh context before the next step. Type `skip` to continue in this session."

Wait for the user to confirm before proceeding to the next skill.
<!-- /simple-sdd -->
EOF
      ;;
    copilot)
      cat <<'EOF'

<!-- simple-sdd -->
## simple-sdd

After completing any simple-sdd prompt, remind the user:

> "Recommended: start a new chat for a fresh context before the next step. Type `skip` to continue in this session."

Wait for the user to confirm before proceeding to the next step.
<!-- /simple-sdd -->
EOF
      ;;
    opencode)
      cat <<'EOF'

<!-- simple-sdd -->
## simple-sdd

After completing any simple-sdd command, remind the user:

> "Recommended: start a new session for a fresh context before the next step. Type `skip` to continue in this session."

Wait for the user to confirm before proceeding to the next step.
<!-- /simple-sdd -->
EOF
      ;;
  esac
}

# Strip the <!-- simple-sdd --> … <!-- /simple-sdd --> block from a file.
strip_injection() {
  local dest="$1"
  if [ ! -f "$dest" ]; then
    echo "  skipped: $dest (does not exist)"
    return
  fi
  if ! grep -q "<!-- simple-sdd -->" "$dest"; then
    echo "  skipped: $dest (no simple-sdd block found)"
    return
  fi
  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] strip simple-sdd block from $dest"
    return
  fi
  # sed -i differs between GNU and BSD; the -i.bak form works on both.
  sed -i.bak '/<!-- simple-sdd -->/,/<!-- \/simple-sdd -->/d' "$dest"
  rm -f "${dest}.bak"
  # Remove file if it's now empty (we created it from scratch on install).
  if [ ! -s "$dest" ]; then
    rm -f "$dest"
    echo "  removed: $dest (now empty)"
  else
    echo "  updated: $dest (simple-sdd block removed)"
  fi
}

install_file() {
  local src="$1"
  local dest="$2"
  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] download $BASE_URL/$src -> $dest"
    return
  fi
  local tmp
  tmp="$(mktemp)"
  curl -sSL "$BASE_URL/$src" -o "$tmp"
  # Prepend a version stamp so /simple-sdd-help can check for staleness.
  {
    echo "<!-- simple-sdd: ${SDD_VERSION} -->"
    cat "$tmp"
  } > "$dest"
  rm -f "$tmp"
  echo "  installed: $dest"
}

inject_config() {
  local tool="$1"
  if [ -f "$CONFIG_DEST" ] && grep -q "<!-- simple-sdd -->" "$CONFIG_DEST"; then
    echo "  skipped: $CONFIG_DEST (simple-sdd section already present)"
    return
  fi
  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] append simple-sdd block to $CONFIG_DEST"
    return
  fi
  [ "$CONFIG_PARENT" != "." ] && mkdir -p "$CONFIG_PARENT"
  injection_body "$tool" >> "$CONFIG_DEST"
  echo "  updated: $CONFIG_DEST"
}

install_for_tool() {
  local tool="$1"
  set_paths_for_tool "$tool"
  echo ""
  echo "=== $tool ==="
  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$COMMANDS_DIR" "$TEMPLATES_DIR"
  else
    echo "  [dry-run] mkdir -p $COMMANDS_DIR $TEMPLATES_DIR"
  fi
  echo "Installing commands..."
  for cmd in "${COMMANDS[@]}"; do
    install_file "${cmd}.md" "$COMMANDS_DIR/${cmd}${CMD_EXT}"
  done
  echo "Installing templates..."
  install_file "plan-template.md" "$TEMPLATES_DIR/plan-template.md"
  echo "Injecting config..."
  inject_config "$tool"
}

uninstall_for_tool() {
  local tool="$1"
  set_paths_for_tool "$tool"
  echo ""
  echo "=== $tool (uninstall) ==="
  echo "Removing commands..."
  for cmd in "${COMMANDS[@]}"; do
    local f="$COMMANDS_DIR/${cmd}${CMD_EXT}"
    if [ -f "$f" ]; then
      if [ "$DRY_RUN" = true ]; then
        echo "  [dry-run] rm $f"
      else
        rm -f "$f"
        echo "  removed: $f"
      fi
    fi
  done
  local tmpl="$TEMPLATES_DIR/plan-template.md"
  if [ -f "$tmpl" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  [dry-run] rm $tmpl"
    else
      rm -f "$tmpl"
      echo "  removed: $tmpl"
    fi
  fi
  echo "Stripping config injection..."
  strip_injection "$CONFIG_DEST"
}

# Main
if [ "$UNINSTALL" = true ]; then
  echo "Uninstalling simple-sdd for: ${TOOLS[*]}"
  for tool in "${TOOLS[@]}"; do
    uninstall_for_tool "$tool"
  done
  echo ""
  echo "Done. If you want to remove the now-empty .claude/ or .opencode/ directories,"
  echo "delete them manually — we leave them in place in case you have other content there."
  exit 0
fi

echo "Installing simple-sdd (version: $SDD_VERSION) for: ${TOOLS[*]}"
for tool in "${TOOLS[@]}"; do
  install_for_tool "$tool"
done

echo ""
echo "Done."
echo ""
echo "Available commands:"
echo "  simple-sdd-setup             — initialize SDD for this project"
echo "  simple-sdd-feature-new       — start a new feature"
echo "  simple-sdd-feature-implement — implement the next task"
echo "  simple-sdd-feature-update    — apply a change mid-feature"
echo "  simple-sdd-feature-status    — check progress"
echo "  simple-sdd-feature-complete  — close a finished feature"
echo "  simple-sdd-feature-abandon   — abandon an in-progress feature"
echo "  simple-sdd-constitution-sync — sync mission.md / tech-stack.md"
echo "  simple-sdd-help              — show this reference"
