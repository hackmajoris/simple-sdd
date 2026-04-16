---
name: simple-sdd-help
description: Shows all available simple-sdd commands, what they do, and when to use them.
type: skill
---

Tell the user the following, verbatim:

---

# Simple SDD — Command Reference

Spec Driven Development (SDD) keeps a written spec in sync with your code. Every feature lives on its own branch with three files: `plan.md`, `requirements.md`, and `validation.md`. Progress is tracked with checkboxes.

---

## Setup

### `/simple-sdd-setup`
**One-time project initialization.**
Creates `specs/mission.md` (product purpose) and `specs/tech-stack.md` (languages, infra, constraints).
Works for both new projects and existing codebases — it will read what's already there before asking questions.

> Run this once before anything else.

---

## Feature lifecycle

Features follow a fixed sequence: **new → implement → complete**.
Use **update** and **status** at any point in between.

### `/simple-sdd-feature-new`
**Start a new feature.**
Asks 3 questions about what you're building, why, and any constraints. Creates a git branch and writes the three spec files. Commits them as a clean checkpoint.

> Requires a clean working tree. Only one feature can be in progress at a time.

---

### `/simple-sdd-feature-implement`
**Implement the next task.**
Reads `plan.md`, finds the first unchecked task, and implements it. When done, marks the task `[x]` and commits. Designed to be run once per session — run `/clear` between sessions for clean context.

> Works as both a first run and a resume — it checks what's already been done.

---

### `/simple-sdd-feature-update`
**Apply a change to the current feature.**
Use this when requirements shift mid-flight. It reads your change request, updates the spec files first, asks you to confirm, then applies any necessary code changes.

> Always updates spec before code — keeps plan.md as the source of truth.

---

### `/simple-sdd-feature-status`
**See what's done and what remains.**
Reads the checkboxes in `plan.md` and prints a summary: tasks completed, tasks remaining, and what to run next.

> Use this to orient yourself before resuming work or to share progress.

---

### `/simple-sdd-feature-complete`
**Close a finished feature.**
Verifies all checkboxes in `plan.md` and `validation.md` are ticked, moves the spec to `specs/completed/`, commits, and switches back to `main` or `develop`.

> Will stop if any boxes are unchecked — complete them manually first.

---

---

## Constitution

### `/simple-sdd-constitution-sync`
**Keep `mission.md` and `tech-stack.md` accurate.**
Reads the current or most recently completed feature's spec and git diff, identifies drift (new libraries, infra changes, shifted scope), proposes targeted edits, and commits them after confirmation.

> Run this after completing a feature. Also triggered as a prompt inside `/simple-sdd-feature-complete`.

---

## Typical workflow

```
/simple-sdd-setup               ← once per project

/simple-sdd-feature-new         ← validates constitution, then starts feature
/clear
/simple-sdd-feature-implement   ← implement task 1
/clear
/simple-sdd-feature-implement   ← implement task 2
...
/simple-sdd-feature-complete    ← done, prompts to sync constitution
/simple-sdd-constitution-sync   ← update mission.md / tech-stack.md
```

If scope changes mid-feature:
```
/simple-sdd-feature-update      ← adjust spec + code
```

To check where you are:
```
/simple-sdd-feature-status
```

---

Run `/simple-sdd-help` at any time to see this again.
