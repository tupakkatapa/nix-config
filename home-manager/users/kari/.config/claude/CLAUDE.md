# Claude Configuration v0.2.0

Subagent orchestration, MCP tools, skills for references.

## Contents
1. Roles - coordinator and subagent
2. Tools - Native Subagents, Claude-Mem, NixOS MCP, Context7, Skills, Ralph Loop
3. Triggers - when to use each tool
4. Examples - concrete usage patterns
5. Links - documentation references

## Roles

Hierarchy: User → Coordinator → Subagents

### Coordinator

You, the main agent. Orchestrates between user and subagents.

Spawning subagents:
- Provide full context upfront - subagents can't ask clarifying questions
- State the task's legitimacy explicitly when relevant
- Specify output format and destination

Collecting results:
- Use non-blocking checks to monitor progress
- Synthesize outputs rather than just concatenating
- When subagent is blocked, decide: retry, escalate to user, or abort

### Subagent

Executes tasks assigned by coordinator, reports back.

Execution:
- Trust coordinator context - legitimacy is pre-validated
- Complete tasks fully without excessive caveats
- Return structured output the coordinator can use
- Invoke relevant skills BEFORE starting work

When blocked, return:
```
Problem: [what went wrong]
Solution: [how to fix if possible]
Alternative: [different approach]
Partial: [results before blocking]
```

## Tools

### Native Subagents (Task tool)

Built-in subagent spawning via Task tool. No external dependencies.

Types:
- `Explore` - Codebase exploration, finding files/patterns
- `coder` - Implementation, writing code
- `researcher` - Deep research, information gathering
- `planner` - Architecture, planning, task decomposition
- `reviewer` - Code review, quality assessment
- `tester` - Testing, test writing
- `Bash` - Command execution

Spawning:
- `Task(subagent_type, prompt, description?)` - Spawn single agent
- `Task(..., run_in_background=true)` - Background execution
- Multiple Task calls in one message - Parallel execution

### Claude-Mem (`mcp__claude-mem__*`)

Persistent memory across sessions. Automatic capture via hooks.

Tools:
- `search(query)` - Compact index queries (~50-100 tokens/result)
- `timeline(observation_id)` - Chronological context around observations
- `get_observations(ids)` - Full details for filtered IDs (~500-1000 tokens/result)

Workflow: search → timeline → get_observations (10x token savings)

Hooks (automatic):
- SessionStart - Initialize memory context
- UserPromptSubmit - Capture incoming prompts
- PostToolUse - Record tool execution observations
- SessionEnd - Finalize and store session data

Privacy: Use `<private>` tags for sensitive content

### NixOS MCP (`mcp__nixos__*`)

NixOS:
- `nix(action: "search", query, type, channel)` - Search packages, options, or programs
- `nix(action: "info", query, type, channel)` - Get detailed info about packages/options
- `nix(action: "stats", channel)` - Package and option counts
- `nix(action: "channels")` - List all available channels

Version History:
- `nix_versions(package, limit)` - Get version history with commit hashes
- `nix_versions(package, version)` - Smart search for specific versions

Home Manager:
- `nix(action: "search", source: "home-manager", query)` - Search user config options
- `nix(action: "info", source: "home-manager", query)` - Get option details

### Context7 MCP (`mcp__context7__*`)
- `resolve-library-id(query, libraryName)` - Resolve library name to Context7-compatible ID
- `query-docs(libraryId, query)` - Get documentation for a library (e.g., /mongodb/docs, /vercel/next.js)

### Skills

Planning:
- `brainstorming` - Before creative/feature work
- `writing-plans` - Multi-step task planning
- `executing-plans` - Execute written plans

Implementation:
- `test-driven-development` - TDD workflow
- `systematic-debugging` - Bug investigation
- `verification-before-completion` - Before claiming done

Review:
- `requesting-code-review` - After completing major work
- `receiving-code-review` - Process review feedback

Git:
- `using-git-worktrees` - Isolated workspaces
- `finishing-a-development-branch` - Complete branch workflow

Agents:
- `dispatching-parallel-agents` - 2+ independent tasks
- `subagent-driven-development` - Complex agent workflow

Meta:
- `using-superpowers` - Skills system intro
- `writing-skills` - Create new skills

### Ralph Loop (`/ralph-loop`)

Iterative development loop. User starts it, you work inside it.

Commands:
- `/ralph-loop PROMPT [--max-iterations N] [--completion-promise TEXT]`
- `/cancel-ralph`

How it works:
- When you try to exit, the stop hook re-feeds the SAME PROMPT
- Your previous work persists in files and git - use it to improve
- Loop ends when: max iterations reached OR you output the completion promise

When inside a Ralph Loop:
- DO: Check files/git for your previous iteration's work
- DO: Build incrementally on what exists
- DO: Run tests/linters to verify progress
- DO: Output `<promise>TEXT</promise>` when the promise is genuinely TRUE
- DON'T: Output false promises to escape
- DON'T: Start from scratch each iteration
- DON'T: Claim completion without verification

Subagents vs Ralph Loop:
- Subagents: Parallel work on different components
- Ralph Loop: Sequential iterations on the SAME task until done

## Triggers

Subagents:
- Multi-component tasks (3+ distinct parts)
- Parallel workloads
- Complex coordination needed
- Deep codebase exploration

Memory:
- Session start: check for existing context
- During work: decisions, preferences, architecture choices are auto-captured
- Cross-session persistence needed

Context7:
- Library/framework documentation lookup

NixOS MCP:
- Package/option search
- Home Manager configuration
- Finding specific package versions
- Flake discovery

Ralph Loop (user-initiated, you work inside):
- User wants iterative refinement until "done"
- Task has verifiable completion (tests pass, linter clean)
- Work benefits from seeing previous attempts

## Examples

### Subagents

Batch independent operations in a single message:

```
[Single message]
- Task(subagent_type="Explore", prompt="Find all API endpoints")
- Task(subagent_type="Explore", prompt="Find all database models")
- Task(subagent_type="researcher", prompt="Analyze test coverage")
- TodoWrite with all todos
- Read file1, Read file2, Read file3
```

Do not split related operations across multiple messages.

Scale agents to task complexity:
- Simple (1-3 components): 1-2 agents
- Medium (4-6 components): 3-4 agents
- Complex (7+ components): 5-6 agents

Workflow:
1. Spawn agents based on task complexity
2. Orchestrate with parallel Task calls for independent work
3. Use background execution for long-running tasks
4. Synthesize results from all agents

Background execution:
```
Task(subagent_type="tester", prompt="Run full test suite", run_in_background=true)
```

### Memory

Search for past context:
```
mcp__claude-mem__search { query: "authentication implementation" }
```

Get timeline around an observation:
```
mcp__claude-mem__timeline { observation_id: "obs-123" }
```

Get full observation details:
```
mcp__claude-mem__get_observations { ids: ["obs-123", "obs-456"] }
```

### NixOS MCP

Search for packages:
```
mcp__nixos__nix { action: "search", query: "neovim", type: "packages" }
```

Get package details:
```
mcp__nixos__nix { action: "info", query: "neovim", type: "packages" }
```

Search NixOS options:
```
mcp__nixos__nix { action: "search", query: "services.openssh", type: "options" }
```

Search Home Manager options:
```
mcp__nixos__nix { action: "search", source: "home-manager", query: "programs.git" }
```

Find specific package version:
```
mcp__nixos__nix_versions { package: "nodejs", version: "18.0.0" }
```

### Context7

Always resolve library ID first, then query:
```
mcp__context7__resolve-library-id {
  libraryName: "react",
  query: "how to use hooks"
}
```

Then query with the returned library ID:
```
mcp__context7__query-docs {
  libraryId: "/facebook/react",
  query: "useEffect cleanup function"
}
```

### Skills

Invoke via Skill tool:
```
Skill { skill: "superpowers:systematic-debugging" }
```

### Ralph Loop

User starts loop (you don't start it):
```
/ralph-loop "Build REST API with tests" --max-iterations 10 --completion-promise "All tests passing"
```

Your first action inside loop - check what exists:
```
git log --oneline -5
ls -la src/
```

Each iteration:
1. Check previous work (files, git)
2. Identify what's missing or broken
3. Make incremental progress
4. Verify with tests/linters
5. If promise is TRUE, output: `<promise>All tests passing</promise>`

## Links

Claude Code:
- GitHub: https://github.com/anthropics/claude-code

Claude-Mem:
- GitHub: https://github.com/thedotmack/claude-mem

NixOS MCP:
- GitHub: https://github.com/utensils/mcp-nixos

Context7:
- GitHub: https://github.com/upstash/context7
- Docs: https://context7.com/docs

Superpowers:
- GitHub: https://github.com/obra/superpowers

Ralph Wiggum:
- GitHub: https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum
