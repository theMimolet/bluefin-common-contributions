---
name: queue-dashboard
description: "PR review and merge queue workflow for projectbluefin/common — ruleset, triage tiers, rebase patterns, and what to do with each PR state."
---

# Queue Dashboard — projectbluefin/common

## Merge ruleset (`main-review-required-with-renovate-bypass`)

| Setting | Value |
|---|---|
| Required approvals | **1** (+ code owner review required) |
| Dismiss stale reviews | Yes (on push) |
| Required check | `Build and push image` only |
| Merge method | Squash only |
| Merge queue | Enabled — `ALLGREEN` grouping strategy |
| Max entries to build | 2 |

E2E checks are **informational** — they do not block merging. Only `Build and push image` is required.

## Triage tiers

### Ready to land
- `reviewDecision: APPROVED` + CI green (`Build and push image: SUCCESS`) + `mergeable_state: clean`
- Action: `gh pr merge <N> --repo projectbluefin/common --squash --auto`

### Needs rebase
- `mergeable_state: dirty`
- Action: fetch branch, `git rebase origin/main`, resolve conflicts, force-push
- For fork PRs: `gh pr view <N> --json headRefName,headRepository` to get fork remote

### Needs review
- `reviewDecision: REVIEW_REQUIRED` or blank
- Check if it's castrojo-authored (can't self-approve) — leave it for a human reviewer

### Blocked by submodule boundary
- Touches `system_files/shared/**` → **cannot land here**
- Leave comment pointing to `ublue-os/aurorafin-shared` upstream
- **Never file the upstream ublue-os PR yourself** — tell the author to do it manually
- See `submodule-boundary.md` for full policy

### CHANGES_REQUESTED
- Read the review comment to understand what's needed
- If it's a doc/stale issue — rebase and update the content
- If it's a missing feature/packaging — leave a comment and skip

## PR review workflow

```bash
# 1. Get full open PR list with CI status
gh pr list --repo projectbluefin/common --state open \
  --json number,title,author,labels,reviewDecision,statusCheckRollup

# 2. Check mergeability (triggers GitHub lazy computation)
gh api repos/projectbluefin/common/pulls/<N> --jq '.mergeable,.mergeable_state'

# 3. Check all CI checks
gh pr checks <N> --repo projectbluefin/common

# 4. Queue for merge
gh pr merge <N> --repo projectbluefin/common --squash --auto

# 5. Disable auto-merge (if a PR was queued by mistake)
gh pr merge --disable-auto <N> --repo projectbluefin/common
```

## Rebase pattern for fork PRs

```bash
# Get fork info
gh pr view <N> --repo projectbluefin/common \
  --json headRefName,headRepository \
  --jq '{branch: .headRefName, repo: .headRepository.nameWithOwner}'

# Fetch and rebase
git fetch https://github.com/<fork-owner>/common.git <branch>:<local>
git checkout <local>
git rebase origin/main

# Push back to fork
git push https://github.com/<fork-owner>/common.git <local>:<branch> --force
```

## Known infra issue (as of 2026-06-04)

E2E GNOME smoke tests failing on all branches with:
```
cp: cannot stat '.../usr/lib/modules/.../vmlinuz': No such file or directory
```
This is a **CI infrastructure issue** (knuckle headless ISO boot), not caused by PR changes.
Since `Build and push image` is the only required check, affected PRs can still land.

## Common PR comment templates

**Submodule boundary:**
```
This PR touches `system_files/shared/` which is read-only here — materialized from
`ublue-os/aurorafin-shared`. Changes must go upstream to ublue-os/aurorafin-shared first.
Agent cannot file PRs in ublue-os repos — please report upstream manually.
```

**Superseded:**
```
Superseded — [explain what on main covers this]. Closing.
```
