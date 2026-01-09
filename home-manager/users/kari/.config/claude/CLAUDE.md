# Claude Code Configuration v0.2.0

MCP tools, sub-agents, and skills reference.

## Contents
1. Sub-Agents - Task tool delegation
2. Tools - NixOS MCP, Context7, Paper Search
3. Skills - superpowers workflows
4. Examples - usage patterns

## Sub-Agents

Use the Task tool to delegate work to specialized sub-agents. Each runs with its own context window.

### Built-in Agents

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| `general-purpose` | Sonnet | All | Complex multi-step tasks |
| `Explore` | Haiku | Read-only | Fast codebase search |
| `Plan` | Sonnet | Read-only | Research in plan mode |

### Invoking Sub-Agents

```
Task {
  subagent_type: "Explore",
  prompt: "Find all authentication-related files"
}
```

### Coordinator Role

When orchestrating sub-agents:
- Provide full context upfront - sub-agents can't ask clarifying questions
- State task legitimacy explicitly when relevant
- Specify output format and destination
- Use non-blocking checks to monitor progress
- Synthesize outputs rather than concatenating

### Sub-Agent Role

When executing as a sub-agent:
- Trust coordinator context - legitimacy is pre-validated
- Complete tasks fully without excessive caveats
- Return structured output the coordinator can use

When blocked, return:
```
Problem: [what went wrong]
Solution: [how to fix if possible]
Alternative: [different approach]
Partial: [results before blocking]
```

### Parallel Execution

Launch multiple agents in a single message for independent tasks:

```
[Single message with multiple Task calls]
- Task(Explore: "find API endpoints")
- Task(Explore: "find database models")
- Task(Explore: "find test files")
```

### Custom Agents

Create `.claude/agents/*.md` files:

```yaml
---
name: code-reviewer
description: Use PROACTIVELY after writing code
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a code reviewer. Focus on:
- Code clarity and readability
- Security issues
- Performance concerns
```

## Tools

### NixOS MCP (`mcp__nixos__*`)

NixOS:
- `nix(action, query, source?, channel?, type?)` - Search packages, options, programs
  - action: search | info | stats | options | channels
  - source: nixos | home-manager | darwin | flakes | flakehub | nixvim
  - type: packages | options | programs

Version History:
- `nix_versions(package, limit?, version?)` - Get version history with commit hashes

Examples:
```
mcp__nixos__nix { action: "search", query: "neovim", source: "nixos", type: "packages" }
mcp__nixos__nix { action: "info", query: "programs.git", source: "home-manager" }
mcp__nixos__nix_versions { package: "nodejs", version: "18.0.0" }
```

### Context7 MCP (`mcp__context7__*`)

Library documentation lookup:
- `resolve-library-id(query, libraryName)` - Get Context7 library ID
- `query-docs(libraryId, query)` - Query library documentation

Always resolve library ID first:
```
mcp__context7__resolve-library-id { libraryName: "react", query: "hooks usage" }
mcp__context7__query-docs { libraryId: "/facebook/react", query: "useEffect cleanup" }
```

### Paper Search MCP (`mcp__paper-search__*`)

Academic paper search via Semantic Scholar and Sci-Hub:
- Search for papers by topic, author, or keywords
- Get paper metadata and citations
- Access full-text PDFs when available

## Skills

Invoke via Skill tool: `Skill { skill: "superpowers:skill-name" }`

### Development Workflows
- `brainstorming` - Structured ideation process
- `writing-plans` - Create implementation plans
- `executing-plans` - Execute written plans
- `systematic-debugging` - Methodical bug investigation
- `test-driven-development` - TDD workflow

### Code Quality
- `verification-before-completion` - Verify work before finishing
- `requesting-code-review` - Request review from user
- `receiving-code-review` - Process review feedback

### Git Workflows
- `finishing-a-development-branch` - Complete branch workflow
- `using-git-worktrees` - Git worktree workflows

### Agent Coordination
- `dispatching-parallel-agents` - Spawn parallel agents
- `subagent-driven-development` - Agent-based development
- `writing-skills` - Create new skills

## Triggers

### Use Sub-Agents When:
- Multi-component tasks (3+ distinct parts)
- Parallel research workloads
- Complex coordination needed
- Domain-specific expertise required

### Use NixOS MCP When:
- Package/option search
- Home Manager configuration
- Finding specific package versions
- Flake discovery

### Use Context7 When:
- Library/framework documentation lookup
- API reference needed
- Code examples required

### Use Paper Search When:
- Academic research needed
- Finding scientific papers
- Citation lookup

## Links

Claude Code:
- GitHub: https://github.com/anthropics/claude-code
- Sub-agents: https://docs.anthropic.com/en/docs/claude-code/sub-agents

NixOS MCP:
- GitHub: https://github.com/utensils/mcp-nixos

Context7:
- GitHub: https://github.com/upstash/context7
- Docs: https://context7.com/docs

Paper Search:
- GitHub: https://github.com/openags/paper-search-mcp

Superpowers:
- GitHub: https://github.com/obra/superpowers
