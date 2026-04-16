---
name: simple-sdd-feature-status
description: Shows the status of the current in-progress feature — what tasks have been completed and what remains, based on checkboxes in plan.md.
type: skill
---

You are reporting the status of the current in-progress feature.

## Config values used in this command

```bash
[ -f specs/.sddrc ] && . specs/.sddrc
SPECS_DIR="${SDD_SPECS_DIR:-specs}"
```

## Step 1 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository."

## Step 2 — Find in-progress feature spec

Use the Bash tool to find all spec directories outside `$SPECS_DIR/completed/`:
```bash
find "$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name completed 2>/dev/null
```

If no directories are found, tell the user:
"No feature is currently in progress. Run `/simple-sdd-feature-new` to start one."
Then stop.

If more than one directory is found, tell the user:
"More than one feature spec found:
<list directories>

Only one feature should be in progress at a time."
Then stop.

Store the single directory found.

## Step 3 — Read plan.md

Use the Read tool to read `<spec-directory>/plan.md`.

Extract:
- All lines matching `- [x]` — these are **completed** tasks.
- All lines matching `- [ ]` — these are **remaining** tasks.

Also extract the feature name from the directory (e.g. `specs/2026-04-16-user-authentication` → `user-authentication`).

## Step 4 — Report status

Count totals:
- `done` = number of `[x]` lines
- `remaining` = number of `[ ]` lines
- `total` = done + remaining

Tell the user:

"**Feature:** `<feature-name>`
**Progress:** <done>/<total> tasks complete

---

**Done** (<done>):
<list each completed [x] line, preserving indentation>

**Remaining** (<remaining>):
<list each unchecked [ ] line, preserving indentation>

---

<if remaining > 0>
Run `/simple-sdd-feature-implement` to continue.
<else>
All tasks complete. Run `/simple-sdd-feature-complete` to close this feature.
</if>"

Then stop.
