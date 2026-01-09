---
model: claude-sonnet-4-0
---

Craft a Ralph Wiggum iterative loop prompt for: $ARGUMENTS

## Understanding Ralph Loops

Ralph loops enable iterative refinement through a feedback mechanism:
1. A prompt is repeatedly fed to the AI
2. Each iteration sees previous work via files and git history
3. Loop continues until completion criteria are met
4. Safety limit prevents infinite loops

## Prompt Construction

Based on the user's request, create a structured Ralph loop with:

### 1. Task Definition
- Clear, specific goal statement
- Break into verifiable phases
- Define what "done" looks like

### 2. Completion Promise
- Exact string that signals completion
- Only output when genuinely complete
- Example: "TASK_COMPLETE: All tests passing"

### 3. Iteration Strategy
- What to do in each iteration
- How to build on previous work
- Self-correction mechanisms

### 4. Safety Limits
- Appropriate max-iterations (default: 25)
- Higher for complex tasks (up to 50)
- Lower for simpler tasks (10-15)

## Output Format

Generate a ready-to-use command:

```
/ralph-loop "
[Task description with phases]

Phase 1: [First milestone]
Phase 2: [Second milestone]
...

Completion Criteria:
- [Specific, verifiable criteria]
- [Tests, checks, or validations]

After completing ALL criteria, output exactly: [COMPLETION_PROMISE]
" --completion-promise "[COMPLETION_PROMISE]" --max-iterations [N]
```

## Best Practices Applied

- Include test-driven elements when appropriate
- Add verification steps between phases
- Make completion criteria objectively measurable
- Use clear phase boundaries for progress tracking
