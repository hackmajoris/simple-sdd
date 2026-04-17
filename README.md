# simple-sdd

**simple ssd** — Spec Driven Development a tool-agnostic workflow that structures your work into markdown spec files before any code is written. Works with Claude Code, GitHub Copilot, and OpenCode or any AI environment.

## tl;dr

```bash
# 1. Install (pinned, verified — see "Install" below for the one-liner)
VERSION=v1.0.0
curl -sSL -o install.sh "https://github.com/hackmajoris/simple-sdd/releases/download/${VERSION}/install.sh"
bash install.sh

# 2. Use: bootstrap once, then one feature at a time
/simple-sdd-setup              # ← once per project
/simple-sdd-feature-new        # ← once per feature
/simple-sdd-feature-implement  # ← one task per session; repeat until done
/simple-sdd-feature-complete   # ← push, open PR; after merge run with --cleanup
```

Full example session is at the bottom of this README.

---

Instead of diving straight into code, SDD asks you to answer a few focused questions first. Your AI assistant uses your answers to generate a "constitution" for the project — mission and tech stack — then helps you create a detailed spec each time you start a new feature. Implementation happens one task at a time, each in a fresh session, with a commit after every task.

---

## Why SDD?

- **Clarity before code.** Writing specs forces you to articulate what you're building and why, catching ambiguity early.
- **Shared context.** Specs live in the repo alongside the code. Any collaborator (human or AI) can pick up where you left off.
- **Feature-by-feature discipline.** Each feature gets its own directory with requirements, a task plan, and validation criteria — so you always know what "done" looks like before you start.
- **Works for new and existing projects.** New projects get scaffolded from scratch. Existing codebases get analyzed and filled in interactively.
- **Fresh context, better results.** Each command recommends `/clear` between sessions so every task starts with a clean, focused context. You can skip it when the next task is genuinely tiny.
- **Parallel work, safely.** Opt into git worktrees and run multiple features side-by-side without branch-switching chaos.

---

## Install

The recommended flow is to **pin a version** and **verify the checksum** before running. Pick the latest tag from [Releases](https://github.com/hackmajoris/simple-sdd/releases) and substitute it for `VERSION` below:

```bash
VERSION=v1.0.0   # replace with the latest release tag
curl -sSL -o install.sh "https://github.com/hackmajoris/simple-sdd/releases/download/${VERSION}/install.sh"
curl -sSL -o SHA256SUMS "https://github.com/hackmajoris/simple-sdd/releases/download/${VERSION}/SHA256SUMS"
sha256sum -c SHA256SUMS --ignore-missing   # on macOS: shasum -a 256 -c SHA256SUMS
less install.sh            # skim it
bash install.sh            # run it
```

Want the one-liner (unpinned, unverified — fine for throwaway repos)?

```bash
curl -sSL https://github.com/hackmajoris/simple-sdd/releases/latest/download/install.sh | bash
```

The script auto-detects your AI tool from the project's directory structure. Pass `--tool` to set it explicitly:

```bash
bash install.sh --tool claude     # Claude Code
bash install.sh --tool copilot    # GitHub Copilot
bash install.sh --tool opencode   # OpenCode
```

Depending on the tool, commands and templates are installed under:

| Tool | Commands | Templates | Config injection |
|------|----------|-----------|-----------------|
| Claude Code | `.claude/commands/` | `.claude/templates/` | `.claude/CLAUDE.md` |
| GitHub Copilot | `.github/prompts/` | `.github/prompts/` | `.github/copilot-instructions.md` |
| OpenCode | `.opencode/commands/` | `.opencode/templates/` | `RULES.md` |

Commands are always overwritten with the latest version. Config injection is idempotent (the section is only added once).

---

## Update

Re-run the install command at a newer `VERSION`. Existing files are overwritten with the latest version. Config injection stays idempotent.

```bash
VERSION=v1.1.0
curl -sSL -o install.sh "https://github.com/hackmajoris/simple-sdd/releases/download/${VERSION}/install.sh"
bash install.sh --tool claude
```

`/simple-sdd-help` also checks for a newer release each time it runs and prints a reminder if you're stale.

---

## Uninstall & dry-run

Preview what the installer will touch without writing anything:

```bash
bash install.sh --dry-run --tool claude
```

Remove everything the installer added (commands, templates, and the injected config block):

```bash
bash install.sh --uninstall --tool claude
# or, to uninstall for every tool at once:
bash install.sh --uninstall --tool all
```

The uninstaller leaves `.claude/` (or `.opencode/`, `.github/`) in place in case you have other content there — only files it installed are removed.

---

## How it works

SDD follows a fixed lifecycle. Each step is a single slash command:

```
/simple-sdd-setup               ← once per project
/simple-sdd-feature-new         ← once per feature
/simple-sdd-feature-implement   ← once per task (repeat until done)
/simple-sdd-feature-update      ← when requirements change mid-feature
/simple-sdd-feature-status      ← check progress at any time
/simple-sdd-feature-complete    ← when all tasks are done (then --cleanup after PR merge)
/simple-sdd-feature-abandon     ← when you want to start over cleanly
/simple-sdd-constitution-sync   ← after completing a feature
/simple-sdd-help                ← quick command reference
```

Between every command, the assistant recommends you run `/clear` for a fresh context. You can type `skip` to continue in the same session when the next task is genuinely tiny. This keeps sessions focused and prevents context bleed across tasks.

---

## Configuration

SDD reads optional overrides from `specs/.sddrc` (created for you by `/simple-sdd-setup` with all values commented out). It's a plain shell file — each command `source`s it. Defaults shown below:

```sh
# SDD_SPECS_DIR=specs                # where spec directories live
# SDD_DEFAULT_BRANCH=main            # overridden by origin/HEAD if detected
# SDD_TEMPLATE_PATH=.claude/templates/plan-template.md
# SDD_USE_WORKTREES=false            # true → a git worktree per feature
# SDD_WORKTREE_DIR=..                # parent dir for worktrees
# SDD_COMMIT_PREFIX_CHORE=chore      # for teams with conventional-commits rules
# SDD_COMMIT_PREFIX_FEAT=feat
# SDD_COMMIT_SCOPE_FORMAT=({{branch}})   # empty string disables the scope suffix
```

You don't have to edit `.sddrc` — the defaults cover the common case. Reach for it when your repo uses a non-`main` default branch, you want to run features in parallel worktrees, or your team enforces a particular commit style.

---

## Worktrees for parallel work

By default SDD stays inside a single checkout: one feature at a time on a feature branch. If you need to work on multiple features (bug fix on the side while a bigger feature is in progress), set `SDD_USE_WORKTREES=true` in `specs/.sddrc`.

With worktrees enabled, `/simple-sdd-feature-new` creates a dedicated git worktree next to your repo:

```
~/code/myproject/              ← main worktree, on your default branch
~/code/myproject-user-auth/    ← worktree on user-auth branch
~/code/myproject-oauth-spike/  ← worktree on oauth-spike branch
```

Each worktree has its own `specs/<date>-<feature>/` directory and its own "one in-progress feature" scope. Switch between features by `cd`-ing, not by branch-switching.

`/simple-sdd-feature-complete` pushes the branch and opens a PR; after the PR merges, run `/simple-sdd-feature-complete --cleanup` from your main worktree to remove the extra worktree and delete the branch.

---

## Commands

### `/simple-sdd-setup`

**When:** Once at the start of a project.

**What it does:**

1. Validates that the directory is a git repo with a clean working tree.
2. Checks if `specs/mission.md` and `specs/tech-stack.md` already exist. If they do, it tells you the project is already configured and suggests `/simple-sdd-feature-new`.
3. Asks whether this is a **new project** or an **existing project**.
4. Asks two grouped question sets (mission, then tech stack) — 3 questions each — before writing anything to disk.
5. Writes `specs/mission.md`, `specs/tech-stack.md`, and `specs/.sddrc` (config file with commented defaults).
6. Shows you the generated files and asks for confirmation before committing.
7. Commits the spec files with `chore: add SDD spec files`.

**For new projects:** Claude reads any `README.md` or brief you have, then asks from scratch.

**For existing projects:** Claude reads your codebase first — manifests, directory structure, docs — and pre-fills the answers based on what it finds. You only correct or expand.

**Example:**

```
/simple-sdd-setup

Claude: Is this a new project or an existing one?
You: new

Claude: [reads README.md]
       Found: no existing docs. Let me ask a few questions.

       1. What is this product? Who is it for?
       2. What problem does it solve?
       3. What does success look like?

You: [answers]

Claude: [asks tech stack questions]
You: [answers]

Claude: Here's what I'll write:
        - specs/mission.md
        - specs/tech-stack.md
        Ready to commit?

You: yes

Claude: Committed. Run /clear when ready.
```

---

### `/simple-sdd-feature-new`

**When:** Whenever you're ready to start a new piece of work.

**What it does:**

1. Validates git state: must be on your default branch (detected from `origin/HEAD`, or `SDD_DEFAULT_BRANCH` in `specs/.sddrc`). Unrelated working-tree changes are offered to stash rather than abort.
2. Scans the current worktree's `specs/` for unchecked boxes. If any open tasks are found, it stops and tells you to finish them first. (Parallel features live in separate worktrees — see the Worktrees section.)
3. Reads `specs/mission.md`, `specs/tech-stack.md`, and the plan template for context.
4. Asks three grouped questions: what you're building, why now, and any constraints.
5. Creates a git branch (kebab-case feature name, no date). If `SDD_USE_WORKTREES=true`, creates a dedicated worktree for the branch and prints a `cd` instruction.
6. Creates `specs/<date>-<feature-name>/` and writes three files: `requirements.md`, `plan.md`, `validation.md`.
7. Shows the files and asks for confirmation before committing.
8. Commits the spec with `chore: add SDD spec for <feature-name> (<N> tasks)`.

**Example:**

```
/simple-sdd-feature-new

Claude: [reads specs/mission.md, specs/tech-stack.md]
        Building: a spec-driven development plugin for Claude Code.
        Stack: bash, markdown, GitHub Actions.

        1. What are you building or changing?
        2. Why now? What's the trigger for this work?
        3. Any constraints? Dependencies, things not to touch?

You: 1. User authentication with JWT
     2. Needed before the beta launch
     3. Must not change the existing session middleware

Claude: Creating branch `user-authentication`...
        Writing specs/2026-04-16-user-authentication/
        → requirements.md
        → plan.md  (4 task groups)
        → validation.md

        Ready to commit?

You: yes

Claude: Committed. Run /clear, then /simple-sdd-feature-implement.
```

---

### `/simple-sdd-feature-implement`

**When:** After committing the spec — and after every `/clear` until all tasks are done.

**What it does:**

1. Finds the single in-progress spec directory (outside `specs/completed/`). Stops if none or more than one is found.
2. Switches to the feature branch.
3. Counts checked vs. unchecked tasks in `plan.md`.
   - **First run (0 tasks done):** reads the spec and dives straight into Task 1.
   - **Resuming (some tasks done):** reconstructs context from `git log` and `git diff` first, then continues from the first unchecked task.
4. Implements every item in the next unchecked task group. Does not start the following task.
5. Marks every checkbox in the completed task as `[x]` in `plan.md`.
6. Commits all changes with `feat(<branch>): complete task N — <task name>` (configurable via `SDD_COMMIT_PREFIX_FEAT` and `SDD_COMMIT_SCOPE_FORMAT`).
7. If tasks remain: recommends you run `/clear` then `/simple-sdd-feature-implement` again.
   If all tasks are done: prompts you to run `/simple-sdd-feature-complete`.

**Example (first run):**

```
/simple-sdd-feature-implement

Claude: Starting `user-authentication` — 0 of 4 tasks done.

        Next task:
        ### Task 1: Database schema
        - [ ] Create users table migration
        - [ ] Add indexes on email and created_at
        - [ ] Write migration tests
        - [ ] Run tests

        Let's go.

        [implements, marks [x], commits]

        Task 1 complete and committed.
        Run /clear then /simple-sdd-feature-implement to continue with Task 2.
```

**Example (resuming after a break):**

```
/simple-sdd-feature-implement

Claude: Resuming `user-authentication` — 2 of 4 tasks done.
        Done so far: users table, JWT helpers (src/auth/, migrations/)
        Next: Task 3 — Login endpoint

        [implements Task 3, marks [x], commits]

        Task 3 complete and committed.
        Run /clear then /simple-sdd-feature-implement to continue with Task 4.
```

---

### `/simple-sdd-feature-update`

**When:** Requirements change while a feature is in progress.

**What it does:**

1. Validates git state: must be on a feature branch (not your default branch) with a matching spec directory.
2. Reads the current `plan.md`, `requirements.md`, and `validation.md`.
3. Asks one open question: what needs to change?
4. Updates only the relevant spec files:
   - New tasks get a ➕ prefix in `plan.md`
   - Blockers get a ⚠️ prefix
   - Scope changes go into `requirements.md`
   - New acceptance criteria go into `validation.md`
5. Shows a diff-style summary of the spec changes and asks for confirmation.
6. Commits the updated spec.
7. If code changes are needed (new tasks added, approach changed), implements them following the updated plan. If it's a spec-only update, tells you to continue with `/simple-sdd-feature-implement`.

**Example:**

```
/simple-sdd-feature-update

Claude: [reads current spec]
        What needs to change?

You: We need to support OAuth in addition to JWT. Google login is required for the beta.

Claude: Here's what I'll update:
        requirements.md — added OAuth to scope; Google provider required
        plan.md         — ➕ Task 5: OAuth integration (Google provider)
        validation.md   — added: Google login flow must work end to end

        Does this look right?

You: yes

Claude: Spec committed. New task added — run /simple-sdd-feature-implement to pick it up.
```

---

### `/simple-sdd-feature-complete`

**When:** All tasks in `plan.md` and `validation.md` are checked.

Two-phase flow:

**Phase 1 — default invocation (from the feature branch/worktree):**
1. Validates git state: must be on a feature branch with a clean working tree.
2. Finds the matching spec directory.
3. Checks for any unchecked boxes in `plan.md` and `validation.md`. If any remain, it lists them and stops.
4. Asks for confirmation, listing exactly what will happen.
5. Moves the spec directory to `specs/completed/<directory-name>` and appends a line to `specs/completed/INDEX.md`.
6. Commits the move with `chore: complete feature <branch-name>`.
7. Pushes the branch and (if `gh` is installed) offers to open a PR with `gh pr create --fill`.
8. **Stops.** Does not switch branches, does not delete the worktree — the PR may need revisions.

**Phase 2 — `--cleanup` (from the default-branch worktree, after the PR merges):**
1. Verifies the PR is merged via `gh pr view <branch> --json state -q .state` (handles squash-merge).
2. Pulls the default branch.
3. Removes the feature worktree (if any) and deletes the local feature branch.
4. Offers (not auto-runs) `git push origin --delete <branch>`.

> **Note on validation.md checkboxes:** some items in `validation.md` are manual checks (e.g. "test the login flow in the browser"). Run those yourself and tick the boxes before running this command.

**Example:**

```
/simple-sdd-feature-complete

Claude: All checkboxes ticked. Ready to complete `user-authentication`?

        This will:
        1. Move specs/2026-04-16-user-authentication/ → specs/completed/
        2. Update specs/completed/INDEX.md
        3. Commit and push the branch
        4. Offer to open a PR

You: yes

Claude: Spec moved, committed, pushed. PR opened: <url>
        After the PR merges, run /simple-sdd-feature-complete --cleanup
        from your main worktree.

# … PR gets reviewed and merged …

/simple-sdd-feature-complete --cleanup

Claude: PR is merged. Pulling main, removing worktree, deleting branch.
        Done. Run /simple-sdd-constitution-sync to sync mission/tech-stack.
```

---

### `/simple-sdd-feature-abandon`

**When:** You've decided the current feature's approach is wrong and want to start over cleanly.

**What it does:**

1. Identifies the current feature (branch + matching spec directory).
2. Lists exactly what will be removed — branch, spec directory, worktree (if any), and the number of commits that will become unreferenced.
3. Requires two confirmations (the second is a typed phrase).
4. Removes the worktree (if any), deletes the local branch, deletes the spec directory.
5. Reminds you that the commits are still recoverable via `git reflog` for ~90 days.

> **Note:** this does NOT force-reset any branch. Commits stay in the reflog for recovery. If you want to restore: `git reflog | grep <branch>` then `git branch <branch> <sha>`.

### `/simple-sdd-feature-status`

**When:** Any time you want to check where you are in the current feature.

**What it does:**

1. Finds the single in-progress spec directory (outside `specs/completed/`).
2. Reads `plan.md` and counts all `[x]` and `[ ]` checkbox lines.
3. Prints a summary: feature name, tasks done vs. total, full list of completed and remaining items.
4. Tells you what to run next — either `/simple-sdd-feature-implement` or `/simple-sdd-feature-complete`.

**Example:**

```
/simple-sdd-feature-status

Claude: Feature: `user-authentication`
        Progress: 2/4 tasks complete

        Done (2):
        - [x] Create users table migration
        - [x] Add indexes on email and created_at
        ...

        Remaining (2):
        - [ ] Login endpoint
        - [ ] Token refresh logic

        Run /simple-sdd-feature-implement to continue.
```

---

### `/simple-sdd-constitution-sync`

**When:** After completing a feature. Also prompted automatically by `/simple-sdd-feature-complete`.

**What it does:**

1. Reads `specs/mission.md` and `specs/tech-stack.md` fully.
2. Finds the reference feature — the in-progress spec if one exists, otherwise the most recently completed one.
3. Reads `requirements.md` for that feature, then reads `git log` and `git diff --stat` to see what actually changed.
4. Compares the code changes against the constitution and identifies drift: new libraries, infrastructure changes, shifted product scope, new integrations.
5. Proposes a concrete diff-style summary of changes to `mission.md` and/or `tech-stack.md`.
6. Asks for confirmation (or adjustments) before writing anything.
7. Applies the edits and commits with `chore: sync constitution after <feature-name>`.

If no meaningful drift is found, it tells you the files are already accurate and stops.

**Example:**

```
/simple-sdd-constitution-sync

Claude: [reads mission.md, tech-stack.md]
        [reads specs/completed/2026-04-16-user-authentication/requirements.md]
        [reads git log and diff]

        mission.md
          → no changes

        tech-stack.md
          → add: jsonwebtoken 9.x (JWT signing)
          → add: Google OAuth 2.0 via passport-google-oauth20
          → add: Redis (session store for OAuth state)

        Do these updates look right? Confirm to apply — or tell me what to adjust.

You: yes

Claude: Constitution updated and committed.
        mission.md and tech-stack.md now reflect the current state of the project.
```

---

### `/simple-sdd-help`

**When:** Any time you want a quick reference of all commands.

**What it does:**

Prints the full command reference — every command, what it does, when to use it, and a typical workflow summary — verbatim. Nothing is read from disk; this is a static reference.

**Example:**

```
/simple-sdd-help

Claude: # Simple SDD — Command Reference
        ...
        [full command list and typical workflow]
        ...
        Run /simple-sdd-help at any time to see this again.
```

---

## What gets generated

### Project setup (`/simple-sdd-setup`)

```
specs/
  mission.md      — what the product is, the problem it solves, definition of success
  tech-stack.md   — languages, frameworks, infrastructure, constraints
  .sddrc          — optional config overrides (shell syntax, all values commented by default)
```

### Feature spec (`/simple-sdd-feature-new`)

```
specs/
  2026-04-16-user-authentication/
    requirements.md   — scope (in/out), context, constraints, key decisions
    plan.md           — numbered task groups with checkboxes, ordered by dependency
    validation.md     — acceptance criteria, manual checks, definition of done

specs/completed/
  INDEX.md                         — auto-maintained list of every completed feature
  2026-04-10-previous-feature/     — moved here by /simple-sdd-feature-complete
    ...
```

`plan.md` follows `src/templates/plan-template.md`, which defines:
- **Overview** and **Context** sections
- **Development Approach** and **Testing Strategy**
- **Implementation Steps** — `### Task N:` groups, each ending with write-and-run-tests checkboxes
- **Technical Details** — data structures, parameters, flow
- **Post-Completion** — manual verification steps (no checkboxes)

The git branch uses the kebab-case feature name without the date prefix (e.g. `user-authentication`).

---

## Full example session

```
# 1. Install (once per project — see "Install" above for the pinned+verified flow)
curl -sSL https://github.com/hackmajoris/simple-sdd/releases/latest/download/install.sh | bash

# 2. Set up project specs
/simple-sdd-setup
→ new or existing?
→ [mission questions] → [tech stack questions]
→ specs/mission.md + specs/tech-stack.md + specs/.sddrc written and committed
→ Recommended: /clear before the next step.

/clear

# 3. Start a feature
/simple-sdd-feature-new
→ [reads specs/ for context]
→ [3 questions about the feature]
→ branch `user-authentication` created
→ specs/2026-04-16-user-authentication/ written and committed
→ Recommended: /clear before /simple-sdd-feature-implement.

/clear

# 4. Implement — one task per session
/simple-sdd-feature-implement
→ Task 1: Database schema — implemented and committed
→ Recommended: /clear before the next /simple-sdd-feature-implement.

/clear
/simple-sdd-feature-implement
→ Task 2: JWT helpers — implemented and committed

/clear

# 5. Mid-feature change request
/simple-sdd-feature-update
→ "add Google OAuth support"
→ spec updated: requirements.md, plan.md (➕ Task 5), validation.md
→ committed

/clear
/simple-sdd-feature-implement  ← Task 3
/clear
/simple-sdd-feature-implement  ← Task 4
/clear
/simple-sdd-feature-implement  ← Task 5 (new OAuth task)

# 6. Close the feature — phase 1: push & open PR
/simple-sdd-feature-complete
→ all checkboxes verified
→ spec moved to specs/completed/, INDEX.md updated
→ branch pushed, PR opened

# … review happens, PR is merged …

# 7. Clean up the branch/worktree (from main worktree)
/simple-sdd-feature-complete --cleanup
→ verifies the PR is merged
→ pulls main, removes worktree (if any), deletes local branch

# 8. Sync the constitution
/simple-sdd-constitution-sync
→ reads mission.md and tech-stack.md
→ compares against feature diff and requirements
→ proposes targeted edits (e.g. new libraries, infra changes)
→ committed after confirmation
→ Run /simple-sdd-feature-new to start the next feature.
```

---

---
