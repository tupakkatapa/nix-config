
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

Update changelog using "Keep a Changelog" format with Semantic Versioning.

## 1. Determine Version Status

Check current version in codebase (e.g., `pyproject.toml`, `Cargo.toml`, `package.json`, `flake.nix`, or `__version__`):
- If version was already bumped for this release cycle, **do not bump again**
- Only bump if releasing a new version

## 2. Identify Changes Since Last Release

Determine the integration branch dynamically (don't hardcode `main`):

```bash
integration=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
integration=${integration:-$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null)}
integration=${integration:-main}

git log "$integration..HEAD" --oneline --no-merges
```

Or diff against the last version-bump commit if on a feature branch (`git log $(git log --grep '^chore: bump' -1 --format=%H)..HEAD --oneline --no-merges`).

## 3. Update Changelog

### Format Rules

- **Client-focused**: Only include changes clients care about
- **No commit hashes**: Keep it clean and readable
- **Consolidate**: Group related commits into single entries
- **Human readable**: Clear, brief descriptions

### What to Include

- New features and capabilities
- API changes (endpoints, fields, scopes)
- Bug fixes that affected users
- Breaking changes and removals
- Deprecation notices

### What to Exclude

- CI/CD changes
- Test infrastructure
- Internal refactoring
- Migration details
- Dev tooling and environment configuration
- Code quality improvements

### Section Order

```markdown
### Added
### Changed
### Fixed
### Removed
### Deprecated
```

## 4. Handle Deprecations

- Check the project's deprecations document (e.g. `docs/deprecations.md`) if present, for items sunset in this version
- Remove sunset items from that document (or mark as completed)
- Ensure the "Removed" section of the changelog documents what was removed

## 5. Version Bump (if needed)

Only if releasing new version:
- Patch (z): Bug fixes, minor improvements
- Minor (y): New features, non-breaking changes
- Major (x): Breaking changes

## Example Entry

```markdown
## [0.4.0] - 2026-02-05

### Added

- New endpoint or capability — one line per change, written for the consumer
- New configuration option (with default and migration note if it changes behaviour)

### Changed

- Behaviour change a caller would notice (e.g. response shape, default value)

### Fixed

- Bug that affected a real user-visible behaviour (not internal refactors)

### Deprecated

- Capability scheduled for removal — name the replacement and the timeline

### Removed

- Capability that no longer exists (and which release deprecated it, if applicable)
```
