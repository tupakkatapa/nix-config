---
description: "Check or compose a message the user will send themselves (Slack, email, issue comment, release note): fact-check, keep their tone and language. Never sends."
argument-hint: "<draft text | what to say>"
---

You are preparing text that the user sends under their own name. **Never send, post or submit it.** The deliverable is the text, in a code block, ready to copy.

## 1. Understand
- A draft was given → the task is to check it, not to rewrite it.
- Only intent was given → compose it.
- A thread or link was given → read it first; answer what was actually asked.

## 2. Fact-check
Verify every concrete claim (what the code does, what shipped, versions, dates, names, numbers) against the source: code, issue tracker, PRs, logs. Apply the `evidence` lens (`~/.claude/tt/lenses/evidence.md`). Report each claim that is wrong or that could not be verified, before the text.

## 3. Edit
- Keep the author's words, tone, language and length. Fix only what is wrong: facts, grammar, an unclear sentence. Do not turn two lines into a structured document.
- Write for the reader named or implied: no engineering jargon for a non-engineer.
- Apply the `prose` lens (`~/.claude/tt/lenses/prose.md`): request or conclusion first, short sentences, no filler.
- When composing from scratch, match the user's own earlier messages in the thread or channel where they are visible.

## 4. Output
1. Fact-check result: one line per problem, or "facts check out".
2. The text in a code block.
3. What changed, in one line, when a draft was given.
