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

    # Mounted under `/tt:*` below.
    commands = { };

    settings = {
      # Model & reasoning
      model = "opus";
      alwaysThinkingEnabled = true;
      showThinkingSummaries = true;

      # Automation & efficiency
      autoCompactEnabled = true;
      autoMemoryEnabled = true;
      autoDreamEnabled = true;
      voiceEnabled = true;
      fileCheckpointingEnabled = true;
      todoFeatureEnabled = true;
      promptSuggestionEnabled = false;
      respectGitignore = true;
      includeGitInstructions = false; # already in CLAUDE.md

      # UI
      showTurnDuration = true;
      terminalTitleFromRename = true;
      spinnerTipsEnabled = false;

      # Privacy
      feedbackSurveyRate = 0;
      env = {
        # CLAUDE_CODE_EFFORT_LEVEL = "auto";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      };
      permissions = {
        defaultMode = "auto";
        inherit (permissions) allow deny;
        additionalDirectories = [ "/home/kari/Workspace" "/tmp" ];
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
      searxng = {
        command = "npx";
        args = [ "-y" "mcp-searxng" ];
        env = {
          SEARXNG_URL = "https://search.coditon.com";
          NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
        };
      };
      playwright = {
        command = "npx";
        args = [ "-y" "@playwright/mcp@latest" ];
      };
      houtini-lm = {
        command = "npx";
        args = [ "-y" "@houtini/lm" ];
        env = {
          HOUTINI_LM_ENDPOINT_URL = "http://localhost:11434";
          HOUTINI_LM_MODEL = "qwen3.5:9b";
        };
      };
    };

    # Global CLAUDE.md - applies to all projects
    memory.source = ./CLAUDE.md;

    # Claude plugins as Nix packages
    plugins = with pkgs.claude-plugins; [
      caveman
      ralph-wiggum
      superpowers
      document-skills
    ];
  };

  # MCP server dependencies + tools
  home.packages = with pkgs; [
    nodejs
    gh
  ];

  # Slash commands
  home.file.".claude/commands/tt".source = ./commands;
}
