
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.

---

Create a diagram and display it for the user. Mermaid is the current backend; the action is intent-named so swapping backends later (Graphviz, PlantUML, etc.) does not require renaming.

## 1. Determine Subject

If not specified, use `AskUserQuestion` to clarify between:
- Project architecture
- Specific component or flow
- Data relationships
- Sequence of operations
- State machine
- Any concept that benefits from visualization

## 2. Create Diagram

Choose the appropriate Mermaid diagram type:
- `flowchart` - Process flows, decision trees
- `sequenceDiagram` - API calls, message passing
- `classDiagram` - Object relationships, inheritance
- `erDiagram` - Database schemas, entity relationships
- `stateDiagram-v2` - State machines, lifecycles
- `gitgraph` - Branch workflows
- `mindmap` - Concept organization
- `timeline` - Historical/sequential events

## 3. Save and Display

Save the diagram to `/tmp/diagram.mmd` using the Write tool.

Generate and open the diagram:
```bash
mmdc -i /tmp/diagram.mmd -o /tmp/diagram.svg && xdg-open /tmp/diagram.svg
```

If `mmdc` (mermaid-cli) is not available:
```bash
nix-shell -p mermaid-cli --run "mmdc -i /tmp/diagram.mmd -o /tmp/diagram.svg" && xdg-open /tmp/diagram.svg
```

## 4. Iterate

Ask if the user wants to:
- Adjust the diagram
- Add more detail
- Create additional diagrams
- Export in different format (png, pdf)
