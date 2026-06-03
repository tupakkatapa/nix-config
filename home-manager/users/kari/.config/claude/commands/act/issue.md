
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- Requires the Linear MCP (`mcp__claude_ai_Linear__*`). If it is unavailable, stop and tell the user to connect it.
- **A Linear issue must fit in one cycle.** If the work spans multiple cycles it is a Project; multiple quarters, an Initiative. Surface that — do not file an oversized issue.

---

You are creating a Linear issue from a request, applying the conventions below. The request may be a sentence, a code reference, a bug, or a plan. Distil it into one well-scoped issue with priority, estimate, and a brief, fact-checked description.

## 1. Understand the Request

- **Investigate and understand what is actually being asked before filing anything.** Treat the user's request as a lead, not a spec — read the relevant files, modules, hosts, and behaviour it touches and extend your understanding against the codebase. The issue must reflect what is really there, not the request's assumptions. Note any discrepancy back to the user before proceeding.
- Resolve the **team**: `list_teams`. If one team, use it. If several, pick from request context or ask.

## 2. Classify the Hierarchy

Decide what the request actually is before filing:

| Level | Scope | Action |
|---|---|---|
| **Initiative** | 1–N quarters | Too large for an issue. Tell the user; offer to create an Initiative instead. |
| **Project** | 1–N cycles | Too large for an issue. Tell the user; offer to create a Project, or split into cycle-sized issues. |
| **Issue** | Fits in one cycle | Proceed. |

If the work cannot fit one cycle, **stop and escalate** rather than filing it.

## 3. Set Priority

Map intent to Linear priority (the `priority` number):

| Word | `priority` | Meaning |
|---|---|---|
| Urgent | `1` | Hotfix — straight to staging/prod |
| High | `2` | Should be committed to dev this cycle |
| Medium | `3` | Pick up when no High items, or at discretion |
| Low | `4` | Do when convenient |

Pick deliberately. If the request gives no signal, default to **Medium (`3`)** and say so.

## 4. Set Estimate

Estimate against this scale (the `estimate` number):

| `estimate` | Size | Meaning |
|---|---|---|
| `1` | Trivial | Hours |
| `2` | Small | ~half day |
| `4` | Medium | ~1–2 days |
| `8` | Large | Multi-day — consider splitting |
| `16` | Too big | **Split into smaller issues.** Estimate priority and estimate of each split with care, and set them. |

For `8`, recommend a split. For `16`, **do not file as one issue** — propose the split, then file the pieces (each with its own priority + estimate, chosen carefully).

## 5. Write the Title

**Very short, but descriptive enough that a human can tell what it is about at a glance.** Discipline:

- A few words — fits in a list without wrapping. No ticket-speak, no trailing period.
- Lead with the area/component when it disambiguates (e.g. `torgue: persist radicle key`, `linear cmd: add title guidance`).
- Imperative or noun phrase. Says *what changes*, not how.
- A reader skimming the cycle board must grasp the subject from the title alone — the description fills in detail.

## 6. Write the Description

The description is for **lazy human reading**. Discipline:

- **Brief and very easily digestible.** Fragments and bullets over prose. No preamble, no restating the title.
- **Fact-checked against the codebase** (step 1) — every concrete claim (file path, symbol, current behaviour) must be verified, not assumed.
- Lead with the *what* and *why*, then the *where* (`file_path:line`), then acceptance check if non-obvious.
- Skip anything a reader can infer. If it adds no signal, cut it.

Keep it short enough that a reader skims it in seconds and knows what to do.

## 7. Place & Relate

- **Project.** `list_projects` (scoped to the team). If the issue advances an existing project's deliverable, attach it. If it belongs to a coherent, cycle-spanning body of work with no project yet, propose a new one (`save_project`) — **confirm with the user before creating**.
- **Labels.** `list_issue_labels` (team + workspace scope). Apply the existing labels that fit. Only create a new label (`create_issue_label`) when no existing one captures a recurring category, never a one-off — **confirm with the user before creating**.
- **Relations.** Search existing issues (`list_issues`) for ones this **relates to**, **blocks**, **is blocked by**, or **duplicates**. If it duplicates an open issue, **stop and surface that** instead of filing a dup.

## 8. File the Issue

Call `save_issue` with: `team`, `title`, `description` (Markdown, literal newlines — no escape sequences), `priority`, `estimate`, and `project`/`labels`/`cycle`/`assignee`/`relatedTo`/`blocks`/`blockedBy`/`duplicateOf` only when justified (§7). Do **not** pass `id` (that is for updates).

Report the created issue identifier and URL. If you escalated to Project/Initiative, created a project or label, or split a `16`, list every artefact created.
