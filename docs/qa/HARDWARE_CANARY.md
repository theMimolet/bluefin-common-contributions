# Hardware Canary Program — Design Intent

**Status: Not yet implemented.** This document describes the intended design
for real-hardware pre-promotion testing. The current process is manual.

---

## What it is

A distributed testing effort using volunteer hardware to validate releases
across diverse device configurations before general availability. VM-based CI
cannot reproduce hardware-specific failure classes:

1. Suspend / resume (S3/S4, ACPI quirks)
2. USB-C / docks / alt-mode (power delivery, DP, hot-plug)
3. GPU power management / display hotplug
4. Wi-Fi / Bluetooth / firmware (iwlwifi, btusb, reconnect)
5. TPM / Secure Boot / disk unlock edge cases
6. Audio / webcam / microphone
7. Battery / thermals / ACPI platform behavior

---

## Current manual process

File a **Hardware test report** issue in `projectbluefin/common` using the
`.github/ISSUE_TEMPLATE/hardware-test-report.yml` template.

Include:
- exact image digest or tag tested
- hardware make/model/generation
- test date
- pass/fail/untested status for all 7 categories
- pstore/kdump evidence (linked or pasted inline)
- severity: `all-clear`, `degraded`, or `blocker`

The template adds `hardware/test-report` and `source:manual` automatically.
Maintainers add `hardware/all-clear` or `hardware/blocker` after triage.

**Do not promote while an open `hardware/blocker` issue targets the candidate
digest or tag.**

Find open blockers:
```bash
gh search issues --label "hardware/blocker" --owner projectbluefin --state open
```

For more detail on the hardware test categories, see
[`../hardware-testing.md`](../hardware-testing.md).

---

## Intended future design

When the program is implemented:
- Volunteer devices run standard test procedures covering the 7 categories
- Results are filed as GitHub issues with structured labels
- A promotion workflow queries for open `hardware/blocker` issues and blocks
  promotion if any are unresolved
- A 3–5 day testing window precedes each LTS stable promotion

Implementation tracking: [#405](https://github.com/projectbluefin/common/issues/405) (QA epic)

---

## Related

- [`../hardware-testing.md`](../hardware-testing.md) — current report format and promotion policy
- [`PROMOTION_GATES.md`](PROMOTION_GATES.md) — full gate pipeline
