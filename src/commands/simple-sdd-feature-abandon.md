---
name: simple-sdd-feature-abandon
description: Abandons an in-progress feature. Removes the worktree (if any), deletes the feature branch, and drops the spec directory. Commits remain recoverable via `git reflog`.
type: skill
---

You are helping the user cleanly abandon an in-progress feature. This is destructive — branch and spec are removed — but commits stay recoverable in `git reflog` for ~90 days.

## Step 1 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository."

Source the config file if it exists so overrides apply:
```bash
[ -f specs/.sddrc ] && . specs/.sddrc
```

Determine the default branch:
```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-${SDD_DEFAULT_BRANCH:-main}}
```

## Step 2 — Identify the feature

Get the current branch:
```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
```

If `BRANCH` equals `$DEFAULT_BRANCH` or is `main`/`develop`, stop and tell the user:
"You are on `<branch>`. Switch to the feature branch (or worktree) you want to abandon first."

Find the matching spec directory:
```bash
SPECS_DIR="${SDD_SPECS_DIR:-specs}"
SPEC_PATH=$(ls -d "$SPECS_DIR"/*"$BRANCH"* 2>/dev/null | head -1)
```

If no spec is found, tell the user:
"No spec directory found matching `<branch>` under `<SPECS_DIR>/`. If you just want to drop the branch, run `git branch -D <branch>` manually."
Then stop.

## Step 3 — Detect worktree mode

```bash
WORKTREE_PATH=$(git rev-parse --show-toplevel)
MAIN_WORKTREE=$(git worktree list --porcelain | awk '/^worktree / {print $2; exit}')
IN_WORKTREE=false
if [ "$WORKTREE_PATH" != "$MAIN_WORKTREE" ]; then
  IN_WORKTREE=true
fi
```

## Step 4 — Show the plan and double-confirm

Print a summary that lists, explicitly:
- Branch to delete: `<branch>`
- Spec directory to delete: `<SPEC_PATH>`
- Worktree to remove: `<WORKTREE_PATH>` (only if `IN_WORKTREE=true`)
- Number of commits that will become unreferenced: `git rev-list --count $DEFAULT_BRANCH..$BRANCH`

Also list the unmerged commit subjects so the user knows what they're dropping:
```bash
git log --oneline "$DEFAULT_BRANCH..$BRANCH"
```

Then use `AskUserQuestion` to ask:
"Abandon feature `<branch>`? This is destructive."

If the user answers anything other than yes, stop.

Then ask a second confirmation:
"Are you absolutely sure? Type `abandon <branch>` to proceed."

Require the exact phrase. Anything else → stop.

## Step 5 — Execute

**If `IN_WORKTREE=true`:**
1. The worktree cannot be removed from inside itself. Instruct the user:
   "Please `cd $MAIN_WORKTREE` and re-run `/simple-sdd-feature-abandon <branch>`."
   Then stop. (A future version may spawn a helper; for now this is the safest path.)

**If `IN_WORKTREE=false` (regular branch checkout):**
1. Switch to default branch:
   ```bash
   git checkout "$DEFAULT_BRANCH"
   ```
2. Delete the spec directory:
   ```bash
   rm -rf "$SPEC_PATH"
   ```
3. Force-delete the feature branch:
   ```bash
   git branch -D "$BRANCH"
   ```
4. If a matching worktree exists elsewhere, remove it:
   ```bash
   git worktree list --porcelain | awk -v b="$BRANCH" '/^worktree / {p=$2} /^branch / {if ($2 == "refs/heads/"b) print p}' \
     | xargs -I{} git worktree remove --force {}
   ```

## Step 6 — Report

Tell the user:
"Feature `<branch>` abandoned.
- Spec directory removed
- Branch deleted
- Worktree removed (if applicable)

**Recovery:** the commits you dropped are still in `git reflog` for ~90 days. To restore:
```
git reflog | grep <branch>
git branch <branch> <sha-from-reflog>
```

Run `/simple-sdd-feature-new` to start a different feature, or `/clear` to start fresh."
