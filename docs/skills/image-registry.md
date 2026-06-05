---
name: image-registry
description: "ublue-os vs projectbluefin OCI publishing split — production images still at ghcr.io/ublue-os, not projectbluefin."
---

# Image Registry — ublue-os vs projectbluefin

## Critical: the org migration is incomplete for OCI images

Production Bluefin images are **still published at `ghcr.io/ublue-os/`**, not
`ghcr.io/projectbluefin/`. The org migration for OCI image publishing has not happened.

**Do NOT change `ublue-os` to `projectbluefin` in image references without explicit maintainer
sign-off.** This would break OTA updates, E2E CI, and the rollback helper for all users.

## Reference table

| Registry path | Status | Notes |
|---|---|---|
| `ghcr.io/ublue-os/bluefin*` | ✅ Active production | All Bluefin image variants |
| `ghcr.io/ublue-os/bluefin:lts` | ✅ Active production | LTS stream |
| `ghcr.io/projectbluefin/bluefin:testing` | ✅ Active testing | Bluefin testing candidate tag |
| `ghcr.io/projectbluefin/bluefin:lts-testing` | ✅ Active testing | Bluefin LTS testing candidate tag |
| `ghcr.io/ublue-os/brew` | ✅ Active | Homebrew layer consumed by bluefin |
| `ghcr.io/ublue-os/akmods-*` | ✅ Active | Kernel modules |
| `ghcr.io/projectbluefin/common` | ✅ Active | Common shared layer (this repo) |
| `ghcr.io/projectbluefin/dakota` | ✅ Active | Dakota image |

## Files where ublue-os image refs MUST remain ublue-os

- `system_files/bluefin/usr/bin/ublue-rollback-helper` — reads `IMAGE_VENDOR` from
  `image-info.json` to construct the registry path; changing the vendor changes the OTA target
- Any ujust recipe that references the image registry for rollback/rebase

## Allowed projectbluefin testing refs in CI workflows

`validate.yml` maintains an explicit allowlist. The following workflow files are allowed to use `projectbluefin` testing-stream refs:

| Workflow file | Allowed refs |
|---|---|
| `promotion-candidate-e2e.yml` | `ghcr.io/projectbluefin/bluefin:testing`, `ghcr.io/projectbluefin/bluefin:lts-testing` |
| `e2e.yml` | `ghcr.io/projectbluefin/bluefin:testing`, `ghcr.io/projectbluefin/bluefin:lts-testing` |
| `pr-e2e.yml` | `ghcr.io/projectbluefin/bluefin:testing` |

These are testing-only candidate tags used for E2E gates. They are **not** production OTA targets. All other `ghcr.io/projectbluefin/bluefin*` refs in workflow files are blocked by `validate.yml`.

## How ublue-rollback-helper uses the registry

```bash
IMAGE_VENDOR="$(jq -r '."image-vendor"' < "$IMAGE_INFO")"
IMAGE_REGISTRY="ghcr.io/${IMAGE_VENDOR}"
```

`image-info.json` is written at build time by `build_files/base/00-image-info.sh` in the
bluefin repo. `IMAGE_VENDOR` is set from the `IMAGE_VENDOR` build arg (currently `projectbluefin`
in bluefin's Justfile — but this sets the *metadata* vendor, not the *publishing* registry).
The production publishing still goes to `ublue-os` org via the build workflow secrets.

`validate.yml` includes a guard that fails if workflow files or `ublue-rollback-helper`
reference `ghcr.io/projectbluefin/bluefin`, `aurora`, or `bazzite`.

Tracked: #468
