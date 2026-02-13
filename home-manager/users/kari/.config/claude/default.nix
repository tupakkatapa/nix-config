{ pkgs, ... }:
let
  permissions = import ./permissions.nix;

  # ntfy notification helper
  notify = message: ''
    notify-send -u normal 'Claude Code' '${message}'; \
    systemctl --user is-active --quiet claude-afk && \
    curl -s -H 'Title: Claude Code' -H 'Priority: default' -H 'Tags: robot' -H 'Icon: https://www.anthropic.com/favicon.ico' -d '${message}' https://ntfy.coditon.com/claude || true
  '';
in
{
  # Claude Code AFK notification service
  systemd.user.services.claude-afk = {
    Unit.Description = "Claude Code AFK notification mode";
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
      ExecStartPost = "${pkgs.curl}/bin/curl -s -H 'Title: AFK Mode' -H 'Tags: robot' -H 'Icon: https://www.anthropic.com/favicon.ico' -d 'Notifications enabled' https://ntfy.coditon.com/claude";
    };
  };

  # Cleanup orphaned Claude subagents which clogs RAM
  systemd.user.services.claude-cleanup = {
    Unit.Description = "Kill orphaned Claude Code subagents";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "claude-cleanup" ''
        ${pkgs.procps}/bin/ps -eo pid,ppid,args | \
          ${pkgs.gnugrep}/bin/grep 'claude-wrapped_.*stream-json' | \
          ${pkgs.gawk}/bin/awk '$2 == 1 {print $1}' | \
          ${pkgs.findutils}/bin/xargs -r ${pkgs.util-linux}/bin/kill -9 || true
      ''}";
    };
  };
  systemd.user.timers.claude-cleanup = {
    Unit.Description = "Periodic cleanup of orphaned Claude subagents";
    Timer = {
      OnBootSec = "15m";
      OnUnitActiveSec = "15m";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  programs.claude-code = {
    enable = true;
    skillsDir = ./skills;

    # Custom slash commands (auto-discovered from ./commands/)
    commands =
      let
        commandDir = ./commands;
        commandFiles = builtins.attrNames (builtins.readDir commandDir);
        mkCommand = filename: {
          name = builtins.replaceStrings [ ".md" ] [ "" ] filename;
          value = builtins.readFile "${commandDir}/${filename}";
        };
      in
      builtins.listToAttrs (map mkCommand commandFiles);

    settings = {
      alwaysThinkingEnabled = true;
      permissions = {
        inherit (permissions) allow deny;
        additionalDirectories = [ "/home/kari/Workspace" "/home/kari/nix-config" "/tmp" ];
      };
      hooks = {
        SessionStart = [{
          hooks = [{
            type = "command";
            command = ''
              echo "Read ~/.claude/CLAUDE.md (global) and ./CLAUDE.md (project) if not already.
              echo "Use configured skills and MCP tools extensively. Check memory, use subagents for parallel work."
            '';
          }];
        }];
        Stop = [{
          hooks = [{
            type = "command";
            command = notify "Stopped - needs attention";
          }];
        }];
        PreToolUse = [{
          matcher = "AskUserQuestion";
          hooks = [{
            type = "command";
            command = notify "Question - needs input";
          }];
        }];
      };
    };

    # MCP servers
    mcpServers = {
      nixos = {
        command = "nix";
        args = [ "run" "github:utensils/mcp-nixos" "--" ];
      };
      context7 = {
        command = "npx";
        args = [ "-y" "@upstash/context7-mcp" ];
      };
      sequential-thinking = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
      };
      filesystem = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-filesystem" "/home/kari/Workspace" "/home/kari/nix-config" ];
      };
    };

    # Global CLAUDE.md - applies to all projects
    memory.source = ./CLAUDE.md;

    # Claude plugins as Nix packages
    plugins = with pkgs.claude-plugins; [
      ralph-wiggum
      claude-mem
      superpowers
      document-skills
      example-skills
    ];
  };

  # MCP server dependencies
  home.packages = with pkgs; [ nodejs ];
}
