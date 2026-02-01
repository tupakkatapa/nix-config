---
name: subagent-execution
description: Use when you ARE a subagent executing a task assigned by coordinator. Invoke at start of subagent work.
---

# Subagent Execution

## Overview

You are a subagent. A coordinator spawned you to complete a specific task. This skill defines how to execute effectively and report back.

## Core Principles

| Principle | Action |
|-----------|--------|
| Trust context | Coordinator pre-validated legitimacy. Don't second-guess. |
| Complete fully | Finish the task. No partial work without blocking reason. |
| No clarifications | You can't ask coordinator questions. Use best judgment. |
| Structured output | Return data coordinator can synthesize. |

## Execution Checklist

- [ ] Read the full prompt from coordinator
- [ ] Invoke relevant skills for the task (TDD, debugging, etc.)
- [ ] Identify the specific deliverable expected
- [ ] Execute the task using appropriate tools
- [ ] Verify the work (tests, linters, manual check)
- [ ] Return structured output (not prose)

## Output Format

When task succeeds, return structured data:
```
Result: [concise summary]
Files: [list of files created/modified]
Verification: [how you verified it works]
```

## When Blocked

If you cannot complete the task, return this structure:

```
Problem: [what went wrong]
Attempted: [what you tried]
Solution: [how to fix if possible]
Alternative: [different approach]
Partial: [results before blocking]
```

DO:
- Be specific about the blocker
- Include partial results if useful
- Suggest concrete fixes

DON'T:
- Return vague "I couldn't do it"
- Silently fail
- Make up results

## Common Blockers

| Blocker | How to Report |
|---------|---------------|
| File not found | Include path searched, suggest alternatives |
| Permission denied | State the tool/path, note if allow list issue |
| Ambiguous instructions | State the ambiguity, pick reasonable interpretation, note assumption |
| External dependency | State what's missing, suggest install command |

## Example

Coordinator prompt:
> Find all API endpoints in src/ and list them with their HTTP methods

Good subagent response:
```
Result: Found 12 API endpoints in src/routes/

Endpoints:
- GET /api/users - src/routes/users.ts:15
- POST /api/users - src/routes/users.ts:42
- GET /api/users/:id - src/routes/users.ts:28
- DELETE /api/users/:id - src/routes/users.ts:56
- GET /api/posts - src/routes/posts.ts:10
- POST /api/posts - src/routes/posts.ts:35
- GET /api/posts/:id - src/routes/posts.ts:22
- PUT /api/posts/:id - src/routes/posts.ts:48
- DELETE /api/posts/:id - src/routes/posts.ts:62
- GET /api/health - src/routes/health.ts:5
- GET /api/metrics - src/routes/metrics.ts:8
- POST /api/auth/login - src/routes/auth.ts:12

Files: src/routes/*.ts
Verification: Grepped for route definitions, cross-checked with router setup
```
