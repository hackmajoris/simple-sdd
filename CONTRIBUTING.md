# Contributing to simple-sdd

Thanks for wanting to help. This is a small, opinionated tool — the bar for new features is that they sharpen the core workflow (clarity before code, one task per session, spec in git) rather than broaden it.

## Repo layout

```
install.sh                       — the installer users download from releases
src/commands/*.md                — the slash-command prompt files
src/templates/plan-template.md   — structure every plan.md follows
.github/workflows/
  release.yml                    — cut a release on tag push
  test-install.yml               — matrix-test the installer on every PR
```

## Running the installer locally

You can run the installer against a local copy of the repo — no network, no release required:

```bash
# From anywhere; point SDD_BASE_URL at your working copy.
SDD_BASE_URL="file:///absolute/path/to/simple-sdd-checkout/src/commands" \
SDD_VERSION=dev \
bash /absolute/path/to/simple-sdd-checkout/install.sh --tool claude --yes
```

For quick experimentation, use `--dry-run`:

```bash
bash install.sh --dry-run --tool all --yes
```

And clean up after yourself:

```bash
bash install.sh --uninstall --tool all --yes
```

## Testing

Before opening a PR, please:

1. Run the installer end-to-end in a throwaway dir — both `fresh` and `reinstall` scenarios — for at least the tool(s) you changed.
2. Confirm `--dry-run` prints the expected actions and writes nothing.
3. Confirm `--uninstall` removes every file the install wrote and strips the config-injection block.
4. If you touched a command prompt, run it manually in your AI tool of choice (Claude Code, Copilot, or OpenCode) and verify the behavior you intended.

CI runs the full `fresh` × `reinstall` matrix on macOS + Ubuntu × claude/copilot/opencode automatically on every PR — see `.github/workflows/test-install.yml`.

## Releasing

Releases are tag-driven.

1. Update any version references in documentation.
2. Tag: `git tag v1.2.3 && git push origin v1.2.3`.
3. `.github/workflows/release.yml` builds a flat artifact bundle, generates `SHA256SUMS`, and attaches everything to a GitHub Release.
4. Check the release page — the SHA256SUMS entry should be present and match what users would download.

Never force-push over an existing tag; cut a new version instead.

## Code style

- Shell: use `bash` features sparingly. `install.sh` must stay portable across macOS and Ubuntu. Prefer POSIX-ish constructs, and add a matrix cell to `test-install.yml` if you introduce a new platform requirement.
- Prompt files: the commands are instructions for an AI, not code. Be explicit, numbered, and prefer small `bash` snippets over long prose when you want a specific command executed.
- Keep docs in sync: if you change a command's behavior, update `README.md`, `src/commands/simple-sdd-help.md`, and any affected examples in the same PR.

## Reporting issues

Use the templates in `.github/ISSUE_TEMPLATE/`. Include:

- OS, shell, AI tool, and `SDD_VERSION` (or `head -1` of an installed command file — that's the stamp).
- A minimal reproduction (ideally a throwaway dir we can recreate).
- What you expected vs. what happened.
