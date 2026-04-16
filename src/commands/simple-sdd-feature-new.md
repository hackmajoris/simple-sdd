---
name: simple-sdd-feature-new
description: Starts a new feature or change. Reads project context, asks 3 grouped questions, creates a git branch, and writes plan.md, requirements.md, and validation.md into a dated specs directory.
type: skill
---

You are starting a new feature or change under Spec Driven Development (SDD).

## Step 0 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository. Run `git init` first."

Run `git status --porcelain` — if not empty, stop: "You have uncommitted changes. Commit or stash them first — SDD will create a new branch and commit the feature spec files as a clean checkpoint."

## Step 1 — Check for in-progress feature

Use the Bash tool to find all spec directories outside `specs/completed/`:
```bash
find specs -mindepth 1 -maxdepth 1 -type d ! -name completed 2>/dev/null
```

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
- Apply their corrections to `specs/mission.md` and/or `specs/tech-stack.md` using the Edit tool.
- Commit the updates:
  ```bash
  git add specs/mission.md specs/tech-stack.md
  git commit -m "chore: update constitution before <feature-name> spec"
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

Use the Bash tool to:
1. `git checkout -b <branch-name>`
2. `mkdir -p specs/<directory-name>`

Tell the user the branch and directory that were created.

---

## Phase 3 — Write spec files

Before writing any files, read `.claude/templates/plan-template.md` — this defines the required structure for `plan.md`.

Use the Write tool to write the following three files into `specs/<directory-name>/`. Use `specs/mission.md` and `specs/tech-stack.md` for alignment.

### specs/<directory-name>/requirements.md

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

### specs/<directory-name>/plan.md

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

### specs/<directory-name>/validation.md

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
- `specs/<directory-name>/requirements.md`
- `specs/<directory-name>/plan.md`
- `specs/<directory-name>/validation.md`

Take a look and confirm when ready — or let me know what to adjust."

2. Use the `AskUserQuestion` tool to ask:
   "Are the spec files good to commit, or do you need changes?"

3. If the user confirms (yes / looks good / commit / etc.):
   Use the Bash tool to run:
   ```bash
   git add specs/<directory-name>/
   git commit -m "chore: add spec for <feature-name>"
   ```
   Then tell the user:
   "Committed. Run `/clear` for a fresh context, then `/simple-sdd-feature-implement` to start implementation."

4. If the user requests changes:
   Make the requested edits to the spec files, then return to step 2.