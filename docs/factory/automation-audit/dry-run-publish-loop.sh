#!/usr/bin/env bash
# Dry-run verification of the publish loop.
#
# Exercises every artifact-producing step against a canary registry without
# touching production tags. Designed to run nightly via the chaos-suite or
# on-demand via `gh workflow run`.
#
# Pass criteria: same source digest produces same canary digest twice in a row.
# This is the runtime idempotency invariant referenced in publish-loop-test-plan.md.

set -euo pipefail

OWNER="${OWNER:-projectbluefin}"
SOURCE_IMAGE="${SOURCE_IMAGE:-bluefin}"
SOURCE_TAG="${SOURCE_TAG:-testing}"
CANARY_IMAGE="${SOURCE_IMAGE}-canary"
RUN_ID="$(date -u +%Y%m%d-%H%M%S)"
LOG="/tmp/publish-loop-dryrun-${RUN_ID}.log"

log()  { printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*" | tee -a "$LOG"; }
fail() { log "FAIL: $*"; exit 1; }

trap 'log "Logs: $LOG"' EXIT

log "==> 1. Resolve source digest"
SOURCE_DIGEST=$(skopeo inspect "docker://ghcr.io/${OWNER}/${SOURCE_IMAGE}:${SOURCE_TAG}" \
  --format '{{.Digest}}') || fail "could not resolve source digest"
log "    source = ghcr.io/${OWNER}/${SOURCE_IMAGE}@${SOURCE_DIGEST}"

log "==> 2. Verify cosign signature on source"
cosign verify "ghcr.io/${OWNER}/${SOURCE_IMAGE}@${SOURCE_DIGEST}" \
  --certificate-identity-regexp "https://github\\.com/${OWNER}/.+" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  >/dev/null 2>>"$LOG" \
  || fail "cosign verify on source"
log "    OK"

log "==> 3. Skopeo copy → canary (run 1)"
skopeo copy --all \
  "docker://ghcr.io/${OWNER}/${SOURCE_IMAGE}@${SOURCE_DIGEST}" \
  "docker://ghcr.io/${OWNER}/${CANARY_IMAGE}:run1" \
  >>"$LOG" 2>&1 || fail "skopeo copy run1"
CANARY_DIGEST_1=$(skopeo inspect "docker://ghcr.io/${OWNER}/${CANARY_IMAGE}:run1" \
  --format '{{.Digest}}')
log "    canary:run1 = ${CANARY_DIGEST_1}"

log "==> 4. Skopeo copy → canary (run 2 — idempotency probe)"
skopeo copy --all \
  "docker://ghcr.io/${OWNER}/${SOURCE_IMAGE}@${SOURCE_DIGEST}" \
  "docker://ghcr.io/${OWNER}/${CANARY_IMAGE}:run2" \
  >>"$LOG" 2>&1 || fail "skopeo copy run2"
CANARY_DIGEST_2=$(skopeo inspect "docker://ghcr.io/${OWNER}/${CANARY_IMAGE}:run2" \
  --format '{{.Digest}}')
log "    canary:run2 = ${CANARY_DIGEST_2}"

[ "$CANARY_DIGEST_1" = "$CANARY_DIGEST_2" ] \
  || fail "IDEMPOTENCY VIOLATION: run1 ($CANARY_DIGEST_1) != run2 ($CANARY_DIGEST_2)"
log "    OK — idempotency invariant held"

log "==> 5. SBOM presence"
cosign download sbom "ghcr.io/${OWNER}/${SOURCE_IMAGE}@${SOURCE_DIGEST}" \
  >/tmp/sbom.json 2>>"$LOG"
jq -e '.bomFormat == "CycloneDX"' /tmp/sbom.json >/dev/null \
  || log "    WARN: SBOM missing or wrong format (expected after #513 lands)"

log "==> 6. SLSA provenance attestation"
gh attestation verify "oci://ghcr.io/${OWNER}/${SOURCE_IMAGE}@${SOURCE_DIGEST}" \
  --owner "${OWNER}" >/dev/null 2>>"$LOG" \
  || log "    WARN: provenance missing (expected after actions#86 lands)"

log "==> 7. GitHub Release exists referencing source digest"
LATEST_TAG=$(gh api "repos/${OWNER}/${SOURCE_IMAGE}/releases/latest" --jq '.tag_name' 2>>"$LOG" || echo "")
if [ -n "$LATEST_TAG" ]; then
  gh release view "$LATEST_TAG" --repo "${OWNER}/${SOURCE_IMAGE}" --json body \
    --jq '.body' | grep -q "${SOURCE_DIGEST}" \
    && log "    OK — release ${LATEST_TAG} references digest" \
    || log "    WARN: release body does not reference current testing digest"
else
  log "    WARN: no GitHub Release found"
fi

log "==> 8. ISO availability"
ISO_URL="https://download.projectbluefin.io/${SOURCE_IMAGE}-${SOURCE_TAG}.iso"
if curl -sI "$ISO_URL" | grep -qi 'HTTP/.* 200'; then
  log "    OK — ISO at ${ISO_URL}"
else
  log "    WARN: ISO not available at ${ISO_URL} (expected after iso-auto-rebuild lands)"
fi

log "==> 9. Cleanup canary tags (idempotent)"
for tag in run1 run2; do
  gh api -X DELETE \
    "/orgs/${OWNER}/packages/container/${CANARY_IMAGE}/versions/$( \
      gh api "/orgs/${OWNER}/packages/container/${CANARY_IMAGE}/versions" \
        --jq ".[] | select(.metadata.container.tags[] == \"${tag}\") | .id" 2>/dev/null \
    )" >/dev/null 2>&1 || true
done

log ""
log "PUBLISH LOOP DRY-RUN PASSED"
log "  source digest:   ${SOURCE_DIGEST}"
log "  canary identity: ${CANARY_DIGEST_1}"
log "  log:             ${LOG}"
