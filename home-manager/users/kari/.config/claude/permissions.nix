{
  allow = [
    # Core tools
    "Glob"
    "Grep"
    "LS(*)"
    "Read"
    "Write"
    "Edit"
    "Search(*)"
    "Task(*)"
    "TodoWrite(*)"

    # Git (both exact and with args)
    "Bash(git status)"
    "Bash(git status:*)"
    "Bash(git log)"
    "Bash(git log:*)"
    "Bash(git diff)"
    "Bash(git diff:*)"
    "Bash(git show)"
    "Bash(git show:*)"
    "Bash(git branch)"
    "Bash(git branch:*)"
    "Bash(git remote)"
    "Bash(git remote:*)"
    "Bash(git add:*)"
    "Bash(git commit:*)"
    "Bash(git rev-parse:*)"
    "Bash(git stash)"
    "Bash(git stash:*)"

    # GitHub CLI
    "Bash(gh run list:*)"
    "Bash(gh run view:*)"
    "Bash(gh run watch:*)"
    "Bash(gh pr view:*)"
    "Bash(gh pr list:*)"
    "Bash(gh pr checks:*)"
    "Bash(gh pr diff:*)"
    "Bash(gh pr status:*)"
    "Bash(gh pr create:*)"
    "Bash(gh issue view:*)"
    "Bash(gh issue list:*)"

    # Nix
    "Bash(nix:*)"

    # File system (read-only)
    "Bash(ls)"
    "Bash(ls:*)"
    "Bash(eza:*)"
    "Bash(find:*)"
    "Bash(cat:*)"
    "Bash(head:*)"
    "Bash(tail:*)"
    "Bash(pwd)"
    "Bash(stat:*)"
    "Bash(tree:*)"
    "Bash(wc:*)"
    "Bash(diff:*)"
    "Bash(lsblk:*)"

    # Shell utilities
    "Bash(which)"
    "Bash(which:*)"
    "Bash(echo:*)"
    "Bash(for:*)"
    "Bash(rg:*)"
    "Bash(grep:*)"
    "Bash(jq:*)"
    "Bash(timeout:*)"
    "Bash(test:*)"
    "Bash(sleep:*)"
    "Bash(date:*)"
    "Bash(tee:*)"
    "Bash(xargs:*)"
    "Bash(sort:*)"
    "Bash(uniq:*)"
    "Bash(cut:*)"
    "Bash(sed:*)"
    "Bash(awk:*)"
    "Bash(realpath:*)"
    "Bash(readlink:*)"
    "Bash(basename:*)"
    "Bash(dirname:*)"

    # System info (read-only)
    "Bash(dmesg:*)"
    "Bash(systemctl list-units:*)"
    "Bash(systemctl list-timers:*)"
    "Bash(systemctl status:*)"
    "Bash(journalctl:*)"

    # Web
    "WebFetch(domain:github.com)"
    "WebFetch(domain:api.github.com)"
    "WebFetch(domain:raw.githubusercontent.com)"
    "WebSearch"

    # Skills & MCP
    "Skill(*)"
    "mcp__plugin_claude-code-home-manager_nixos__*"
    "mcp__plugin_claude-code-home-manager_searxng__*"
    "mcp__plugin_claude-code-home-manager_playwright__*"

    # Vision (Wayland screenshots)
    "Bash(grim:*)"
    "Bash(slurp:*)"

    # Development
    "Bash(pre-commit run:*)"
    "Bash(make:*)"
    "Bash(just:*)"
    "Bash(node:*)"
    "Bash(cargo:*)"
    "Bash(python:*)"
    "Bash(uv:*)"

    # File operations
    "Bash(cp:*)"
    "Bash(mv:*)"
    "Bash(mkdir:*)"

    # herdr: spawn/drive worker agents in panes + worktrees
    "Bash(herdr:*)"
  ];

  # Prompt every time, in auto mode too
  ask = [
    "Bash(rm -r:*)"
    "Bash(rm -R:*)"
    "Bash(rm -f:*)"
    "Bash(rm --recursive:*)"
    "Bash(rm --force:*)"
    "Bash(rm -v:*)"
    "Bash(rm -d:*)"
    "Bash(git push:*)"
    "Bash(git reset --hard:*)"
    "Bash(git clean:*)"
    "Bash(gh pr merge:*)"
  ];

  deny = [
    # Secrets - always block
    "Read(**/.env)"
    "Read(**/.env.*)"
    "Read(**/.ssh/*)"
    "Read(**/.gnupg/*)"
    "Read(**/*secret*)"
    "Read(**/*credential*)"
    "Bash(cat *.env*)"

    "Bash(sudo rm:*)"
  ];
}
