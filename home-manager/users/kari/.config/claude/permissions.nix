{
  allow = [
    # Core tools
    "Glob(*)"
    "Grep(*)"
    "LS(*)"
    "Read(*)"
    "Write(*)"
    "Edit(*)"
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
    "Bash(git rev-parse:*)"
    "Bash(git stash)"
    "Bash(git stash:*)"

    # GitHub CLI
    "Bash(gh run list:*)"
    "Bash(gh pr:*)"
    "Bash(gh issue:*)"

    # Nix (non-destructive only)
    "Bash(nix search:*)"
    "Bash(nix eval:*)"
    "Bash(nix flake show:*)"
    "Bash(nix flake metadata:*)"
    "Bash(nix flake info:*)"
    "Bash(nix path-info:*)"
    "Bash(nix derivation show:*)"
    "Bash(nix show-derivation:*)"
    "Bash(nix log:*)"
    "Bash(nix why-depends:*)"
    "Bash(nix hash:*)"
    "Bash(nix repl:*)"

    # File system (read-only)
    "Bash(ls:*)"
    "Bash(eza:*)"
    "Bash(find:*)"
    "Bash(cat:*)"
    "Bash(head:*)"
    "Bash(tail:*)"
    "Bash(mkdir:*)"
    "Bash(pwd)"
    "Bash(stat:*)"
    "Bash(tree:*)"
    "Bash(wc:*)"
    "Bash(diff:*)"
    "Bash(lsblk:*)"

    # Shell utilities
    "Bash(which:*)"
    "Bash(echo:*)"
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
    "Skill(superpowers:*)"
    "mcp__nixos__*"
    "mcp__context7__*"
    "mcp__paper-search__*"

    # Development
    "Bash(pre-commit run:*)"
    "Bash(make:*)"
    "Bash(just:*)"
    "Bash(node:*)"
    "Bash(npm:*)"
    "Bash(npx:*)"
    "Bash(cargo:*)"
    "Bash(python:*)"
    "Bash(uv:*)"

    # File operations
    "Bash(cp:*)"
    "Bash(mv:*)"
  ];

  deny = [
    # Secrets - always block
    "Read(**/.env)"
    "Read(**/.ssh/*)"
    "Read(**/.gnupg/*)"
    "Read(**/*secret*)"
    "Read(**/*credential*)"
  ];
}
