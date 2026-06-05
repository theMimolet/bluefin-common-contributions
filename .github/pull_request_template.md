<!--
## Thank you for contributing

Please [read the README](../README.md) and ensure your change goes to the correct directory.

### Changes related to Bluefin
If your change is gnome or bluefin change, make sure you put the change under the  system_files/bluefin/ folder.

## Global changes
Global changes that are not GNOME-specific should go in the `system_files/shared/` folder. This is also used by [Aurora](https://github.com/ublue-os/aurora), so ensure no GNOME-related changes end up here.

-->

## PR pipeline

```
opened ──▶ review ──▶ approved ──▶ merged
                    [lgtm]      auto-merge
                                when CI green
```

> Add `do-not-merge` at any time to block automation.
> `/approve` or `lgtm` from a maintainer triggers merge queue.

## What does this change?

<!-- Required: one sentence -->

## Why?

<!-- Link the issue this closes: "Closes #NNN" -->
Closes #

## Checklist

- [ ] `just check` passes
- [ ] `pre-commit run --all-files` passes
- [ ] PR title follows Conventional Commits (`fix:`, `feat:`, `chore:`, etc.)
