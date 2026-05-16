
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are writing documentation as the primary task — a new tutorial, how-to, reference page, explanation, runbook, ADR, or changelog entry — rather than auditing docs as a side-effect of review. Substantive guidance comes from the `/tt:lens:docs` lens applied in **authoring** mode, anchored by the Diátaxis framework (Procida).

Distinct from:
- `/tt:lens:docs` — dimensional viewpoint, applied *during* review/planning/diagnosis. This agenda is what you reach for when docs are the deliverable.
- `/tt:explain` (action) — produces an in-conversation explanation for the user. This agenda produces durable files in the repo.

## 1. Clarify Subject and Audience

If the subject is unclear, ask the user to choose:
- [ ] A new capability that needs documenting
- [ ] An existing capability that is currently undocumented or stale
- [ ] An incident/runbook (operational response)
- [ ] An architectural decision record (ADR)
- [ ] A changelog entry for a release

Then identify the **reader**. A doc with no concrete reader in mind is fated to be wrong for everyone. State explicitly: who will read this, what they already know, what task they are trying to accomplish or what understanding they are seeking.

## 2. Choose the Diátaxis Quadrant

Diátaxis (Procida) separates documentation into four distinct modes. Picking the wrong mode is the most common docs failure — a tutorial written like reference frustrates learners; reference written like a tutorial buries the facts.

| Mode | Orientation | Reader is… | Shape |
|---|---|---|---|
| **Tutorial** | Learning | Learning by doing | Safe, complete walk-through with an outcome to point at; no choices |
| **How-to** | Task | Doing | Numbered steps assuming prerequisites; goal-oriented; multiple valid approaches OK |
| **Reference** | Information | Looking up | Complete, accurate, neutral; structured for scanning; no narrative |
| **Explanation** | Understanding | Reflecting | Context, design rationale, alternatives considered; discursive |

Special cases (canonical formats):
- **Runbook** → How-to (task: respond to incident X). Test the procedure under a game day before declaring it ready.
- **Changelog** → Reference (what changed in version X). Use *Keep a Changelog* format (keepachangelog.com, current 1.1.0): Added / Changed / Deprecated / Removed / Fixed / Security. See `/tt:actions:bump`.
- **ADR** → Explanation (why we chose X over Y, what we rejected). Use MADR format (adr.github.io/madr): context → decision drivers → considered options → decision → consequences. Immutable once accepted; supersede rather than rewrite.
- **README** → usually mixed; if so, *separate the sections* into the four modes rather than blending.

A single document should serve **one** mode. If the subject needs more than one, write multiple documents and cross-link them.

## 3. Research

- Read the code or system being documented. Do not document from memory — code drifts.
- Identify existing documentation that touches the subject; decide whether to extend, replace, or cross-link.
- For tutorials and how-tos: execute the steps yourself in a clean environment. A doc you have not walked through is a doc that does not work.
- For reference: derive the surface from the code (function signatures, config schema, CLI flags, API endpoints). Anything not in code does not belong in reference.
- For explanation: locate the original design discussion (commits, ADRs, prior docs). If none exists, talk to the user to capture the rationale before it's lost.

## 4. Apply the Lens Panel (mode = authoring)

Read lens files lazily — `commands/lens/docs.md` Dimensions section for the primary lens; supporting lenses only when their surface applies. Consult:

- **`/tt:lens:docs`** — Diátaxis discipline, fact-check against implementation, audience fit, completeness for the chosen mode.
- **`/tt:lens:scope`** — does this doc say only what is essential to the reader? Cut paragraphs that gold-plate, repeat code comments, or document obvious behaviour.
- **`/tt:lens:ux`** — the doc is a surface. Apply Nielsen heuristics to it: status visibility (TOC, breadcrumbs), error recovery (troubleshooting), consistency, minimalism.
- **`/tt:lens:aesthetics`** — prose discipline. Short sentences. Active voice. One idea per paragraph. No filler. No throat-clearing introductions ("In this document we will discuss…").

## 5. Draft

Write to the chosen mode's shape. Do not blend modes within a single doc.

For tutorials and how-tos:
- One outcome per document. Numbered steps. Each step states the action and what the reader should observe.
- Verify each step against a real run. Include exact commands and expected output.

For reference:
- One symbol/entity per section. Consistent ordering across sections (signature → parameters → returns → errors → example).
- Auto-derive from code where possible; hand-written reference rots faster.

For explanation:
- State the question being answered up front.
- Present alternatives considered, not only the chosen path. Cite trade-offs.

## 6. Place in the Docs Tree

- Follow the project's existing docs layout. If none exists, propose one: typically `docs/tutorials/`, `docs/how-to/`, `docs/reference/`, `docs/explanation/`.
- For ADRs: `docs/adr/NNNN-<slug>.md` numbered sequentially (MADR or similar conventions).
- For changelogs: a single `CHANGELOG.md` at the repo root (Keep a Changelog format — see `/tt:actions:bump`).
- Cross-link related docs; an unreachable doc is an absent doc.

## 7. Verify

- Re-run any commands or code blocks in the doc against a clean environment.
- Fact-check claims about behaviour against current code (`grep`, run tests).
- Ask a fresh reader (or simulate one): can they follow it without your help?
- Check links resolve. Check anchors. Check code blocks parse.

## 8. Handoff

Suggest:
- **`/tt:review`** against the new docs (scope = "the new/changed documentation files"). The lens panel — especially `docs`, `scope`, `ux`, `aesthetics` — applies cleanly to prose.
- **`/tt:actions:commit`** when the review is clean.
