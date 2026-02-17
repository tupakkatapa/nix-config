# Claude Configuration

## Principles

- When unsure, choose the most fundamentally right action instead of asking.
- Fix all failing tests. They run continuously, so failures are from recent changes.
- All changes must pass `nix fmt` and existing tests.

## NixOS Development

NixOS environment. All infrastructure in `~/nix-config` (github.com/tupakkatapa/nix-config).

- NEVER suggest `apt install`, `brew install`, `pip install`, or similar
- Temporary: `nix-shell -p <package>` or `, <command>` (comma runs from nixpkgs)
- Permanent: add to config, `direnv reload`, restart session
- Check packages: `nix eval --json github:tupakkatapa/nix-config#nixosConfigurations.$HOSTNAME.config.environment.systemPackages --apply 'builtins.map (p: p.name)'`
- All hosts: `nix eval --json github:tupakkatapa/nix-config#nixosConfigurations --apply builtins.attrNames`

## Subagent Dispatch

Use Task tool for parallel work. Provide full context upfront — subagents can't ask questions.

- **3+ independent tasks:** dispatch parallel subagents in a single message
- **Codebase exploration:** use Explore subagent (fast, read-only)
- **Background tasks:** `Task(..., run_in_background=true)`
- Scale: simple 1-2, medium 3-4, complex 5-6 agents

When a subagent is blocked, it returns:
```
Problem: [what went wrong]
Attempted: [what was tried]
Solution: [fix if possible]
Alternative: [different approach]
Partial: [results before blocking]
```

## Memory (claude-mem)

Persistent cross-session memory. 3-layer progressive disclosure:

1. `search(query)` — compact index (~50-100 tokens/result)
2. `timeline(anchor_id)` — chronological context around a result
3. `get_observations([ids])` — full details for filtered IDs only

Always filter before fetching full details (10x token savings).

## Skills (superpowers)

Invoke via `Skill` tool. Key workflows:

Planning:
- `brainstorming` — explore ideas without implementation
- `writing-plans` — create plans for later execution
- `executing-plans` — implement a written plan

Implementation:
- `test-driven-development` — TDD workflow
- `systematic-debugging` — bug investigation
- `verification-before-completion` — before claiming done

Review:
- `requesting-code-review` — after completing major work
- `receiving-code-review` — process review feedback

Git:
- `using-git-worktrees` — isolated workspaces
- `finishing-a-development-branch` — complete branch workflow

Agents:
- `subagent-execution` — when YOU are the subagent
- `dispatching-parallel-agents` — 2+ independent tasks
- `subagent-driven-development` — complex agent workflow

## Commands

User-invoked workflows via `/command`. Auto-invoke when user intent clearly matches:

- `/tt-implement` — plan and implement a feature/fix
- `/tt-review` — code review, calls `/tt-check`
- `/tt-check` — run pre-commit, linters, tests
- `/tt-commit` — prepare and create commit (amend if unpushed)
- `/tt-security` — comprehensive security review
- `/tt-explain` — explain topic/code, calls `/tt-mermaid` if diagrams help
- `/tt-mermaid` — create and display Mermaid diagrams

Typical flow: implement → review → commit

## Ralph Loop

User-initiated iterative loop (`/ralph-loop`). When inside:
- Check files/git for previous iteration's work
- Build incrementally on what exists
- Run tests/linters to verify progress
- Output `<promise>TEXT</promise>` when promise is genuinely TRUE
- Don't start from scratch, don't fake promises

## Triggers

| Need | Tool |
|------|------|
| Library/framework docs | context7 MCP |
| NixOS packages/options | nixos MCP |
| Cross-session context | claude-mem search |
| Parallel work (3+ tasks) | Task tool subagents |
| Deep codebase search | Explore subagent |
| Iterative refinement | Ralph Loop (user starts) |

## Links

- [claude-mem](https://github.com/thedotmack/claude-mem)
- [mcp-nixos](https://github.com/utensils/mcp-nixos)
- [context7](https://context7.com/docs)
- [superpowers](https://github.com/obra/superpowers)
- [ralph-wiggum](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum)
