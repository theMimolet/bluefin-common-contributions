# bluefin-common — Copilot Instructions

**Primary contract: [`AGENTS.md`](../AGENTS.md) — read it before taking any action.** This file adds only Copilot-specific context.

## Safety rules (repeated here for bootstrap safety)

**NEVER** create issues, PRs, comments, forks, automated reports, webhook calls, or any programmatic write action targeting any `ublue-os/*` repository. Reads of `ghcr.io/ublue-os` images are fine. For anything requiring a write or automated action to `ublue-os`, tell the human to report it manually and stop.

One comment per PR event. Combine all findings. Edit the existing comment rather than posting a follow-up. When in doubt, post nothing.

## Attribution trailer

Every AI-authored commit must include:

```
Assisted-by: <Model> via GitHub Copilot
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

## Branch and commit rules

- `docs/`, `*.md`, and `.github/CODEOWNERS` changes → commit directly to `main`, no PR needed
- All other changes → PR with Conventional Commits title (`feat:`, `fix:`, `chore:`, etc.)
- Run `just check` and `pre-commit run --all-files` before every commit

## CODEOWNERS — sentinel is load-bearing

**Never remove or restructure the `# BEGIN TRIAGERS … # END TRIAGERS` block.**
`sync-codeowners.yml` parses it to sync triager rules and GitHub triage permissions to
`bluefin`, `bluefin-lts`, `dakota`, and `knuckle`. Removing it silently disables all of that.

To add a triager: append `@handle` to the `**/*.md` line inside the sentinel, commit to `main`.
Before editing CODEOWNERS, read `.github/workflows/sync-codeowners.yml` to understand dependencies.
