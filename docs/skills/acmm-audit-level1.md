---
name: acmm-audit-level1
description: "ACMM Level 1 audit — current open gaps, parity matrix, and active blindspot rules. Historical resolved items moved to appendix."
---

# ACMM Level 1 Audit — Project Bluefin Factory

**Framework:** AI Codebase Maturity Model (arXiv:2604.09388)
**Current level:** 1 (Assisted) → actively bridging to Level 2 (Instructed)
**Scope:** `common`, `bluefin`, `bluefin-lts`, `dakota`, `actions`, `testsuite`
**Last updated:** 2026-06-05 (third-pass audit)

---

## Summary

The projectbluefin factory is a six-repo OCI image pipeline operated increasingly
by AI agents. It has strong documentation discipline and a growing skills
infrastructure. The core mission — **Agentic OS Components / operating system
factory** — must be the first thing any agent reads. `common` is the org brain.

**Progress since Level 1 assessment began (2026-06-04):**
- 10+ blindspots documented and cross-linked to issues
- 7 ✅ cells gained in one day of focused parity work
- Pre-merge e2e for `common` now active (was disabled)
- Dakota fully onboarded (pre-commit, no-floating-tags, bonedigger)
- `bluefin-lts` post-merge e2e now active

**Remaining blockers to Level 2:**
- Nightly CI desensitization (LTS + GDX suites persistently red)
- Installability gate not wired before `testing → stable`
- Migration test not auto-triggered (queue/hold)
- Lifecycle bot parity: `bonedigger` SHA-pin inconsistent across org

---

## 1. Active Blindspots

Active risks where an AI without full context will confidently generate broken changes.

### BS-1.2 · `bluefin` Containerfile Stage 1/Stage 2 cache boundary

**Repo:** bluefin  **Issue:** [#472](https://github.com/projectbluefin/common/issues/472)

ARG declarations are placed *between* Stage 1 and Stage 2 RUN blocks intentionally
to avoid busting Stage 1 cache. Adding a package to Stage 2, or moving ARG declarations
upward, silently breaks 20–80 minutes of cache on every CI build. No test detects this.

**Constraint rule:** Check `bluefin/docs/build.md` stage boundary notes before adding
any package or ARG to the Bluefin Containerfile.

---

### BS-1.5 · ublue-os → projectbluefin image ref migration is incomplete

**Repo:** common, bluefin  **Issue:** [#468](https://github.com/projectbluefin/common/issues/468)

Production OCI images are **still published at `ghcr.io/ublue-os/bluefin*`**. Replacing
`ublue-os` refs with `projectbluefin` breaks e2e workflows, PR smoke gates, and
`ublue-rollback-helper`. No code-level guard prevents this.

**Constraint rule:** Load `docs/skills/image-registry.md` before touching any image
reference. Never change `ublue-os` refs without explicit maintainer approval.

---

### BS-1.6 · `bluefin` git remote trap

**Repo:** bluefin  **Issue:** [#476](https://github.com/projectbluefin/common/issues/476)

In `projectbluefin/bluefin`, `origin` points to `ublue-os/bluefin`. A bare `git push`
or `git push origin` sends commits to the wrong org. This has already happened.
The correct remote is `projectbluefin`. No pre-push hook enforces it.

**Constraint rule:** In `bluefin`, always push to `projectbluefin` remote explicitly:
`git push projectbluefin <branch>`. Never use bare `git push`.

---

### BS-1.8 · Dakota build paradigm contamination

**Repo:** dakota  **Issue:** [#475](https://github.com/projectbluefin/common/issues/475)

Dakota uses **BuildStream 2 (BST)**. No `dnf5` commands, no Fedora RPMs, no COPR.
An AI with `common` or `bluefin` context will attempt `dnf5 install` — completely
wrong. The `Containerfile` and `Justfile` name collision creates anchor bias.

**Constraint rule:** Load `dakota/docs/skills/not-bluefin.md` before ANY dakota work.

---

### BS-1.9 · bluefin-lts CentOS/Fedora contamination

**Repo:** bluefin-lts  **Issue:** [#474](https://github.com/projectbluefin/common/issues/474)

`bluefin-lts` is built on **CentOS Stream 10**. COPR does not exist on CentOS.
`copr-helpers.sh` patterns or `dnf5 copr enable` silently fail or break the image.

**Constraint rule:** Load `bluefin-lts/docs/skills/centos-vs-fedora.md` before ANY
bluefin-lts work. No COPR on CentOS — use EPEL.

---

### BS-1.17 · Nightly e2e failures create CI desensitization

**Repos:** testsuite, bluefin-lts  **Issues:** testsuite#372, testsuite#373

Two persistent nightly failures:
- testsuite#373 — `bluefin:lts` suites fail because ZFS on `/var` blocks the harness
- testsuite#372 — `gdx:stream10` common suite fails — Homebrew missing, COPR error

**Constraint rule:** If nightly CI is red for `bluefin:lts` or `gdx:stream10`, do
NOT assume it is the known failure. Explicitly compare against testsuite#372 / #373
before dismissing a new CI failure.

---

### BS-1.18 · `bonedigger.yml` SHA-pinning inconsistent across org

**Files:** `bluefin-lts/bonedigger.yml`, `dakota/bonedigger.yml`

`common` and `bluefin` pin bonedigger to SHA `743f56403af826b148d2841524faa1edb68a4538`.
`bluefin-lts` and `dakota` float `@main`. The `no-floating-action-tags` hook exempts
`projectbluefin/` refs so the hook won't catch this. An agent doing a compliance pass
will attempt to pin them to a possibly-stale SHA.

**Constraint rule:** `@main` in `bluefin-lts/bonedigger.yml` and `dakota/bonedigger.yml`
is intentional — `bonedigger` has no versioned releases. Do NOT pin to SHA without
maintainer coordination. See `docs/skills/ci-tooling.md`.

---

### BS-1.19 · `migration-test.yml` blocked by `queue/hold`

**Repo:** testsuite  **Issue:** testsuite#232

`migration-test.yml` has no `schedule:` trigger — manual only. The issue to add one
is `queue/hold` pending zstd:chunked stability. Migration regressions (broken `bootc upgrade`
paths) are not auto-detected.

**Constraint rule:** Changes to bootc version pins, `ostree-ext`, image base digests,
or OCI layer compression carry invisible migration risk. No CI will catch this automatically.

---

### BS-1.20 · Testsuite step file coverage gap

**Repo:** testsuite  **Issue:** testsuite#371

`hardware/`, `nvidia/`, `flatcar/`, and `bazzite/` step files have zero unit test coverage.
`behave --dry-run` is the only local gate for these suites.

**Constraint rule:** When authoring steps for these suites, step logic errors won't be
caught until live e2e (requires ghost runner access).

---

### BS-1.21 · `bluefin-lts` has no local `renovate.json`

**Repo:** bluefin-lts

No `.github/renovate.json` exists. Renovate inherits silently from org-level
`projectbluefin/renovate-config`. An agent making repo-specific Renovate changes will
find no file to edit and may create unexpected config or edit the org-level config
instead.

**Constraint rule:** If you need to add a Renovate override for `bluefin-lts`
specifically, first create `.github/renovate.json` extending the org config before
adding overrides.

---

## 2. Feedback Mechanisms

| Gate | Trigger | What it catches | Status |
|---|---|---|---|
| `validate.yml` (common) | PR to main | just syntax, shellcheck, pre-commit | ✅ |
| `pre-commit` (common) | commit | YAML/JSON format, trailing whitespace, actionlint | ✅ |
| `validate-brewfiles.yaml` (common) | PR to main | Brewfile validity | ✅ |
| `build.yml` (common) | merge to main | OCI build integrity | ✅ |
| `pr-e2e.yml` compose + e2e (common) | PR to main | Composed image, common suite | ✅ |
| `e2e.yml` (common) | post-merge | End-to-end: bluefin, lts, dakota | ✅ |
| `promotion-candidate-e2e.yml` (common) | weekly Tue | smoke/common on :testing + :lts-testing | ✅ |
| `skill-drift.yml` (all 5 repos) | PR | Code changes without doc updates | ✅ |
| `post-merge-e2e.yml` (bluefin-lts) | merge to main | smoke/common on :lts-testing | ✅ |
| `factory-operations` env (bluefin, lts, dakota) | promotion | 2-human approval gate | ✅ |
| `consumer-validation.yml` (actions) | PR | Missing consumer PR/CI evidence | ✅ |
| `migration-test.yml` (testsuite) | manual only | bootc upgrade path regressions | ⚠️ manual |
| `pr-e2e.yml` e2e job (common) nightly lts/gdx | nightly | LTS/GDX variant health | ⚠️ degraded |

### Critical gaps

- **No full installability gate** before `testing → stable` — `common` has weekly smoke/common
  but no installer/bootc-install gate ([#423](https://github.com/projectbluefin/common/issues/423))
- **No bonedigger crash signal** wired into promotion decisions ([#424](https://github.com/projectbluefin/common/issues/424))
- **Migration upgrade path testing** is manual-only; adding a schedule is `queue/hold` (testsuite#232)
- **Nightly LTS/GDX e2e degraded** — testsuite#372, #373 keep suites persistently red

---

## 3. Current Parity Matrix (2026-06-05)

| Artifact | common | bluefin | bluefin-lts | dakota | actions | testsuite |
|---|---|---|---|---|---|---|
| AGENTS.md | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| pre-commit | ✅ | ✅ | ✅ | ✅ | — | — |
| skill-drift.yml | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| no-floating-action-tags | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| bonedigger lifecycle | ✅ | ✅ | ✅ | ✅ | — | — |
| bonedigger SHA-pinned | ✅ | ✅ | ❌ (@main) | ❌ (@main) | — | — |
| Renovate config | ✅ | ✅ | ❓ org-inherited | ❌ | ✅ | ✅ |
| Post-merge e2e | ✅ | ✅ | ✅ | partial | — | — |
| Pre-merge e2e | ✅ (common suite) | ✅ (pr-smoke) | ❌ | ❌ | — | — |
| Installability gate | ⚠️ smoke/common only | ❌ | ❌ | ❌ | — | ❌ |
| 2-human production gate | ✅ | ✅ | ✅ | ✅ | — | — |
| CODEOWNERS active | ✅ | ✅ | ✅ | ✅ | — | — |
| docs/skills/ populated | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Migration-test auto-trigger | — | — | — | — | — | ❌ (queue/hold) |
| Consumer contract verified | — | — | — | — | ❌ | — |

---

## 4. Open Issues — Priority Order

Items below are open. When an item is fixed, delete it from this list.

| Priority | Issue | Repo | Type | Blocking |
|---|---|---|---|---|
| P0 | testsuite#373 | testsuite | ZFS `/var` breaks lts nightly | LTS CI signal |
| P0 | testsuite#372 | testsuite | gdx:stream10 common suite broken | GDX CI signal |
| P0 | [#409](https://github.com/projectbluefin/common/issues/409) | org-wide | lifecycle bot unification | all agent operations |
| P1 | testsuite#232 | testsuite | migration-test queue/hold | upgrade regression detection |
| P1 | [#424](https://github.com/projectbluefin/common/issues/424) | common | bonedigger crash/panic → promotion gate | promotion quality |
| P1 | [#420](https://github.com/projectbluefin/common/issues/420) | common | regression contract definition | stream parity |
| P1 | [#423](https://github.com/projectbluefin/common/issues/423) | common | installability gate | promotion quality |
| P1 | [#425](https://github.com/projectbluefin/common/issues/425) | common | lts full e2e gate | testing quality |
| P2 | bluefin-lts, dakota | bonedigger @main exemption comments | agent confusion |
| P2 | testsuite | add skill-drift.yml | doc parity |
| P2 | bluefin-lts | add renovate.json | config transparency |
| P2 | actions | consumer contract machine test | aurora/bazzite safety |
| P2 | [#404](https://github.com/projectbluefin/common/issues/404) | org-wide | infra parity epic | agent reliability |
| P2 | [#405](https://github.com/projectbluefin/common/issues/405) | org-wide | QA epic | quality gates |
