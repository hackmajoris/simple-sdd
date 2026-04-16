---
name: simple-sdd-constitution-sync
description: Reviews mission.md and tech-stack.md against recent feature work and proposes targeted updates to keep the constitution accurate.
type: skill
---

You are syncing the SDD constitution files after a feature or period of work.

## Config values used in this command

```bash
[ -f specs/.sddrc ] && . specs/.sddrc
SPECS_DIR="${SDD_SPECS_DIR:-specs}"
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-${SDD_DEFAULT_BRANCH:-main}}
CHORE="${SDD_COMMIT_PREFIX_CHORE:-chore}"
```

## Step 1 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository."

## Step 2 — Read the constitution

Read both files fully:
- `$SPECS_DIR/mission.md`
- `$SPECS_DIR/tech-stack.md`

If either file is missing, tell the user:
"Constitution file not found: `<file>`. Run `/simple-sdd-setup` first."
Then stop.

## Step 3 — Gather feature context

### Find the reference feature

First, prefer the completed-specs index if present:
```bash
[ -f "$SPECS_DIR/completed/INDEX.md" ] && tail -1 "$SPECS_DIR/completed/INDEX.md"
```

The last line of `INDEX.md` names the most recently completed feature. If the index exists, use its last entry as the reference feature (unless an in-progress feature exists — that takes priority below).

Check for an in-progress feature:
```bash
find "$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name completed 2>/dev/null
```

If one directory is found — use that as the reference feature.

If none is found and no `INDEX.md` entry was usable, fall back to scanning directly:
```bash
ls -dt "$SPECS_DIR"/completed/*/ 2>/dev/null | head -1
```

If still nothing, tell the user:
"No feature specs found to compare against. The constitution can still be edited manually."
Then stop.

Store the reference feature directory.

### Read the feature spec

Read:
- `<feature-directory>/requirements.md`

### Read the git diff

Use the Bash tool to get a summary of what changed in the codebase:
```bash
MERGE_BASE=$(git merge-base HEAD "$DEFAULT_BRANCH" 2>/dev/null || git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null || echo HEAD~10)
git log --oneline "$MERGE_BASE"..HEAD
git diff "$MERGE_BASE"..HEAD --stat
```

Read silently. You are looking for:
- New files, packages, or dependencies added
- Infrastructure or config changes (Dockerfiles, CI, cloud configs)
- New services, APIs, or external integrations introduced
- Shifts in product scope or purpose

## Step 4 — Analyse for drift

Compare what you read in Step 3 against the constitution. Identify:

**tech-stack.md drift** — anything added or changed that is not yet reflected:
- New languages, frameworks, or libraries
- New infrastructure components or hosting changes
- New external services, APIs, or integrations
- Changed or removed constraints

**mission.md drift** — any refinement warranted:
- Product scope expanded or narrowed
- Problem statement clarified
- Definition of success evolved

If you find no meaningful drift, tell the user:
"Constitution files look accurate — no updates needed based on `<feature-name>`."
Then stop.

## Step 5 — Propose updates

Tell the user a clear diff-style summary of what you found:

```
mission.md
  → [specific proposed change, or "no changes"]

tech-stack.md
  → [specific proposed change 1]
  → [specific proposed change 2]
  → ...
```

Be concrete. Name the actual library, service, or wording change. Do not use vague summaries like "update to reflect new stack."

## Step 6 — Confirm

Use the `AskUserQuestion` tool to ask:
"Do these updates look right? Confirm to apply — or tell me what to adjust."

If the user requests adjustments, revise your proposals and return to this step.

## Step 7 — Apply updates

Use the Edit tool to apply only the confirmed changes to `specs/mission.md` and/or `specs/tech-stack.md`.

Then commit:
```bash
git add "$SPECS_DIR/mission.md" "$SPECS_DIR/tech-stack.md"
git commit -m "$CHORE: sync constitution after <feature-name>"
```

Tell the user:
"Constitution updated and committed.

`mission.md` and `tech-stack.md` now reflect the current state of the project."
