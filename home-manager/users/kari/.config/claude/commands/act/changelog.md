
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are updating the changelog (Keep a Changelog + Semantic Versioning) **without bumping the version**. Use this to clean up, consolidate, or add entries for in-flight work. To also bump the version and cut a release heading, use `/tt:act:bump` (it calls this procedure for the changelog part).

## 1. Identify Changes

Determine the integration branch dynamically (don't hardcode `main`):

```bash
integration=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
integration=${integration:-$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)}
integration=${integration:-main}

git log "$integration..HEAD" --oneline --no-merges
```

Or diff against the last version-bump commit on a feature branch:
`git log $(git log --grep '^chore: bump' -1 --format=%H)..HEAD --oneline --no-merges`.

New, unreleased work goes under `## [Unreleased]`. Do **not** invent a version heading or date here — that is `/tt:act:bump`'s job at release time.

## 2. Format Rules

The default failure mode is **too many, too granular, too technical** entries (one per commit/PR, written for an engineer). Correct for that hard:

- **Consolidate to capabilities, never to commits.** One entry per user-visible capability or fix. Merge *every* commit, PR, and hotfix that contributed to it into a **single cumulative line describing the net end state** as shipped. One line per commit = wrong. A whole release is a **handful** of entries, not dozens — if a section runs long, you are too granular; group it.
- **Cumulative, not a journey.** Describe where the release *landed*, not the steps to get there. A feature added then refined across several commits is **one** entry.
- **Client-targeted, not engineer-targeted.** Each entry reads like a `/tt:act:issue` title: short, leads with *what changed* for the user, plain language, no ticket-speak (no ticket IDs, no PR numbers, no commit hashes).
- **Cut the minutiae.** Omit endpoint paths, parameter names, rate limits, scopes, internal flags/IDs, migrations, and symbol names **unless the user directly types or sees them**. Prefer the user-visible outcome over the implementation detail.
- **Brief. Human readable.**

### Consolidation example (Don't → Do)

```markdown
Don't (per-commit, technical — the usual over-detailed output):
- Add `?status=` multi-value filter to the list endpoint
- Add owner-scoped filter to the list endpoint
- Return 409 on duplicate create
- Change the email link target
- Lower the rate limit 10 → 5/min

Do (one cumulative, user-facing line):
- Reworked <feature>: clearer duplicate handling and richer filtering
```

## 3. What to Include / Exclude

Include:
- New user-facing features and capabilities (one consolidated line each)
- Behaviour changes a user would notice (response shape, defaults, flows)
- Bug fixes that affected real user-visible behaviour
- Breaking changes, removals, deprecations (name the replacement + timeline)

Exclude:
- CI/CD, test infrastructure, internal refactoring, migrations, dev tooling, code-quality
- Performance work **unless a user would notice it** (then state the *benefit*, not the mechanism — "faster project listing for large accounts", not the query/index/policy change)
- Anything a client cannot see or act on — if in doubt, leave it out

## 4. Sections & Dating

Section order within a version:

```markdown
### Added
### Changed
### Fixed
### Removed
### Deprecated
```

**Dating rule — production, not staging.** A version heading is dated with the day its changes reach **production** (merge to the prod branch, typically `main`), **never** the staging date. Until work ships to prod it stays under `## [Unreleased]`. If the same version is on staging today and prod next week, the date is next week's. When unsure which day a release hits prod, ask rather than guess. (Re-derive a stale date from the actual prod-merge day at release time.)

## 5. Deprecations

- Check the project's deprecations document (e.g. `docs/deprecations.md`) if present, for items sunset in this version.
- Remove sunset items from that document (or mark completed).
- Ensure the changelog's `Removed` section documents what was removed.

## Example Entry

```markdown
## [0.4.0] - 2026-02-05

### Added

- New capability — one line, written for the consumer (default + migration note if behaviour changes)

### Changed

- Behaviour change a caller would notice (response shape, default value)

### Fixed

- Bug that affected real user-visible behaviour (not internal refactors)

### Deprecated

- Capability scheduled for removal — name the replacement and the timeline

### Removed

- Capability that no longer exists (and which release deprecated it, if applicable)
```
