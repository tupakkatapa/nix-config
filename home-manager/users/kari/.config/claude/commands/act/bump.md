
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are bumping the version for a release and cutting its changelog heading. For changelog *content* (consolidating, wording, what to include), this delegates to `/tt:act:changelog` — do not restate those rules here. If the intent is only to tidy/update the changelog **without** a version bump, use `/tt:act:changelog` instead.

## 1. Determine Version Status

Find the current version in the codebase (`pyproject.toml`, `Cargo.toml`, `package.json`, `flake.nix`, or `__version__`).

- If the version was **already bumped** for this release cycle, **do not bump again** — just ensure the changelog heading + date are correct (§3).
- Only bump when actually cutting a new release.

## 2. Choose the Increment

Semantic Versioning, driven by the consolidated change set (run `/tt:act:changelog`'s "Identify Changes" step to see it):

| Bump | When |
|---|---|
| Patch (z) | Bug fixes, minor improvements |
| Minor (y) | New features, non-breaking changes |
| Major (x) | Breaking changes |

A single breaking change forces a major (or minor pre-1.0 by project policy). State the chosen increment and why.

## 3. Cut the Release

1. **Changelog content** — run `/tt:act:changelog` to consolidate `## [Unreleased]` into release-ready entries (its format + include/exclude rules apply).
2. **Promote the heading** — rename `## [Unreleased]` to `## [x.y.z] - YYYY-MM-DD`, then add a fresh empty `## [Unreleased]` above it.
   - **Date = the production-release day**, never the staging day (see `/tt:act:changelog` §4). If the release reaches prod on a later day, use that day; when unsure, ask.
3. **Version string** — update it in the single source of truth (the file from §1). Update lockfiles/derived metadata only if the project regenerates them on bump.

## 4. Report

State: old → new version, the increment type and rationale, the release date used (and that it is the prod date), and a one-line summary of the consolidated changelog sections. Do not commit unless told.
