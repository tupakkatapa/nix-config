{ pkgs, ... }:
let
  git = "${pkgs.git}/bin/git";
  permissions = import ./permissions.nix;

  notify = message: "${pkgs.libnotify}/bin/notify-send -u normal 'Claude Code' '${message}' || true";
in
{
  # Cleanup orphaned Claude subagents and MCP servers which clog RAM
  imports = [ (import ./cleanup.nix { inherit pkgs; }) ];

  programs.claude-code = {
    enable = true;
    skills = ./skills;

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
        additionalDirectories = [ "/mnt/sftp/code/workspace" "/mnt/wd-red/sftp/code/workspace" "/tmp" ];
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
        args = [ "run" "github:utensils/mcp-nixos/6a517811658c21f97bd7703b35546085117fc310" "--" ];
      };
      context7 = {
        command = "npx";
        args = [ "-y" "@upstash/context7-mcp@4.4.4" ];
      };
      searxng = {
        command = "npx";
        args = [ "-y" "mcp-searxng@2.7.0" ];
        env = {
          SEARXNG_URL = "https://search.coditon.com";
          NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
        };
      };
      playwright = {
        command = "npx";
        args = [ "-y" "@playwright/mcp@0.0.83" ];
      };
      houtini-lm = {
        command = "npx";
        args = [ "-y" "@houtini/lm@3.3.4" ];
        env = {
          HOUTINI_LM_ENDPOINT_URL = "http://localhost:11434";
          HOUTINI_LM_MODEL = "qwen3.5:9b";
        };
      };
    };

    # Global CLAUDE.md - applies to all projects
    context = ./CLAUDE.md;

    # Claude plugins as Nix packages
    pluginPackages = with pkgs.claude-plugins; [
      caveman
      ponytail
      ralph-wiggum
      superpowers
      document-skills
    ];
  };

  # MCP server dependencies + tools
  home.packages = with pkgs; [
    nodejs
    grim
    slurp
    gh
    herdr
  ];

  # herdr agent multiplexer: gruvbox theme
  xdg.configFile."herdr/config.toml".text = ''
    [theme]
    name = "gruvbox"
  '';

  # Slash commands
  home.file.".claude/commands/tt".source = ./commands;
}
