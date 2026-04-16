---
name: simple-sdd-feature-new
description: Starts a new feature or change. Reads project context, asks 3 grouped questions, creates a git branch, and writes plan.md, requirements.md, and validation.md into a dated specs directory.
type: skill
---

You are starting a new feature or change under Spec Driven Development (SDD).

## Config values used in this command

At the start of every Bash block below, source `specs/.sddrc` if it exists. Values and defaults:

```bash
[ -f specs/.sddrc ] && . specs/.sddrc
SPECS_DIR="${SDD_SPECS_DIR:-specs}"
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-${SDD_DEFAULT_BRANCH:-main}}
TEMPLATE_PATH="${SDD_TEMPLATE_PATH:-.claude/templates/plan-template.md}"
USE_WORKTREES="${SDD_USE_WORKTREES:-false}"
WORKTREE_DIR="${SDD_WORKTREE_DIR:-..}"
CHORE="${SDD_COMMIT_PREFIX_CHORE:-chore}"
```

## Step 0 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository. Run `git init` first."

Run `git status --porcelain` — if the working tree has unrelated changes:
- Offer to stash them: `git stash push -u -m "sdd-auto-<feature-name>"` and show the stash ref.
- After the feature's spec commit lands (end of this command), remind the user to `git stash pop` to restore their work.
- If the user prefers, they can abort and commit/stash manually — respect that choice.

## Step 1 — Check for in-progress feature

Use the Bash tool to find all spec directories outside `<SPECS_DIR>/completed/` in the current worktree:
```bash
find "$SPECS_DIR" -mindepth 1 -maxdepth 1 -type d ! -name completed 2>/dev/null
```

Note: in worktree mode, each worktree has its own `$SPECS_DIR` on its own branch, so this scan correctly stays local to the working directory.

If any directories are found, tell the user:
"A feature is already in progress: `<directory>`

Finish or complete it before starting a new one:
- `/simple-sdd-feature-implement` — continue implementation
- `/simple-sdd-feature-status` — check what's left
- `/simple-sdd-feature-complete` — close it if all tasks are done"

Then stop.

---

## Phase 0 — Read and validate context

Before asking anything:
1. Read `specs/mission.md` and `specs/tech-stack.md` — internalize the product purpose and stack constraints.
2. Show the user a brief summary (2–3 lines) of the product and stack.

Then use the `AskUserQuestion` tool to ask:
"Are `mission.md` and `tech-stack.md` still accurate, or has anything changed since they were last updated? (new libraries, infra changes, shifted scope, etc.)

- If yes → describe what's changed and I'll update them before we spec this feature.
- If no → we'll proceed."

If the user reports changes:
- Apply their corrections to `$SPECS_DIR/mission.md` and/or `$SPECS_DIR/tech-stack.md` using the Edit tool.
- Commit the updates:
  ```bash
  git add "$SPECS_DIR/mission.md" "$SPECS_DIR/tech-stack.md"
  git commit -m "$CHORE: update constitution before <feature-name> spec"
  ```
- Tell the user the constitution is updated, then continue.

If the user confirms no changes are needed, continue to Phase 1.

---

## Phase 1 — Feature questions

Use the `AskUserQuestion` tool to ask the following **3 questions in a single grouped call**. Do not create any files or branches yet.

1. **What are you building or changing?**
2. **Why now?** What's the motivation or trigger for this piece of work?
3. **Any constraints?** Dependencies, things that must NOT change, or hard boundaries to respect.

Wait for the user's answers before proceeding.

---

## Phase 2 — Create branch and directory

From the user's answer to Q1, derive:
- **Branch name**: kebab-case of the feature name, no date prefix (e.g. `user-authentication`)
- **Directory name**: today's date + kebab-case feature name (e.g. `2026-04-16-user-authentication`)

Use the Bash tool to create the branch. Choose one path based on `USE_WORKTREES`:

**If `USE_WORKTREES=false` (default)** — regular branch checkout in the current working directory:
```bash
git checkout -b <branch-name>
mkdir -p "$SPECS_DIR/<directory-name>"
```

**If `USE_WORKTREES=true`** — create a dedicated worktree for parallel work:
```bash
WORKTREE_PATH="$WORKTREE_DIR/$(basename "$PWD")-<branch-name>"
git worktree add "$WORKTREE_PATH" -b <branch-name>
mkdir -p "$WORKTREE_PATH/$SPECS_DIR/<directory-name>"
```

Tell the user the branch and directory that were created. In worktree mode, also tell them:
> "Worktree created at `<WORKTREE_PATH>`. Run `cd <WORKTREE_PATH>` before `/simple-sdd-feature-implement`."

All subsequent file writes in this command target the spec directory inside whichever location is active.

---

## Phase 3 — Write spec files

Before writing any files, read `$TEMPLATE_PATH` (default `.claude/templates/plan-template.md`) — this defines the required structure for `plan.md`. Copilot and OpenCode installs place the template at `.github/prompts/plan-template.md` and `.opencode/templates/plan-template.md` respectively; `SDD_TEMPLATE_PATH` in `specs/.sddrc` overrides.

Use the Write tool to write the following three files into `$SPECS_DIR/<directory-name>/`. Use `$SPECS_DIR/mission.md` and `$SPECS_DIR/tech-stack.md` for alignment.

### $SPECS_DIR/<directory-name>/requirements.md

```markdown
# Requirements: <feature name>

## Scope

### In
[What is included in this piece of work — derived from Phase 1 answers]

### Out
[What is explicitly excluded]

## Context
[Why this work is happening now — from Phase 1, Q2]

## Constraints
[From Phase 1, Q3 — dependencies, boundaries, things not to touch]

## Key decisions
[Any decisions made upfront that shape the implementation]
```

### $SPECS_DIR/<directory-name>/plan.md

Follow the structure defined in `.claude/templates/plan-template.md` exactly. Adapt the section content to this specific feature — do not copy placeholder text. The plan must include:

- **Overview** — what is being built and why
- **Context** — files/components involved, related patterns, dependencies (infer from the tech stack and feature description)
- **Development Approach** — testing approach (ask yourself: does the user's tech stack suggest TDD or regular?), rules for task completion
- **Testing Strategy** — unit and e2e test expectations
- **Progress Tracking** — checkbox conventions (`[x]`, ➕, ⚠️)
- **Implementation Steps** — concrete `### Task N:` groups with `[ ]` checkboxes; each task must end with writing/updating tests and running them
- **Technical Details** — data structures, parameters, processing flow relevant to this feature
- **Post-Completion** — manual verification steps, external system updates (no checkboxes)

Keep tasks small and ordered by dependency. Each task should be completable in one focused session.

### $SPECS_DIR/<directory-name>/validation.md

```markdown
# Validation: <feature name>

> How to know the implementation succeeded and is safe to merge.

## Acceptance criteria
[Specific, testable conditions that must be true when this is done]

## Manual checks
[Steps a reviewer would take to verify the feature works end to end]

## Automated checks
[Tests, linting, CI steps that must pass]

## Definition of done
- [ ] All acceptance criteria met
- [ ] Manual checks completed
- [ ] CI passing
- [ ] No regressions in related areas
```

---

## Completion

After writing all files:

1. Tell the user:
   "Feature spec ready on branch `<branch-name>`. Please review the generated files before we commit:
- `$SPECS_DIR/<directory-name>/requirements.md`
- `$SPECS_DIR/<directory-name>/plan.md`
- `$SPECS_DIR/<directory-name>/validation.md`

Take a look and confirm when ready — or let me know what to adjust."

2. Use the `AskUserQuestion` tool to ask:
   "Are the spec files good to commit, or do you need changes?"

3. If the user confirms (yes / looks good / commit / etc.):
   - Count the `### Task` groups in `plan.md` to put the task count in the commit message:
     ```bash
     TASK_COUNT=$(grep -c '^### Task' "$SPECS_DIR/<directory-name>/plan.md")
     ```
   - Commit:
     ```bash
     git add "$SPECS_DIR/<directory-name>/"
     git commit -m "$CHORE: add SDD spec for <feature-name> ($TASK_COUNT tasks)"
     ```
   - Tell the user:
     "Committed. Recommended: run `/clear` for a fresh context before `/simple-sdd-feature-implement`. Type `skip` to continue in this session."

   If a stash was created in Step 0, remind the user: "Your earlier unrelated changes are still in `stash@{0}`. Run `git stash pop` when you're ready to restore them."

4. If the user requests changes:
   Make the requested edits to the spec files, then return to step 2.