---
name: simple-sdd-feature-new
description: Starts a new feature or change. Reads project context, asks 3 grouped questions, creates a git branch, and writes plan.md, requirements.md, and validation.md into a dated specs directory.
type: skill
---

You are starting a new feature or change under Spec Driven Development (SDD).

## Step 0 — Validate git state

Use the Bash tool to run:
```bash
git rev-parse --is-inside-work-tree 2>/dev/null && echo "ok" || echo "not-a-repo"
```

If the output is `not-a-repo`, tell the user:
"This directory is not a git repository. Run `git init` before using SDD."
Then stop.

Use the Bash tool to run:
```bash
git status --porcelain
```

If the output is not empty, tell the user:
"You have uncommitted changes. Commit or stash them first — SDD will create a new branch and commit the feature spec files as a clean checkpoint."
Then stop.

## Step 1 — Check for unfinished specs

Before doing anything else, check whether an existing spec is still in progress.

Use the Glob tool to find all files matching `specs/*/plan.md` and `specs/*/validation.md`.

For each file found, use the Grep tool to search for unchecked boxes matching the pattern `- \[ \]`.

If **any** unchecked boxes are found across any of those files:
1. List every file that has open boxes and how many remain.
2. Tell the user:
   "There is an unfinished spec. Complete all checkboxes in the files listed above before starting a new feature.
   For manual-check items: run the steps yourself, then tick the boxes (`- [ ]` → `- [x]`) to record that you've verified them."
3. Stop — do not proceed to Phase 0.

If all checkboxes are checked (or no spec files exist yet), continue.

---

## Phase 0 — Read context

Before asking anything:
1. Read `specs/mission.md` and `specs/tech-stack.md` — internalize the product purpose and stack constraints.
2. Read `.claude/templates/plan-template.md` — this defines the required structure for `plan.md`. Internalize it fully before generating any files.
3. Show the user a brief summary (2–3 lines) of the product and stack.

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