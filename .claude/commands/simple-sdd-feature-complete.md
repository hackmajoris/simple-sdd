---
name: simple-sdd-feature-complete
description: Marks the current feature as complete. Verifies all checkboxes are ticked, moves the spec to specs/completed/, and merges the branch.
type: skill
---

You are completing the current SDD feature.

## Step 1 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository."

## Step 2 — Identify current feature branch

Use the Bash tool to run:
```bash
git rev-parse --abbrev-ref HEAD
```

If the branch is `main` or `develop`, tell the user:
"You are on `<branch>`. Switch to a feature branch before running this command."
Then stop.

Store the branch name — this is the feature name.

## Step 3 — Find the feature spec directory

Use the Bash tool to run:
```bash
ls -d specs/*<branch-name>* 2>/dev/null
```

If no directory is found, tell the user:
"No spec directory found matching branch `<branch-name>`. Expected a directory under `specs/` containing the branch name."
Then stop.

Store the matched directory path (e.g. `specs/2026-04-16-user-authentication`).

## Step 4 — Check for uncommitted changes

Run `git status --porcelain` — if not empty, stop: "You have uncommitted changes. Commit them before completing the feature."

## Step 5 — Verify all checkboxes are ticked

Use the Bash tool to run:
```bash
grep -rn "\- \[ \]" <spec-directory>/plan.md <spec-directory>/validation.md 2>/dev/null
```

If any unchecked boxes are found, tell the user:
"The following items are still open:

<list each file and unchecked line>

Complete all items before marking the feature as done. For manual-check items: run the steps yourself, then tick the boxes (`- [ ]` → `- [x]`)."
Then stop.

## Step 6 — Confirm completion

Use the `AskUserQuestion` tool to ask:
"All checkboxes are ticked. Ready to complete feature `<branch-name>`?

This will:
1. Move `<spec-directory>` → `specs/completed/<directory-name>`
2. Commit the move
3. Switch back to `main` or `develop`"

If the user confirms, continue. Otherwise stop.

## Step 7 — Move spec to completed

Use the Bash tool to run:
```bash
mkdir -p specs/completed
mv <spec-directory> specs/completed/
git add specs/
git commit -m "chore: complete feature <branch-name>"
```

## Step 8 — Switch back to base branch

Use the Bash tool to determine which base branch exists:
```bash
git branch | grep -E "^\*? *(main|develop)$" | head -1 | tr -d '* '
```

Then run:
```bash
git checkout <base-branch>
```

## Completion

Tell the user:
"Feature `<branch-name>` marked as complete.
- Spec moved to `specs/completed/<directory-name>`
- Back on `<base-branch>`

**Next:** run `/simple-sdd-constitution-sync` to check whether `mission.md` or `tech-stack.md` need updating based on what this feature changed. Then `/simple-sdd-feature-new` when ready."
