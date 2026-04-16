# simple-sdd

A [Claude Code](https://claude.ai/code) plugin for **Spec Driven Development (SDD)** — a lightweight, interactive workflow that turns a blank project (or an existing codebase) into a structured set of markdown spec files before any implementation begins.

Instead of diving straight into code, SDD asks you to answer a few focused questions first. Claude uses your answers to generate a small "constitution" for the project — mission and tech stack — then helps you create detailed feature specs each time you start a new chunk of work.

---

## Why SDD?

- **Clarity before code.** Writing specs forces you to articulate what you're building and why, catching ambiguity early.
- **Shared context.** Specs live in the repo alongside the code. Any collaborator (human or AI) can pick up where you left off.
- **Feature-by-feature discipline.** Each feature gets its own directory with a plan, requirements, and validation criteria — so you always know what done looks like before you start.
- **Works for new and existing projects.** New projects get scaffolded from scratch. Existing projects get reverse-engineered from the codebase and then filled in interactively.
- **Fresh context, better results.** Each command prompts you to run `/clear` when done, so the next task always starts with a clean session.

---

## Install

Run this from the root of your project:

```bash
curl -sSL https://github.com/hackmajoris/simple-sdd/releases/latest/download/install.sh | bash
```

This installs into your project directory:
- `.claude/commands/` — all SDD slash commands
- `.claude/templates/` — plan template used when generating feature specs
- `.claude/CLAUDE.md` — injects a section that reminds Claude to prompt `/clear` at natural breakpoints

Commands that are already installed are skipped. The CLAUDE.md injection is idempotent.

> **Note:** Commands are project-scoped. Each project gets its own copy. Run the install command once per project.

---

## Workflow

### Step 1 — Set up project specs

Run once at the start of a project:

```
/simple-sdd-setup
```

If the project is already configured (`specs/mission.md` and `specs/tech-stack.md` exist), Claude will tell you and suggest running `/simple-sdd-feature-new` instead.

Otherwise, Claude asks whether this is a **new project** or an **existing project** and runs the appropriate flow internally. Claude reads your `README.md` and any other context files first, then asks **2 grouped question sets** (mission, tech stack) before writing anything to disk.

When done, Claude prompts you to run `/clear` before the next step.

---

### Step 2 — Start a feature

Run whenever you're ready to work on a new piece of functionality:

```
/simple-sdd-feature-new
```

Claude reads your existing specs for context, then asks **3 grouped questions** about what you're building. After your answers, it:

1. Creates a git branch
2. Creates a dated directory under `specs/`
3. Writes `requirements.md`, `plan.md` (following the plan template), and `validation.md`

When done, Claude prompts you to run `/clear` before starting implementation.

---

## Commands reference

| Command | When to use |
|---|---|
| `/simple-sdd-setup` | Start here — detects if already configured, otherwise runs full setup |
| `/simple-sdd-feature-new` | Start a new feature or change |
| `/simple-sdd-feature-complete` | Mark the current feature as done — verifies all checkboxes, moves spec to `specs/completed/`, switches back to base branch |
| `/simple-sdd-feature-implement` | Implement one task — works for both first run and resuming after a break. Run `/clear` between tasks. |
| `/simple-sdd-feature-update` | Apply a change request — updates the spec first, confirms, then applies code changes if needed |

---

## What gets generated

### Project setup

```
specs/
  mission.md     — what the product is, the problem it solves, definition of success
  tech-stack.md  — languages, frameworks, infrastructure, constraints
```

**For new projects**, Claude asks you to describe everything from scratch.

**For existing projects**, Claude first analyzes the codebase — reading manifests, directory structure, existing docs — and pre-fills answers based on what it finds. You only need to correct or expand.

---

### Feature work

```
specs/
  2026-04-16-user-authentication/
    requirements.md   — scope (in/out), context, constraints, key decisions
    plan.md           — numbered task groups with checkboxes, ordered by dependency
    validation.md     — acceptance criteria, manual checks, definition of done
```

`plan.md` follows the structure defined in `.claude/templates/plan-template.md`, which includes mandatory test tasks per group, a post-completion section, and progress tracking conventions.

The git branch uses the kebab-case feature name (without the date).

---

## Example session

```
# Install (once per project)
curl -sSL https://github.com/hackmajoris/simple-sdd/releases/latest/download/install.sh | bash

# Set up specs
/simple-sdd-setup
> New or existing? → new
> [3 questions about mission]
> [3 questions about tech stack]
> specs/ written. Run /clear when ready.

/clear

# Start a feature
/simple-sdd-feature-new
> [reads specs/ for context]
> [3 questions about the feature]
> Branch created. specs/2026-04-16-user-authentication/ written.
> Run /clear before starting implementation.

/clear

# Implement one task at a time
/simple-sdd-feature-implement
> [implements Task 1, commits, prompts /clear]

/clear
/simple-sdd-feature-implement
> [implements Task 2, commits, prompts /clear]

# When all tasks done
/simple-sdd-feature-complete
```

---

## Update

Re-run the install command from your project root. Existing files are skipped — delete a file first if you want to overwrite it with the latest version.

```bash
curl -sSL https://github.com/hackmajoris/simple-sdd/releases/latest/download/install.sh | bash
```

---

## Release

Tag a version to trigger a GitHub release and publish updated files:

```bash
git tag v1.0.0
git push origin v1.0.0
```
