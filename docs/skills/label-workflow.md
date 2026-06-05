---
name: label-workflow
description: "Label taxonomy, issue lifecycle, and workflow guidelines for contributors and agents in projectbluefin factory repos."
---

# Label Workflow — projectbluefin Factory

## The one-line model

**Humans decide what gets built. Agents build it.**

Humans file, triage, and approve work. Agents claim, implement, and ship it.
Labels are the handoff signal between the two.

---

## Next-step reference

Every issue and PR always has exactly one actor who owns it. Find the active label — that tells you who acts next and what they do.

### Issues

| Label | 🟠 Actor | Next action |
|---|---|---|
| `status/triage` | **Human** triager | Set `kind/` + `area/`, then `/approve` or add `status/discussing` |
| `status/discussing` | **Human** maintainer | Drive to consensus, update spec, then `/approve` |
| `status/queued` | **Agent** / contributor | Comment `/claim` |
| `status/claimed` | **Agent** | Implement → open PR with `Closes #NNN` |
| `agent/blocked` | **Human** | Read issue comment → unblock → remove label |
| `status/hold` | *nobody* | Intentionally paused — read comments for reason |

### PRs

| Label | 🟠 Actor | Next action |
|---|---|---|
| `pr/needs-review` | **Human** reviewer | Review → add `lgtm` or request changes |
| `lgtm` + CI green | *automation* | Merges automatically |
| Changes requested | **Agent** | Address feedback → re-request review |
| `do-not-merge` | **Human** | Investigate → remove when resolved |

---

## Issue lifecycle

Issues follow one of two entry paths depending on type, then converge into a shared pipeline:

```
BUG:     filed → [status/triage] → status/approved → status/queued → status/claimed → done
FEATURE: filed → [status/discussing] → status/approved → status/queued → status/claimed → done
```

Blocking overlays (can be applied at any stage):
- `status/hold` — paused intentionally, do not touch
- `agent/blocked` — agent stuck, needs human input

---

## Human workflow

### Filing an issue

Use the issue templates — they set the right initial labels automatically.

If filing without a template, include enough context that someone else can act on it without asking you follow-up questions. Issues that require clarification stay in triage indefinitely.

**Bug reports** get `status/triage` automatically.
**Feature requests** get `status/discussing` automatically.

### Triaging a bug (maintainers and triagers)

When you see `status/triage`:

1. Is this valid? Is it a duplicate?
   - Invalid or duplicate → close with explanation; add `kind/wontfix` if you want to track the decision
   - Needs more data → ask for `ujust report` output in a comment, leave `status/triage` in place
2. Set **exactly one** `kind/` label
3. Set **one or more** `area/` labels
4. Optionally set one `priority/` label (backlog ordering) or `hive/p0`/`hive/p1` (current-cycle urgency)
5. Remove `status/triage`

If the bug needs design discussion before anyone implements a fix, add `status/discussing` after removing `status/triage`.

### Advancing a feature discussion

When an issue in `status/discussing` reaches consensus on approach:

1. Update the issue description with the agreed spec — it needs to be clear enough for a contributor who wasn't part of the discussion to act on it
2. Comment `/approve`

### Approving work

When an issue is fully scoped and ready for implementation:

- Comment `/approve`

Bonedigger responds by adding `status/approved` and `status/queued`.
The issue is now in the work pool.

**Manual fallback (if bonedigger is down):**
```
Add: status/approved + status/queued
```

### Reviewing agent PRs

PRs opened by agents carry `pr/needs-review` automatically. When you see it:

1. Verify the diff solves the stated issue (not just technically correct — actually the right fix)
2. Check `agent-tested` is present (e2e passed)
3. If it looks good: add `lgtm` — the PR will merge when CI is green
4. If something is wrong: leave a review comment — the agent will address it on next run
5. To block merge entirely: add `do-not-merge`

### Unblocking a stuck agent

When an issue has `agent/blocked`:

1. Read the comment the agent left — it will state exactly what it needs
2. Provide the answer or decision as a comment on the issue
3. Remove `agent/blocked`

The agent resumes on its next run.

### Pausing work

- `status/hold` — add to prevent any agent from claiming. Always add a comment explaining why and when it can be unpaused.
- `needs-human/agent-oops` — agent made an error that requires manual correction. Do not re-trigger agents on this issue; fix the underlying problem by hand first.

---

## Agent workflow

### Finding work

```bash
# All factory repos — start here
gh search issues --label "status/queued" --owner projectbluefin --state open

# Single repo
gh issue list --repo projectbluefin/common --label "status/queued" --state open

# Live hive snapshot (if available)
just hive   # from ~/src
```

**Pick order:** `hive/p0` first → `hive/p1` → `priority/p0` → `priority/p1` → `priority/p2` → unlabeled.

Check each candidate issue for `status/hold` before claiming — those are off-limits.

### Claiming an issue

Comment `/claim` on the issue. Bonedigger will:
1. Replace `status/queued` with `status/claimed`
2. Assign the issue to you
3. Remove you from the available pool for this issue

**Manual fallback (if bonedigger is down):**
```
Add: status/claimed
Remove: status/queued
Assign: yourself
```

### Working

- Read the target repo's `AGENTS.md` — it specifies the required validation commands for that repo
- Create a branch: `fix/NNN-short-description` or `feat/NNN-short-description`
- Run the repo's validation gate before every commit (see `AGENTS.md`)
- Follow Conventional Commits for PR titles: `fix:`, `feat:`, `chore:`, etc.

### Signaling a blocker

When you cannot proceed without a human decision:

1. Add `agent/blocked` to the **issue** (not the PR)
2. Comment on the issue with:
   - What you need (specific, not vague)
   - Why you're blocked (the exact ambiguity or missing information)
   - What the options are, if you can enumerate them
3. Stop. Do not open a partial PR. Do not guess.

### Opening a PR

- Title: Conventional Commits format (`fix: ...`, `feat: ...`, `chore(deps): ...`)
- Body: `Closes #NNN` + what changed + why
- Follow the target repo's `AGENTS.md` for attribution trailers
- Labels are set automatically where wired: `source:agent`, `size/*`, `agent-tested` after e2e

### Unclaiming

If you cannot finish the work:
```
Comment: /unclaim
```

**Manual fallback:**
```
Remove: status/claimed
Add: status/queued
Unassign yourself
```

---

## Label reference

### Lifecycle — defines where an issue is

> **Invariants:** at most one lifecycle label active at a time (except overlays `status/hold` and `agent/blocked`, which can coexist with any stage)

| Label | Color | Who sets it | Meaning |
|---|---|---|---|
| `status/triage` | 🟠 orange | Auto on bug reports | New bug. Human must set kind/ + area/, then /approve or add discussing. |
| `status/discussing` | 🔵 blue | Auto on features; human for bugs needing design | Under discussion. Human must reach consensus before /approve. |
| `status/approved` | 🟢 green | Human (`/approve`) | Approved. Bonedigger adds status/queued automatically. |
| `status/queued` | 🟣 purple | Bonedigger or human | In the work pool. Agent: comment /claim to take it. |
| `status/claimed` | 🟡 amber | Bonedigger or agent | Actively being worked. Open PR with Closes #NNN. |
| `status/hold` | ⬜ gray | Human | Off-limits — do not claim or touch. Read comments for reason. |
| `agent/blocked` | 🔴 red | Agent | Agent stuck; needs human decision. Read the issue comment. |

### Kind — what type of work?

> **Invariant:** exactly one `kind/*` per issue

| Label | Meaning |
|---|---|
| `kind/bug` | Broken behavior. Requires a fix PR. Verify with `ujust verify` after fix. |
| `kind/enhancement` | New capability. Must have a written spec in the issue body before claiming. |
| `kind/improvement` | Incremental improvement to existing behavior. No new spec required. |
| `kind/tech-debt` | Cleanup or refactor with no user-visible change. No spec required. |
| `kind/documentation` | Docs only. In `common`, commit directly to main — no PR needed. |
| `kind/translation` | i18n/l10n change. Coordinate with translation team before claiming. |
| `kind/epic` | Multi-issue tracker. Do not implement here; file child issues instead. |
| `kind/wontfix` | Will not be implemented. Do not claim or open PRs for this issue. |

### Priority — two families, different purposes

> **Invariants:** at most one `hive/*`; at most one `priority/*`

**Hive** — current release cycle priority. Reset each cycle by maintainers.

| Label | Meaning |
|---|---|
| `hive/p0` | Cycle release blocker. Fix before next promotion. |
| `hive/p1` | Must land this cycle. |

**Priority** — static backlog ordering. Set during triage, not reset each cycle.

| Label | Meaning |
|---|---|
| `priority/p0` | Repo-level blocker |
| `priority/p1` | High priority |
| `priority/p2` | Normal backlog |

An issue can carry **both** a `hive/*` and a `priority/*` — they track different things.

### Area — what part of the system?

> Set one or more `area/` labels. These scope the work and route CODEOWNERS reviews.

`area/agent` · `area/aurora` · `area/bling` · `area/bluespeed` · `area/bootc` · `area/brew` · `area/buildstream` · `area/ci` · `area/dx` · `area/finpilot` · `area/flatpak` · `area/gnome` · `area/hardware` · `area/iso` · `area/just` · `area/nvidia` · `area/policy` · `area/security` · `area/services` · `area/testing` · `area/ujust` · `area/upstream`

### Source — who filed it?

> Set automatically by templates and automation. Do not set or change manually.

| Label | Meaning |
|---|---|
| `source:agent` | Filed by an AI agent |
| `source:gha` | Filed by GitHub Actions |
| `source:manual` | Filed by a human contributor |
| `source:ujust-report` | Filed via `ujust report` by a user |

Note: `source:` uses a colon separator — this is intentional for compatibility with bonedigger's label routing.

### PR labels

> `pr/needs-review` is auto-set when a PR is opened. Size labels are auto-set where wired.

| Label | Color | Who sets it | Meaning |
|---|---|---|---|
| `pr/needs-review` | 🟠 orange | Auto on PR open | Awaiting human review. Add `lgtm` or request changes. |
| `lgtm` | 🟢 green | Human | Maintainer approved. Merges automatically when CI is green. |
| `do-not-merge` | 🔴 red | Human | Blocks all merges. Remove only when the blocking issue resolves. |
| `agent-tested` | 🟢 green | CI automation | e2e test suite passed. Set automatically after a clean run. |
| `tests:pass` | 🔵 blue | CI automation | Required CI gate passed. Enables auto-merge where wired. |
| `size/XS` | gray | Auto | ~1 hour: 0–9 lines changed |
| `size/S` | gray | Auto | ~half day: 10–29 lines changed |
| `size/M` | gray | Auto | ~1 day: 30–99 lines changed |
| `size/L` | gray | Auto | ~3 days: 100–499 lines changed |
| `size/XL` | gray | Auto | ~1 week: 500–999 lines changed |

PRs over ~1000 lines should be split. If you see one that size, split the PR or the issue.

Note: `tests:pass` uses a colon separator — retained for CI automation compatibility.

### Agent flow triggers

Applied to issues to request a specific agent workflow:

| Label | Meaning |
|---|---|
| `flow/issue-review` | Agent: review the linked issue, post findings as a comment, remove this label. |
| `flow/pr-review` | Agent: review the linked PR, post findings as a comment, remove this label. |

### Special and automation labels

| Label | Meaning |
|---|---|
| `ai-context` | ACMM audit finding — AI/LLM context gap that improves agent reliability org-wide |
| `stale` | No recent activity; will auto-close unless updated |
| `needs-human/agent-oops` | Agent error — do not re-run automation; fix manually then re-queue |
| `dependencies` | Renovate dependency update PR. Automerges on CI pass; only major bumps need review. |

---

## What automation does (do not set these manually unless bonedigger is down)

| Trigger | What bonedigger does |
|---|---|
| Bug report opened | Adds `status/triage` |
| Feature request opened | Adds `status/discussing` |
| PR opened | Adds `pr/needs-review` |
| `/approve` comment | Adds `status/approved` + `status/queued` |
| `/claim` comment | Removes `status/queued`, adds `status/claimed`, assigns |
| `/unclaim` comment | Removes `status/claimed`, re-adds `status/queued`, unassigns |
| No PR activity in 7 days | Returns claim: removes `status/claimed`, re-adds `status/queued` *(target state — not fully consistent across all repos yet)* |
| PR review submitted | Removes `pr/needs-review` |

---

## Quick reference for new contributors

**I want to report a bug:**
→ Open an issue → use the Bug Report template → fill it out → done. Maintainers triage it.

**I want to propose a feature:**
→ Open an issue → use the Feature Request template → be specific → done. Vague proposals wait indefinitely in `status/discussing`.

**I want to implement something:**
1. Find an issue with `status/queued` in the target repo
2. Comment `/claim`
3. Read the issue + the repo's `AGENTS.md`
4. Branch, build, test, PR with "Closes #NNN"

**I'm a maintainer and want to queue work for agents:**
1. Find a triaged issue (has `kind/` and `area/` set)
2. Comment `/approve`
3. Done — bonedigger queues it automatically

**I need to stop automation from touching something:**
→ Add `status/hold` and leave a comment explaining why

---

## Migration status

The following labels are in the process of being retired. They remain present in some repos
while templates and automation are updated. **Do not use them for new issues.**

| Retiring | Use instead | Blocker |
|---|---|---|
| `bug` (bare) | `kind/bug` | Template update needed in common |
| `type/bug` | `kind/bug` | Template update needed in bluefin, bluefin-lts |
| `type/feature` | `kind/enhancement` | Template update needed in bluefin, bluefin-lts |
| `needs-human/agent-ready` | `status/queued` | Docs update needed |
| `agent/claimed` | `status/claimed` | Verify no automation dependency |
| `size:*` (colon variants) | `size/*` (slash variants) | Check automation consumers per repo |
| `copilot-ready` | `status/queued` | Label cleanup only |
| `hold` (bare) | `status/hold` | Verify automation consumers |

Tracking issue: file one in `projectbluefin/common` with `kind/tech-debt` + `area/agent`.
