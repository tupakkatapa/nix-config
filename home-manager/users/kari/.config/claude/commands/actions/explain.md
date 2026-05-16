
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

Explain a topic, concept, or aspect of the codebase clearly and thoroughly.

## 1. Clarify Subject

If the subject is ambiguous, use `AskUserQuestion` to clarify between:
- General concept (e.g., "API endpoints" in general)
- Project-specific (e.g., this project's API endpoints)
- External reference (e.g., documentation link, library)

Examples of ambiguous requests:
- "Explain authentication" → General auth concepts or this project's auth?
- "Explain the database" → Schema design, queries, or connection handling?

## 2. Research

For project-specific topics:
- Explore relevant files and code
- Trace data flow and dependencies
- Identify key patterns and design decisions

For general concepts:
- Use Context7 MCP for library documentation if applicable
- Provide clear, practical explanations

## 3. Explain

Provide a clear, structured explanation:
- Start with a high-level overview
- Break down into components/steps as needed
- Include relevant code snippets with file references
- Highlight important gotchas or edge cases

## 4. Visualize

If a diagram would help understanding, suggest `/tt:actions:diagram` at the end of the explanation. That action owns the rendering pipeline (Mermaid backend, `/tmp/diagram.{mmd,svg}`, `xdg-open`); duplicating it here would let the two drift.

Examples of where a diagram earns its keep:
- Architecture diagrams for system design.
- Sequence diagrams for request flows.
- Flowcharts for complex logic.
- ER diagrams for data relationships.

