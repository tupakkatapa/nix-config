---
description: "Review how this Claude setup is actually used: mine recent session history for retyped prompts, unused commands and friction, then propose edits to commands, lenses and CLAUDE.md."
argument-hint: "[days, default 30]"
---

You are reviewing the working setup against real use and proposing changes to it. Read-only until the user accepts a proposal.

## 1. Gather
Dispatch one subagent to mine `~/.claude/projects/*/*.jsonl` (main-thread sessions in the period; stream with `jq` or a script, never read transcripts whole). It returns numbers, not transcripts:
- Invocations per command and per skill; commands with zero use.
- Chains: commands named together or back to back.
- Free-text prompts typed again and again, clustered, with counts and two verbatim examples each.
- Friction after a command: interrupts and corrections, quoted.
- Standing rules the user had to repeat.

## 2. Judge
- A prompt typed about 30 times or more in the period → a command, or one line in an existing command.
- A rule the user repeats although `CLAUDE.md` states it → find what competes with it or why it is not applied; do not just restate it louder.
- A command with zero use over two periods → delete it, or fix its description if the need exists but the command never fires.
- Friction after a command → the step in that command that caused it.

## 3. Propose
A short list, most valuable first: the evidence (count, quote), the change, the file. Mark every removal or rename of a command as breaking. Then stop; the user picks.
