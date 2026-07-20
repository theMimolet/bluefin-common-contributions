---
name: write-a-skill
version: "1.0"
last_updated: "2026-07-20"
tags: [skills, authoring, documentation]
description: >-
  Author a new agent skill for projectbluefin/common. Covers front-matter,
  size budget, canonical linking, verification sections, and the skill-drift
  mandate. Use when creating a new docs/skills/*.md file or splitting an
  oversized skill.
metadata:
  type: procedure
---

# Writing a Skill

A skill is an agent-facing markdown file in `docs/skills/*.md` that records how
to work safely in a specific domain. Every agent session that introduces a new
domain or discovers a durable pattern must write or update one.

## When to create a new skill

Create a new skill only when the change introduces a reusable domain that has
no existing home. Prefer updating an existing skill. Typical triggers:

- A new workflow, service, tool, or repo convention is introduced.
- A non-obvious workaround or correctness requirement is discovered.
- A project-internal fact (image names, tags, registry paths, workflow outputs)
  is documented and needs a verification command.

Do **not** create a skill for one-off task notes, ephemeral state, or obvious
developer knowledge. Do not duplicate content that already lives in another
skill or canonical source.

## Required front-matter

Every `docs/skills/*.md` file must start with:

```yaml
---
name: <kebab-case-skill-name>
version: "<semver>"
last_updated: YYYY-MM-DD
tags: [tag1, tag2, tag3]
description: "<capability sentence>. Use when <triggers>."
metadata:
  type: <procedure | reference | runbook | policy>
---
```

- `name`: kebab-case, matches filename stem.
- `version`: semver string in quotes (e.g., `"1.0"`).
- `last_updated`: ISO-8601 date.
- `tags`: 3-6 lowercase keywords.
- `description`: ≤256 characters, third person, capability first sentence,
  "Use when ..." second sentence.
- `metadata.type`: one of `procedure`, `reference`, `runbook`, `policy`.

## Description rules

The description is the only text an agent sees when choosing a skill. Make it
specific enough to trigger loading:

- **Good:** `Documents ... . Use when editing ... or debugging ... .`
- **Bad:** `Helps with ... .`

Keep it under 256 characters. Preserve the original body coverage if you
shorten the description.

## Size budget

- **Soft max:** 200 lines.
- **Hard max:** 500 lines.
- Existing oversized skills are grandfathered until Phase E migrates them to
  per-skill directories with `SKILL.md` + `references/`.

If a draft exceeds 200 lines, split rarely-needed detail into a separate
`references/` file and link to it.

## Link to canonical sources

Do not duplicate facts that live in source files, workflow YAML, or upstream
docs. Instead, record how to derive the fact:

- Project-internal facts: add a `## Verification` section with the exact
  command to re-derive the fact (`gh api`, `grep`, `skopeo inspect`, etc.).
- External tools: record the Context7 library ID in
  `metadata.context7-sources`, then link to the section in the upstream docs.

See [`image-registry.md`](./image-registry.md) for the reference
implementation of a verification section.

## Body sections

A well-formed skill contains:

1. `## When to Use` — specific triggers andscopes.
2. `## Core Process` or `## What this covers` — the agent workflow.
3. `## Red Flags` — mistakes that violate repo policy.
4. `## Verification` — commands to self-check project-internal facts.

## The skill-drift mandate

Every implementation PR must include a matching skill update in the same PR.
The skill-drift CI check warns when code paths change without a corresponding
skill-path change. Treat warnings as hard requirements.

- Why: [`skill-improvement.md`](./skill-improvement.md)
- How the check works and waiver process: [`skill-drift.md`](./skill-drift.md)

## Verification

Before committing a new or updated skill:

- [ ] Front-matter includes all required keys and `description` ≤256 chars.
- [ ] `metadata.type` is appropriate for the content.
- [ ] Body has `When to Use`, process/reference content, `Red Flags`, and
      `Verification` sections.
- [ ] Project-internal facts include a verification command.
- [ ] `bash scripts/check-skill-frontmatter.sh` passes with no errors.
- [ ] File is under 200 lines (soft) or under 500 lines (hard max).
