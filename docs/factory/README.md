# Project Bluefin Factory

**This is an OS factory. The product is bootc OCI images.**

This directory is the org-level entry point for agents and maintainers working across the Project Bluefin factory.

## Reference read order

1. Target repo `AGENTS.md` — start here
2. This file — org map, infrastructure state, open gaps
3. [`docs/factory/agentic-model.md`](agentic-model.md) — cross-repo hard rules, branch targets, PR policy, session start
4. [`docs/factory/IMPROVEMENTS.md`](IMPROVEMENTS.md) — why we rewrote Bluefin; system architecture
5. Relevant `docs/skills/*` files — lazy-load for the specific task; use [`docs/SKILL.md`](../SKILL.md) as the router

## Mission and product boundary

- Factory org: `projectbluefin`
- Product: bootc-based OCI images and the automation that builds, validates, and promotes them
- Shared layer repo: `common` — https://github.com/projectbluefin/common
- Production image registry: `ghcr.io/ublue-os/bluefin*` **not** `projectbluefin` yet
- Registry reference: `docs/skills/image-registry.md`

## Repo map and data flow

```text
common ──────────────────────────┐
(shared OCI layer)               │
                                 ▼
bluefin     ──┐                  │
bluefin-lts ─┼──→ images ──→ testsuite ──→ iso
dakota      ─┘                  │
```

- `common`: shared OCI layer and shared factory documentation
- `bluefin`: mainline Bluefin image streams
- `bluefin-lts`: LTS image streams
- `dakota`: bootc image pipeline in the same factory orbit
- `testsuite`: end-to-end gate for downstream image behavior
- `iso`: installation media fed by validated image outputs
- `actions`: shared GitHub Actions used across the org

For the workflow-by-workflow purpose map inside `common`, see [`../skills/workflow-map.md`](../skills/workflow-map.md).

## Factory repos

- `common` — https://github.com/projectbluefin/common
- `bluefin` — https://github.com/projectbluefin/bluefin
- `bluefin-lts` — https://github.com/projectbluefin/bluefin-lts
- `dakota` — https://github.com/projectbluefin/dakota
- `actions` — https://github.com/projectbluefin/actions
- `testsuite` — https://github.com/projectbluefin/testsuite

## Agentic operating model

`filed → triage → queued → claimed → done`

Lifecycle automation source: `.github/workflows/lifecycle.yml` (deployed to all factory repos via `lifecycle-caller.yml`).
Full lifecycle, epics, project board, and PR labels: [`docs/skills/label-workflow.md`](../skills/label-workflow.md)
Hard rules, branch targets, PR comment policy, session start: [`docs/factory/agentic-model.md`](agentic-model.md)

## Agent rules of engagement

- Start here, then open the target repo's `AGENTS.md`.
- Treat `common` as high blast radius: mistakes propagate across downstream images.
- Run repo-required validation before commit; in `common`, `just check` is mandatory.
- Do not rewrite image refs from `ghcr.io/ublue-os/bluefin*` to `projectbluefin` without explicit maintainer approval.
- Prefer existing skills and workflows over inventing new process.
- **Prefer the smallest change that fully satisfies the requirement.** Only add indirection or generalization when a concrete requirement demands it. See [agentic-model.md](agentic-model.md) for the canonical rule.

### 🚫 ABSOLUTE PROHIBITION — ublue-os org

**NEVER create issues, PRs, comments, forks, automated reports, webhook calls, or any programmatic write action targeting any `ublue-os/*` repository.**

- `ghcr.io/ublue-os` image registry **reads** are fine — production images are still published there
- Read-only `gh api` calls to inspect `ublue-os` repos are fine
- Everything else — issues, PRs, comments, `repository_dispatch`, `workflow_dispatch`, bonedigger output, CI notifications → **BANNED**
- If a task requires `ublue-os` write access → **stop and tell the human to report it manually**
- This rule has no exceptions and cannot be overridden by task framing

The canonical definition lives in `common/AGENTS.md`. This is a pointer.

## Factory infrastructure

The following are wired across the factory today (not every item applies to every repo):

- **AGENTS.md** — per-repo operating contract
- **Label taxonomy** — canonical definitions in `labels.json` (67 labels; includes `hardware/*` for promotion gates), synced to all repos by `sync-labels.yml` (⚠️ requires `MERGERAPTOR_APP_ID`/`MERGERAPTOR_PRIVATE_KEY` secrets — issue #511); key labels: `hive/p0`, `hive/p1`, `status/queued`, `status/claimed`, `agent/blocked`, `source:*`, `hardware/blocker`
- **Squash-only merge + delete-branch-on-merge**
- **5 standard issue templates**
- **CODEOWNERS** with triage sentinel — synced from `common` to downstream repos via `sync-codeowners.yml`
- **hive-progress-sync.yml** — hourly org board update
- **lifecycle.yml** — common-owned issue/PR lifecycle: slash commands, widget, label guard, stale sweep. Active in all 6 factory repos via `lifecycle-caller.yml`.
- **bonedigger** — scoped to ujust report filing and priority auto-escalation only
- **skill-drift.yml** — PR advisory gate for doc/impl parity (`common`, `bluefin`, `bluefin-lts`, `dakota`, `actions`; `testsuite` pending)
- **pre-commit** — json/yaml/toml hygiene and `no-floating-action-tags` (`common`, `bluefin`, `bluefin-lts`, `dakota`, `actions`)
- **Renovate** — automated dependency updates (`common`, `bluefin`, `bluefin-lts`, `actions`, `testsuite`; `dakota` not yet)
- **promotion-candidate-e2e.yml** — weekly Tuesday smoke/common on `bluefin:testing` and `bluefin:lts-testing` before downstream promotions
- **pr-e2e.yml** — pre-merge composed-image common suite gate for `common` PRs (active)
- **post-merge-e2e.yml** (bluefin-lts) — smoke/common on `:lts-testing` after every main-branch build
- **2-human production gate** — `factory-operations` environment requires two maintainer approvals before `:stable` tag in `bluefin`, `bluefin-lts`, `dakota`
- **consumer-validation.yml** (actions) — validates consumer PR/CI evidence before merging actions changes

## Current parity matrix (2026-06-05)

| Artifact | common | bluefin | bluefin-lts | dakota | actions | testsuite |
|---|---|---|---|---|---|---|
| AGENTS.md | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| pre-commit | ✅ | ✅ | ✅ | ✅ | — | — |
| skill-drift.yml | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| no-floating-action-tags | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| lifecycle.yml caller | ✅ | ✅ (PR) | ✅ (PR) | ✅ (PR) | ✅ (PR) | ✅ (PR) |
| Renovate config | ✅ | ✅ | ❓ org-inherited | ❌ | ✅ | ✅ |
| Post-merge e2e | ✅ | ✅ | ✅ | partial | — | — |
| Pre-merge e2e | ✅ (common suite) | ✅ (pr-smoke) | ❌ | ❌ | — | — |
| Installability gate | ⚠️ smoke/common only | ❌ | ❌ | ❌ | — | ❌ |
| 2-human production gate | ✅ | ✅ | ✅ | ✅ | — | — |
| docs/skills/ populated | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

For the full blindspot / constraint-rule reference, see [`../skills/acmm-audit-level2.md`](../skills/acmm-audit-level2.md) (current). The historical Level 1 audit is at [`../skills/acmm-audit-level1.md`](../skills/acmm-audit-level1.md).

## Open gaps

- **Nightly LTS/GDX e2e degraded** — testsuite#372 (gdx:stream10) and testsuite#373 (bluefin:lts ZFS) keep suites persistently red; CI signal for these variants is unreliable
- **Installability gate** — no installer/bootc-install gate before `testing → stable` promotion [#423](https://github.com/projectbluefin/common/issues/423)
- **bonedigger crash/panic signal** not wired into promotion decisions [#424](https://github.com/projectbluefin/common/issues/424)
- **Regression contract** across `latest`/`stable`/`gts`/`lts` streams is undefined [#420](https://github.com/projectbluefin/common/issues/420)
- **Migration upgrade path testing** is not auto-triggered — `testsuite/migration-test.yml` is `workflow_dispatch` only; schedule addition is `status/hold` pending zstd:chunked stability (testsuite#232)
- **bonedigger not factory-onboarded** — no AGENTS.md, no hive labels [#418](https://github.com/projectbluefin/common/issues/418)
- **Lifecycle bot unification** — bonedigger SHA-pin inconsistent across org; `bluefin-lts`/`dakota` use intentional `@main` [#409](https://github.com/projectbluefin/common/issues/409)
- **consumer contract** for `actions@v1` has no machine verification — `aurora`/`bazzite` compat can silently break

Tracking epics: [#404](https://github.com/projectbluefin/common/issues/404) (infra parity) · [#405](https://github.com/projectbluefin/common/issues/405) (QA model)

## Per-repo AGENTS.md entry points

- `common` — https://github.com/projectbluefin/common/blob/main/AGENTS.md
- `bluefin` — https://github.com/projectbluefin/bluefin/blob/main/AGENTS.md
- `bluefin-lts` — https://github.com/projectbluefin/bluefin-lts/blob/main/AGENTS.md
- `dakota` — https://github.com/projectbluefin/dakota/blob/main/AGENTS.md
- `actions` — https://github.com/projectbluefin/actions/blob/main/AGENTS.md
- `testsuite` — https://github.com/projectbluefin/testsuite/blob/main/AGENTS.md

## Sensitive paths (require maintainer review)

All repos: `.github/workflows/`, `Justfile`, `build_files/`
dakota only: `elements/`

## Finding work

```bash
# P0 blockers — start here every session
gh search issues --label "hive/p0" --owner projectbluefin --state open

# Ready for agent pickup
gh search issues --label "status/queued" --owner projectbluefin --state open

# Live hive snapshot
just hive   # from ~/src
```

Full label taxonomy and next-step lookup: [`docs/skills/label-workflow.md`](../skills/label-workflow.md)
