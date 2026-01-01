{
  allow = [
    "Glob(*)"
    "Grep(*)"
    "LS(*)"
    "Read(*)"
    "Write(*)"
    "Edit(*)"
    "Search(*)"
    "Task(*)"
    "TodoWrite(*)"

    # Git
    "Bash(git status)"
    "Bash(git log:*)"
    "Bash(git diff:*)"
    "Bash(git show:*)"
    "Bash(git branch:*)"
    "Bash(git remote:*)"
    "Bash(git add:*)"
    "Bash(git rev-parse:*)"

    # Github CLI
    "Bash(gh run list:*)"

    # Nix
    "Bash(nix:*)"

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
    "Bash(dmesg:*)"

    # Systemd (read-only)
    "Bash(systemctl list-units:*)"
    "Bash(systemctl list-timers:*)"
    "Bash(systemctl status:*)"
    "Bash(journalctl:*)"

    # Network (trusted domains)
    "WebFetch(domain:github.com)"
    "WebFetch(domain:api.github.com)"
    "WebFetch(domain:raw.githubusercontent.com)"
    "WebSearch"

    # Skills
    "Skill(superpowers:*)"

    # MCP servers
    "mcp__claude-flow__*"
    "mcp__nixos__*"
    "mcp__context7__*"

    # Development tools
    "Bash(pre-commit run:*)"
    "Bash(make:*)"
    "Bash(just:*)"
    "Bash(node:*)"
    "Bash(npm:*)"
    "Bash(npx:*)"
    "Bash(cargo:*)"
    "Bash(python:*)"
    "Bash(uv:*)"

    # File operations (non-destructive)
    "Bash(cp:*)"
    "Bash(mv:*)"
  ];

  ask = [
    # Nix (can run arbitrary commands)
    "Bash(nix-shell:*)"

    # Git (destructive ops not in allow)
    "Bash(git:*)"
    "Bash(gh:*)"

    # File operations
    "Bash(chmod:*)"
    "Bash(chown:*)"
    "Bash(rm:*)"
    "Bash(ln:*)"
    "Bash(rsync:*)"
    "Bash(tar:*)"
    "Bash(zip:*)"
    "Bash(unzip:*)"

    # Systemd (control ops not in allow)
    "Bash(systemctl:*)"

    # Network
    "Bash(curl:*)"
    "Bash(wget:*)"

    # Process management
    "Bash(kill:*)"
    "Bash(killall:*)"
    "Bash(pkill:*)"

    # Privileged
    "Bash(sudo:*)"
  ];

  deny = [
    # Secrets
    "Read(**/.env)"
    "Read(**/.ssh/*)"
    "Read(**/.gnupg/*)"

    # Dangerous file operations
    "Bash(rm -rf:*)"
    "Bash(dd:*)"
    "Bash(mkfs:*)"

    # System-level operations
    "Bash(nixos-rebuild:*)"

    # Power control
    "Bash(reboot:*)"
    "Bash(shutdown:*)"
    "Bash(poweroff:*)"

    # Remote access
    "Bash(ssh:*)"
    "Bash(scp:*)"
    "Bash(sftp:*)"

    # Network tunneling
    "Bash(nc:*)"
    "Bash(netcat:*)"
  ];
}
