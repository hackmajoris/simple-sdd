---
name: simple-sdd-feature-complete
description: Marks the current feature as complete. Two-phase flow — first invocation moves the spec, commits, pushes, and offers to open a PR; re-run with --cleanup after the PR merges to remove the worktree and delete the branch.
type: skill
---

You are completing the current SDD feature. This command has two phases:

1. **Default** (no flags): verify, move the spec to `specs/completed/`, commit, push, offer to open a PR. **Stop.**
2. **`--cleanup`**: run this from the default-branch worktree *after* the PR has merged. It removes the worktree (if any) and deletes the feature branch.

Check the user's arguments. If they include `--cleanup`, jump to **Phase 2** below. Otherwise run **Phase 1**.

## Config values used in this command

```bash
[ -f specs/.sddrc ] && . specs/.sddrc
SPECS_DIR="${SDD_SPECS_DIR:-specs}"
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-${SDD_DEFAULT_BRANCH:-main}}
CHORE="${SDD_COMMIT_PREFIX_CHORE:-chore}"
```

---

## Phase 1 — Complete & push for PR

### Step 1 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository."

### Step 2 — Identify current feature branch

Use the Bash tool to run:
```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
```

If `$BRANCH` equals `$DEFAULT_BRANCH` (or the literal `main`/`develop`), tell the user:
"You are on `<branch>`. Switch to a feature branch before running this command."
Then stop.

Store the branch name — this is the feature name.

### Step 3 — Find the feature spec directory

Use the Bash tool to run:
```bash
ls -d "$SPECS_DIR"/*"$BRANCH"* 2>/dev/null
```

If no directory is found, tell the user:
"No spec directory found matching branch `<branch-name>`. Expected a directory under `$SPECS_DIR/` containing the branch name."
Then stop.

Store the matched directory path (e.g. `specs/2026-04-16-user-authentication`).

### Step 4 — Check for uncommitted changes

Run `git status --porcelain` — if not empty, stop: "You have uncommitted changes. Commit them before completing the feature."

### Step 5 — Verify all checkboxes are ticked

Use the Bash tool to run:
```bash
grep -rn "\- \[ \]" <spec-directory>/plan.md <spec-directory>/validation.md 2>/dev/null
```

If any unchecked boxes are found, tell the user:
"The following items are still open:

<list each file and unchecked line>

Complete all items before marking the feature as done. For manual-check items: run the steps yourself, then tick the boxes (`- [ ]` → `- [x]`)."
Then stop.

### Step 6 — Confirm completion

Use the `AskUserQuestion` tool to ask:
"All checkboxes are ticked. Ready to complete feature `<branch-name>`?

This will:
1. Move `<spec-directory>` → `$SPECS_DIR/completed/<directory-name>`
2. Update `$SPECS_DIR/completed/INDEX.md`
3. Commit the move on the feature branch
4. Push the branch
5. Offer to open a PR (via `gh pr create`) if `gh` is installed"

If the user confirms, continue. Otherwise stop.

### Step 7 — Move spec to completed and update INDEX

Use the Bash tool to run:
```bash
mkdir -p "$SPECS_DIR/completed"
DIR_NAME=$(basename "<spec-directory>")
mv "<spec-directory>" "$SPECS_DIR/completed/$DIR_NAME"
```

Update `$SPECS_DIR/completed/INDEX.md`:
1. Extract the date from `$DIR_NAME` (first `YYYY-MM-DD` prefix).
2. Count the `### Task` groups in the moved `plan.md` for the task count.
3. Read the first non-empty line after the heading in `requirements.md` for a one-line summary (or fall back to the feature name).
4. Append a line of the form:
   ```
   - YYYY-MM-DD — <branch-name> (<N> tasks) — <one-line summary>
   ```
   If `INDEX.md` does not exist, create it with a `# Completed features` heading first.

Commit and push:
```bash
git add "$SPECS_DIR/"
git commit -m "$CHORE: complete feature <branch-name>"
git push -u origin "$BRANCH"
```

### Step 8 — Offer to open a PR

If `command -v gh >/dev/null 2>&1`:

Use the `AskUserQuestion` tool to ask:
"Open a PR against `<DEFAULT_BRANCH>` via `gh pr create --fill`?"

If yes, run:
```bash
gh pr create --base "$DEFAULT_BRANCH" --head "$BRANCH" --fill
```
Print the PR URL.

If `gh` is not available, print the compare URL instead:
```
https://github.com/<owner>/<repo>/compare/<DEFAULT_BRANCH>...<branch>
```
(Parse the owner/repo from `git config --get remote.origin.url`.)

### Step 9 — Stop

Tell the user, verbatim:
"Feature `<branch-name>` spec moved and pushed.

**Next steps:**
1. Review & merge the PR.
2. After the PR is merged, run `/simple-sdd-feature-complete --cleanup` from the `$DEFAULT_BRANCH` worktree. That will remove the feature worktree (if you created one) and delete the branch locally.
3. Then `/simple-sdd-constitution-sync` to update `mission.md` / `tech-stack.md` if needed.

Recommended: `/clear` before the cleanup step."

**Do not switch branches, remove worktrees, or delete the branch in this phase.** The PR may need revisions.

---

## Phase 2 — `--cleanup` after PR merge

### Step 1 — Validate location

Run `git rev-parse --show-toplevel` to get the current worktree path, and `git rev-parse --abbrev-ref HEAD` to get the current branch. If the current branch is *not* `$DEFAULT_BRANCH`, tell the user:
"Run `--cleanup` from the `$DEFAULT_BRANCH` worktree (e.g. `cd <main-worktree>`). Current branch: `<branch>`."
Then stop.

### Step 2 — Find the feature branch to clean up

Look at recent local branches and ask the user which to clean up (or accept a branch name from the arguments, e.g. `/simple-sdd-feature-complete --cleanup user-authentication`).

```bash
git branch --format='%(refname:short)' | grep -v "^$DEFAULT_BRANCH$"
```

Store the chosen `$BRANCH`.

### Step 3 — Verify the PR has merged

```bash
git fetch origin --prune
STATE=$(gh pr view "$BRANCH" --json state -q .state 2>/dev/null || echo UNKNOWN)
```

If `$STATE` is not `MERGED`, tell the user:
"PR for `<branch>` is in state `<STATE>` — cleanup is only safe after merge. If you merged via a different tool and `gh` can't see it, confirm the branch is fully integrated into `<DEFAULT_BRANCH>` (`git log $DEFAULT_BRANCH..$BRANCH` should be empty, except for squash-merge scenarios), then re-run with `--force-cleanup`."
Then stop (unless the user passed `--force-cleanup`).

### Step 4 — Pull the default branch

```bash
git pull --ff-only origin "$DEFAULT_BRANCH"
```

### Step 5 — Remove worktree (if any) and delete branch

If there's a worktree attached to the feature branch, remove it:
```bash
git worktree list --porcelain | awk -v b="$BRANCH" '/^worktree / {p=$2} /^branch / {if ($2 == "refs/heads/"b) print p}' \
  | xargs -I{} git worktree remove {}
```

Then delete the local branch:
```bash
git branch -d "$BRANCH" 2>/dev/null || git branch -D "$BRANCH"
```

Offer to delete the remote branch too (don't do it automatically — some teams auto-delete via GitHub settings):

"Delete the remote branch too? (`git push origin --delete $BRANCH`)" — via `AskUserQuestion`.

### Step 6 — Report

Tell the user:
"Feature `<branch>` cleaned up.
- Worktree removed (if any)
- Local branch deleted
- Default branch (`<DEFAULT_BRANCH>`) pulled to latest

Run `/simple-sdd-constitution-sync` to check whether `mission.md` or `tech-stack.md` need updating. Then `/simple-sdd-feature-new` when ready."
