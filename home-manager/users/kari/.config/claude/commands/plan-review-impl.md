---
description: "Plan, review the plan, then implement, in one pass with no user gates. For new features and changes large enough to need a design; /tt:start runs it inside a fresh worktree."
argument-hint: "[what to build | issue id]"
---

You are running **plan → review the plan → implement** in one continuous pass. The premise: a flawed plan is cheaper to fix than flawed code, so the design is reviewed before any code exists.

Not for: a bug (`/tt:debug`), a small change that needs no design (`/tt:impl`), or a subject too unfamiliar to plan (`/tt:research` first).

## Discipline
1. **Auto-advance.** No user checkpoints between phases. The task as given is the scope; derive what it leaves open and record it as an open decision with a default.
2. **Stop and report, never improvise,** when any of these holds:
   - the review finds the core approach unsound (wrong abstraction, missing prerequisite, success criteria unachievable as scoped);
   - **the plan contains a breaking change or a regression the user has not explicitly accepted** — a plan this cycle wrote cannot accept its own break;
   - a required input is missing (unknown library, undocumented external service, missing credentials);
   - implementation shows the plan is wrong in a way that changes the approach.
   The report names the blocker and what would unblock it.
3. **The review amends the plan; it does not replace it.** Phase 3 implements the amended plan.
4. **No commit.** The cycle ends with verified changes in the working tree.

## 1. Plan
Run `/tt:plan` on the task: investigate, read the matching language context, write the plan file with success criteria, Non-goals and open decisions. Skip its approval and next-step sections.

## 2. Review the plan
Run `/tt:review` with the plan file as the artefact, mode = planning. There is no diff: the lenses judge the design. Is the scope free of gold-plating? Are boundaries and data flow right? Does it keep existing callers, clients and stored data working (`compatibility`)? Are failure modes and trust boundaries covered? Is every success criterion testable?

Disposition, without asking:
- **Blocker / High** → amend the plan to resolve it, unless Discipline 2 applies.
- **Medium** → fold into the plan where it touches a planned step; else note it under "Deferred" in the plan.
- **Low / Nit** → note under "Deferred".

## 3. Implement
Run `/tt:impl` on the amended plan. A minor deviation (same intent, different mechanics) gets a one-line amendment in the plan file and the work continues.

## 4. Verify
- Each success criterion is demonstrably met, by the means the plan named.
- The formatter is clean; pre-commit hooks and the tests that cover the changed code pass. The full suite is CI's.
- Review findings folded into the plan are addressed; deferred ones are listed in the plan.

## 5. Report
Plan file path, what was built, the verification evidence, deferred findings. Next: `/tt:ship`.
