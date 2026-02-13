
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- Detect available tooling by checking for: `shell.nix`, `flake.nix`, `Makefile`, `Justfile`, or similar.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

You are preparing a ralph-loop for an iterative development task.

Ralph works by intercepting Claude's exit via a stop hook and re-feeding the same prompt. The prompt stays constant — context evolves through file and git changes between iterations.

### Suitability Check
Ralph is good for:
- Clearly-defined deliverables with automated verification (tests, linters)
- Refinement-heavy tasks where iteration improves output
- Greenfield development

Ralph is bad for:
- Decisions requiring human judgment
- Ambiguous success definitions
- Production troubleshooting needing targeted investigation

If the task is a bad fit, say so and suggest an alternative approach.

## 1. Understand the Task
- Clarify what needs to be built or fixed
- Identify verifiable completion criteria (tests pass, linter clean, feature works)

## 2. Create Plan
Write `RALPH.md` in the project root with:
- **Goal** — what the loop should achieve
- **Completion criteria** — concrete, verifiable conditions
- **Phases** — incremental steps, each building on the previous
- **Testing** — what to test (positive and negative cases)

Follow the design principles from `/tt-implement`.

## 3. Craft the Command
```
/ralph-wiggum:ralph-loop "<prompt>" --max-iterations <N> --completion-promise "<text>"
```

- `--completion-promise` (required) — exact string match that signals completion
- `--max-iterations` (optional, default: unlimited) — always set this as a safety net

### Prompt Guidelines
Since the prompt is re-fed verbatim each iteration:
- Write it as standing instructions, not a one-time request
- Define incremental phases, not one monolithic goal
- Include self-correction: check previous work, run tests, fix failures, repeat
- Include escape hatch: what to document if stuck after N iterations
- End with: `Output: <promise>TEXT</promise>` matching `--completion-promise`

To cancel a running loop: `/cancel-ralph`

## 4. Present
Present the `RALPH.md` plan and the ready-to-run command for user approval.
