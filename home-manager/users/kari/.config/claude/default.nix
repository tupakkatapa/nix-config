{ pkgs, ... }:
let
  git = "${pkgs.git}/bin/git";
  permissions = import ./permissions.nix;

  # ntfy notification helper
  notify = message: ''
    notify-send -u normal 'Claude Code' '${message}'; \
    systemctl --user is-active --quiet claude-afk && \
    curl -s -H 'Title: Claude Code' -H 'Priority: default' -H 'Tags: robot' -H 'Icon: https://www.anthropic.com/favicon.ico' -d '${message}' https://ntfy.coditon.com/claude || true
  '';

  # Claude-mem settings
  # https://github.com/thedotmack/claude-mem/blob/main/src/shared/SettingsDefaultsManager.ts
  claudeMemSettings = {
    CLAUDE_MEM_CONTEXT_FULL_COUNT = "3"; # default: 0
    CLAUDE_MEM_CONTEXT_SHOW_SAVINGS_PERCENT = "false"; # default: true
  };
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

  # Cleanup orphaned Claude subagents and MCP servers which clog RAM
  imports = [ (import ./cleanup.nix { inherit pkgs; }) ];

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
              ${git} status --short 2>/dev/null && echo "---" && ${git} log --oneline -3 2>/dev/null || true
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
    };

    # Global CLAUDE.md - applies to all projects
    memory.source = ./CLAUDE.md;

    # Claude plugins as Nix packages
    plugins = with pkgs.claude-plugins; [
      ralph-wiggum
      claude-mem
      superpowers
      document-skills
    ];
  };

  # MCP server dependencies
  home.packages = with pkgs; [ nodejs ];

  # Declarative claude-mem settings
  home.file.".claude-mem/settings.json".text = builtins.toJSON claudeMemSettings;
}
