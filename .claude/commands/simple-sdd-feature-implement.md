---
name: simple-sdd-feature-implement
description: Implements the next task of the current in-progress feature. Works for both first run and resuming after a break — finds the feature, checks progress, and continues from the first unchecked task.
type: skill
---

You are implementing the next task of the current in-progress feature.

## Step 1 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository."

## Step 2 — Find in-progress feature spec

Use the Bash tool to find all spec directories outside `specs/completed/`:
```bash
find specs -mindepth 1 -maxdepth 1 -type d ! -name completed 2>/dev/null
```

If no directories are found, tell the user:
"No feature in progress. Run `/simple-sdd-feature-new` to start one."
Then stop.

If more than one directory is found, tell the user:
"More than one feature spec found:
<list directories>

Only one feature should be in progress at a time."
Then stop.

Store the single directory found.

## Step 3 — Switch to feature branch

Extract the branch name from the directory name by stripping the date prefix (e.g. `specs/2026-04-16-user-authentication` → `user-authentication`).

Use the Bash tool to check the current branch:
```bash
git rev-parse --abbrev-ref HEAD
```

If not already on the feature branch, switch:
```bash
git checkout <branch-name>
```

If the branch does not exist, tell the user:
"Branch `<branch-name>` not found. It may have been deleted or renamed."
Then stop.

## Step 4 — Check progress

Use the Bash tool to count checked and unchecked tasks:
```bash
grep -c "\- \[x\]" <spec-directory>/plan.md 2>/dev/null || echo "0"
grep -c "\- \[ \]" <spec-directory>/plan.md 2>/dev/null || echo "0"
```

If no unchecked tasks remain, tell the user:
"All tasks in `plan.md` are complete. Run `/simple-sdd-feature-complete` to close this feature."
Then stop.

**If this is the first run (0 tasks checked):** read the spec files and dive straight into Task 1 — no git history needed.

**If resuming (some tasks already checked):** reconstruct context first — run:
```bash
git log --oneline $(git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null)..HEAD
git diff $(git merge-base HEAD main 2>/dev/null || git merge-base HEAD develop 2>/dev/null)..HEAD --stat
```

Read silently and build a picture of what's been done before proceeding.

## Step 5 — Read the spec

Always read:
- `<spec-directory>/plan.md`
- `<spec-directory>/requirements.md`

On first run only (0 tasks done), also read `specs/tech-stack.md` for stack alignment. Skip `validation.md` and `specs/mission.md` — not needed at task level.

## Step 6 — Implement the next task

Find the first task group with unchecked boxes.

Tell the user:
"[First run: 'Starting' / Resuming: 'Resuming'] `<branch-name>` — <N> of <total> tasks done.

**Next task:**
<copy the full task group from plan.md>

Let's go."

Implement every item in this task. Do not start the following task.

## Step 7 — Mark and commit (or continue)

Once every item in the task is done:

1. Edit `<spec-directory>/plan.md` — mark every checkbox in the completed task as `[x]`.

**Detect exploration-only tasks:** A task is exploration-only if it contains a note like "No code changes in this task" or "exploration only" (case-insensitive). Check the task text you just completed.

**If the task was exploration-only** (no source files were created or modified — only plan.md was updated):
- Do NOT commit.
- Tell the user: "Task <N> (exploration) complete — no code changes to commit. Continuing to the next task."
- Immediately proceed to the next unchecked task group and implement it (loop back to Step 6 for that task). Do not stop.

**If the task produced code changes:**
2. Commit all changes:
```bash
git add .
git commit -m "feat(<branch-name>): complete task <N> — <task name>"
```

## Step 8 — Prompt for next session

(Only reached after a code-producing task is committed.)

Check remaining unchecked tasks:
```bash
grep -c "\- \[ \]" <spec-directory>/plan.md
```

If tasks remain, tell the user:
"Task <N> complete and committed.

Run `/clear` then `/simple-sdd-feature-implement` to continue with the next task."

If all tasks are done, tell the user:
"Task <N> complete and committed. All tasks done.

Run `/simple-sdd-feature-complete` to close this feature."

Then stop.
