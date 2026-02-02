
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- **Do not push or commit anything unless explicitly told to do so.**

---

Explain a topic, concept, or aspect of the codebase clearly and thoroughly.

## 1. Clarify Subject

If the subject is ambiguous, ask the user to clarify, with multiple-choice feature:
- [ ] General concept (e.g., "API endpoints" in general)
- [ ] Project-specific (e.g., this project's API endpoints)
- [ ] External reference (e.g., documentation link, library)

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

If a diagram would help understanding, call `/tt-mermaid` to create one:
- Architecture diagrams for system design
- Sequence diagrams for request flows
- Flowcharts for complex logic
- ER diagrams for data relationships

Ask the user if they'd like a diagram if it's not obvious.

## 5. Follow-up

Offer to:
- Dive deeper into specific aspects
- Create additional diagrams
- Explain related topics
