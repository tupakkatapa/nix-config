
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

```bash
git log main..HEAD --oneline --no-merges
```

Or diff against the last version bump commit if on a feature branch.

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
- Dev tooling (Doppler, env configs)
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

- Check `docs/deprecations.md` for items sunset in this version
- Remove sunset items from deprecations doc (or mark as completed)
- Ensure "Removed" section documents what was removed

## 5. Version Bump (if needed)

Only if releasing new version:
- Patch (z): Bug fixes, minor improvements
- Minor (y): New features, non-breaking changes
- Major (x): Breaking changes

## Example Entry

```markdown
## [0.2.7] - 2026-02-05

### Added

- API key support for annotations endpoint with `annotations:read` scope
- Global email uniqueness constraint for active users

### Fixed

- Annotators cannot QC their own work
- Email delivery reliability with retry logic

### Deprecated

- QC manual reviewer assignment (sunset in next release)
```
