
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are performing a **structural change that preserves behaviour**. This agenda is bound by Kent Beck's *two hats* rule: while wearing the structural hat, you do not change what the code does — only how it is arranged. Distinct from `/tt:impl` (adds capability) and `/tt:debug` (changes behaviour to fix a defect). The substantive judgement comes from the `/tt:pov:*` panel applied in **restructure** mode — "what is the smallest behaviour-preserving change that reduces complexity here?"

## 1. Clarify Scope
If the refactor target is unclear, ask the user to choose:
- [ ] A specific module/file/function (ask which)
- [ ] A code smell across the codebase (ask which — duplication, long function, feature envy, etc.)
- [ ] Preparation for an upcoming feature (ask which, what shape it needs)
- [ ] A specific Fowler refactoring (ask which — extract function, inline variable, replace conditional with polymorphism, etc.)

State explicitly: **no behaviour change**. If the refactor exposes a latent bug mid-session:
1. **Commit the green refactor steps so far** (each step independently green per §5). Never carry uncommitted structural change into a debug session — the diagnosis would see two unrelated diffs at once.
2. **If a step is mid-flight and not green**, revert it (`git restore .` or equivalent) to return to the last green state.
3. **Then switch to `/tt:debug`.** Return here when the bug is fixed and the regression test is green.

## 2. Pin Behaviour
Before restructuring, ensure current behaviour is locked down:
- Are there tests covering the surface you will touch? Run them; they must be green *before* you start.
- If coverage is thin, add **characterisation tests** first (Feathers): tests that pin down what the code currently does, regardless of whether that is correct. The structural commit is then provably behaviour-preserving.
- Characterisation tests are a separate commit from the refactor itself.

If pinning behaviour is impossible (no seams, no test infrastructure), break dependencies first using Feathers' techniques (see `/tt:pov:testing`). Treat that as its own structural step.

## 3. Apply the Lens Panel (mode = restructure)

Read lens files lazily — pull the dimensions you need, skip lenses with no structural surface. Reframe their dimensions as "what is the smallest move toward this principle that preserves behaviour?".

Typically relevant for refactor:

- **`/tt:pov:quality`** — Fowler's catalogue. Identify smells: duplicated code, long function, large class, long parameter list, feature envy, primitive obsession, switch statements, divergent change, shotgun surgery. For each, name the canonical refactoring (Extract Function, Replace Magic Literal, Replace Conditional with Polymorphism, Move Function, etc.).
- **`/tt:pov:scope`** — accidental complexity to remove outright: dead code, unused abstractions, single-call helpers, configuration knobs no caller overrides, premature generics with one instantiation. Deletion is the cheapest refactoring.
- **`/tt:pov:arch`** — module boundaries to redraw: a function reaching past its layer, a circular import, a class with two reasons to change. Apply Parnas info-hiding and Ousterhout deep modules: the change makes the interface smaller relative to the implementation.
- **`/tt:pov:testing`** — testability as a structural concern: break dependencies (Feathers seams), inject collaborators, expose pure cores from impure shells.
- **`/tt:pov:style`** — formatting, naming, ordering, comment discipline. Often the cheapest first pass; runs last so it doesn't conflict with bigger structural moves.

## 4. Plan the Sequence
Order refactorings smallest-first, each independently verifiable:
- Each step is a named Fowler refactoring (or a small composition of them).
- Each step preserves behaviour — tests stay green throughout.
- Steps build toward the target structure; do not jump.
- Stop when the target structure is reached *or* when further moves would risk behaviour change without stronger tests.

## 5. Execute, Verifying After Each Step
- Apply one refactoring.
- Run the test suite (or at minimum the tests covering the touched surface).
- If green, continue. If red, revert that step and reconsider — never debug forward inside a refactor session.
- Commit at sensible boundaries (per refactoring, or per coherent group of refactorings). Each commit message names the structural move, not a feature.

## 6. Two-Hats Discipline
- A single commit is structural OR behavioural — never both.
- If during refactoring you spot a bug, **do not fix it inside the refactor commit**. Note it, finish the structural step, switch hats, fix it separately (`/tt:debug`).
- If you discover a missing feature need, do not add it inside the refactor commit. Note it for `/tt:impl`.

## 7. Run Automated Checks
Run pre-commit hooks (if configured), linters, and the project's tests. Fix failures before continuing — but failures in a refactor session almost always mean the last step changed behaviour, not that tests are wrong.

## 8. Summary
- Refactorings applied, in order, by name.
- Before/after structural shape (interface size, module count, duplication factor, complexity metric — whichever is relevant).
- Behaviour preservation evidence: which tests covered the surface, whether characterisation tests were added.
- Smells noted but not yet addressed (deferred to follow-up).
- Bugs/features discovered along the way (handed off to `/tt:debug` / `/tt:impl`).

## 9. Handoff
When refactoring is complete, suggest running `/tt:review` to validate the structural change, then `/tt:act:commit`.
