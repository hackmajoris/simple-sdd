---
name: simple-sdd-setup
description: Spec Driven Development setup. Detects if the project is already configured, otherwise asks new or existing and runs the full scaffolding flow.
type: skill
---

You are setting up Spec Driven Development (SDD) for this project.

## Step 1 — Validate git state

Run `git rev-parse --is-inside-work-tree 2>/dev/null || echo not-a-repo` — if `not-a-repo`, stop: "This directory is not a git repository. Run `git init` first."

Run `git status --porcelain` — if not empty, stop: "You have uncommitted changes. Commit or stash them first — SDD setup will commit the generated spec files as a clean checkpoint."

## Step 2 — Check existing setup

Use the Bash tool to run:
```bash
ls specs/mission.md specs/tech-stack.md 2>/dev/null
```

If both files exist, tell the user:

"This project is already configured. Run `/simple-sdd-feature-new` to start a new feature or change."

Then stop — do not proceed further.

---

## Step 2 — New or existing?

Use the `AskUserQuestion` tool to ask:

> "Is this a **new project** (starting from scratch) or an **existing project** (codebase already exists)?"

Accept: new, greenfield, existing, brownfield.

Based on the answer, follow either the **New Project Flow** or the **Existing Project Flow** below.

---

## New Project Flow

### Phase 0 — Read context

Before asking anything:
1. Check if a `README.md` exists. If it does, read it fully — it may contain stakeholder input, product vision, or requirements.
2. Check for any other relevant files: `BRIEF.md`, `REQUIREMENTS.md`, `docs/`, etc.
3. Summarize what you found to the user in 2–3 sentences.

### Phase 1 — Mission questions

Use the `AskUserQuestion` tool to ask the following **3 questions in a single grouped call**. Do not write any files yet.

1. **What is this product?** Describe what it does and who it's for.
2. **What problem does it solve?** What's the core pain point or opportunity?
3. **What does success look like?** What's the north star — how will you know this worked?

Wait for the user's answers before proceeding.

### Phase 2 — Tech stack questions

Use the `AskUserQuestion` tool to ask the following **3 questions in a single grouped call**. Do not write any files yet.

1. **What language(s) and frameworks are you planning to use?** (or "not decided yet" is fine)
2. **What infrastructure or hosting are you targeting?** (cloud provider, self-hosted, serverless, etc.)
3. **Are there any hard constraints or preferences?** (existing services to integrate, team expertise, licensing, etc.)

Wait for the user's answers before proceeding.

### Phase 3 — Write spec files

Use the Bash tool to run `mkdir -p specs`, then use the Write tool to write each file.

**specs/mission.md**
```markdown
# Mission

## What is this?
[answer from Phase 1, Q1]

## Problem
[answer from Phase 1, Q2]

## Definition of success
[answer from Phase 1, Q3]
```

**specs/tech-stack.md**
```markdown
# Tech Stack

## Languages & Frameworks
[answer from Phase 2, Q1]

## Infrastructure & Hosting
[answer from Phase 2, Q2]

## Constraints & Preferences
[answer from Phase 2, Q3]
```

---

## Existing Project Flow

### Phase 0 — Codebase analysis

Before asking anything, explore the existing project to build context:
1. Read `README.md`, `CHANGELOG.md`, `package.json`, `pom.xml`, `go.mod`, `pyproject.toml`, or any manifest file — whatever is relevant to this stack.
2. Scan the top-level directory structure and identify key modules, services, or layers.
3. Look for existing documentation in `docs/`, `specs/`, `wiki/`, or similar.
4. Identify the language(s), framework(s), and infrastructure clues (Dockerfile, CI configs, cloud configs).

Present a brief summary to the user:
- What the system appears to do
- The tech stack you inferred
- What documentation already exists
- What you could not determine

### Phase 1 — Mission questions

Use the `AskUserQuestion` tool to ask the following **3 questions in a single grouped call**, pre-filling what you already know so the user only needs to correct or expand. Do not write any files yet.

1. **Is this an accurate description of what the system does?** [insert your inferred description] — correct or expand as needed.
2. **What is the core problem this system solves, from the user's perspective?** (not technical — what pain does it remove?)
3. **What does success look like for this initiative?** Why is SDD being started now — what needs to change or improve?

Wait for the user's answers before proceeding.

### Phase 2 — Tech stack questions

Use the `AskUserQuestion` tool to ask the following **3 questions in a single grouped call**, pre-filling what you inferred. Do not write any files yet.

1. **Is this the correct tech stack?** [insert inferred stack] — correct or add anything missing.
2. **Are there services, APIs, or infrastructure components not visible in the code?** (third-party services, databases, queues, external APIs, etc.)
3. **Are there any constraints or planned changes to the stack?** (migrations, deprecations, new tools being introduced)

Wait for the user's answers before proceeding.

### Phase 3 — Write spec files

Use the Bash tool to run `mkdir -p specs`, then use the Write tool to write each file.

**specs/mission.md**
```markdown
# Mission

## What is this?
[confirmed/corrected description from Phase 1, Q1]

## Problem
[answer from Phase 1, Q2]

## Definition of success
[answer from Phase 1, Q3]
```

**specs/tech-stack.md**
```markdown
# Tech Stack

## Languages & Frameworks
[confirmed/corrected stack from Phase 2, Q1]

## Infrastructure & External Services
[answer from Phase 2, Q2 — include what was inferred + what the user added]

## Constraints & Planned Changes
[answer from Phase 2, Q3]
```

---

## Completion

After writing all files:

1. Tell the user:
"SDD setup complete. Please review the generated files before we commit:
- `specs/mission.md`
- `specs/tech-stack.md`

Take a look and confirm when ready — or let me know what to adjust."

2. Use the `AskUserQuestion` tool to ask:
"Are the spec files good to commit, or do you need changes?"

3. If the user confirms (yes / looks good / commit / etc.):
   Use the Bash tool to run:
   ```bash
   git add specs/mission.md specs/tech-stack.md
   git commit -m "chore: add SDD spec files"
   ```
   Then tell the user:
   "Committed. Context should be cleared for best results before the next step. Run `/clear` when ready — or type 'skip' to continue in this session."

4. If the user requests changes:
   Make the requested edits to the spec files, then return to step 2.
