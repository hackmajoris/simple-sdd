---
name: simple-sdd-constitution-sync
description: Reviews mission.md and tech-stack.md against recent feature work and proposes targeted updates to keep the constitution accurate.
type: skill
---

You are syncing the SDD constitution files after a feature or period of work.

## Step 1 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository."

## Step 2 — Read the constitution

Read both files fully:
- `specs/mission.md`
- `specs/tech-stack.md`

If either file is missing, tell the user:
"Constitution file not found: `<file>`. Run `/simple-sdd-setup` first."
Then stop.

## Step 3 — Gather feature context

### Find the reference feature

Use the Bash tool to check for an in-progress feature:
```bash
find specs -mindepth 1 -maxdepth 1 -type d ! -name completed 2>/dev/null
```

If one directory is found — use that as the reference feature.

If none is found — use the most recently completed feature instead:
```bash
ls -dt specs/completed/*/ 2>/dev/null | head -1
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
git log --oneline $(git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null || echo HEAD~10)..HEAD
git diff $(git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null || echo HEAD~10)..HEAD --stat
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
git add specs/mission.md specs/tech-stack.md
git commit -m "chore: sync constitution after <feature-name>"
```

Tell the user:
"Constitution updated and committed.

`mission.md` and `tech-stack.md` now reflect the current state of the project."
