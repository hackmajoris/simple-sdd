---
name: simple-sdd-feature-update
description: Updates the current feature based on a change request. Updates the spec (plan, requirements, validation) first, asks for confirmation, then applies code changes if needed.
type: skill
---

You are applying a change to the current in-progress feature.

## Step 1 — Validate git state

Use the Bash tool to run:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null && echo "ok" || echo "not-a-repo"
```

If the output is `not-a-repo`, tell the user:
"This directory is not a git repository."
Then stop.

## Step 2 — Validate feature branch

Use the Bash tool to run:
```bash
git rev-parse --abbrev-ref HEAD
```

If the branch is `main` or `develop`, tell the user:
"You are on `<branch>`. Feature updates can only be done from a feature branch."
Then stop.

Store the branch name.

## Step 3 — Find the feature spec directory

Use the Bash tool to run:
```bash
ls -d specs/*<branch-name>* 2>/dev/null
```

If no directory is found, tell the user:
"No spec directory found matching branch `<branch-name>`."
Then stop.

Store the spec directory path.

## Step 4 — Read current spec

Read the following files to understand the current state:
- `<spec-directory>/plan.md`
- `<spec-directory>/requirements.md`
- `<spec-directory>/validation.md`

## Step 5 — Ask what needs to change

Use the `AskUserQuestion` tool to ask:

"What needs to change? Describe the update — new requirements, a change in approach, a discovered constraint, a scope adjustment, or anything else."

Wait for the user's answer. This is the change request that drives everything below.

## Step 6 — Update the spec files

Based on the change request, update only the relevant spec files using the Edit tool:

**requirements.md** — update if the change affects:
- What's in or out of scope
- Key decisions or constraints

**plan.md** — update if the change affects tasks:
- New tasks → add with ➕ prefix
- Removed tasks → strike through or delete
- Changed approach → update task descriptions
- Blockers → add with ⚠️ prefix

**validation.md** — update if the change affects:
- Acceptance criteria
- Manual or automated checks

Only touch files where something actually changed.

After editing, show the user a clear diff-style summary of what changed in the spec:
```
requirements.md — [what changed]
plan.md         — [what changed]
validation.md   — [what changed, or "no changes"]
```

## Step 7 — Confirm spec changes

Use the `AskUserQuestion` tool to ask:
"Does the updated spec look right? Confirm to proceed — or describe what to adjust."

If the user requests adjustments, return to Step 6.

If confirmed:
- Use the Bash tool to commit the spec changes:
```bash
git add <spec-directory>/
git commit -m "chore: update spec for <branch-name> — <one-line summary of the change>"
```

## Step 8 — Apply code changes if needed

Assess whether the change request requires code changes (new tasks added, approach changed, etc.).

If **no code changes are needed** (spec-only update), tell the user:
"Spec updated. No code changes required — run `/simple-sdd-feature-implement` to continue implementation."
Then stop.

If **code changes are needed**, tell the user what you're about to implement and proceed — following the updated plan.md task order, completing each task fully before moving to the next.

## Completion

After implementing any code changes, tell the user:
"Update complete for feature `<branch-name>`.

Run `/simple-sdd-feature-implement` to continue with remaining tasks, or `/simple-sdd-feature-complete` when all are done."
