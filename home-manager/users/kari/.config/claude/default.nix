{ pkgs, ... }:
let
  git = "${pkgs.git}/bin/git";
  permissions = import ./permissions.nix;

  # Starts an npm-published MCP server from a per-version cache. The install lands in a
  # temporary directory and is renamed into place, so an interrupted or concurrent first
  # start cannot leave a half-installed server behind.
  mcpNpm = pkgs.writeShellScript "mcp-npm" ''
    set -euo pipefail
    export PATH=${pkgs.lib.makeBinPath [ pkgs.nodejs pkgs.coreutils ]}:$PATH
    pkg=$1 ver=$2
    shift 2
    dir="''${XDG_CACHE_HOME:-$HOME/.cache}/claude-mcp/$pkg@$ver"
    if [ ! -e "$dir/.ok" ]; then
      mkdir -p "$(dirname "$dir")"
      tmp=$(mktemp -d "$dir.XXXXXX")
      npm install --silent --no-audit --no-fund --prefix "$tmp" "$pkg@$ver" >&2
      touch "$tmp/.ok"
      mv -T "$tmp" "$dir" 2>/dev/null || rm -r "$tmp"
    fi
    root="$dir/node_modules/$pkg"
    bin=$(node -p 'const b=require(process.argv[1]+"/package.json").bin; typeof b==="string"?b:Object.values(b)[0]' "$root")
    exec node "$root/$bin" "$@"
  '';

  # Inside herdr the popup would land on the server's display; the herdr Matrix bot reaches the owner instead
  notify = message: ''
    [ -n "''${HERDR_ENV:-}" ] || ${pkgs.libnotify}/bin/notify-send -u normal 'Claude Code' '${message}' 2>/dev/null || true
  '';
in
{
  imports = [
    # Cleanup orphaned Claude subagents and MCP servers which clog RAM
    (import ./cleanup.nix { inherit pkgs; })
    ./herdr.nix
  ];

  programs.claude-code = {
    enable = true;
    skills = ./skills;
    agentsDir = ./agents;

    # Mounted under `/tt:*` below.
    commands = { };

    # Defaults that /model and /effort may change; the change survives a rebuild
    mutableSettings = {
      model = "fable";
      effortLevel = "medium";
    };

    settings = {
      # Reasoning
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
        inherit (permissions) allow ask deny;
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
            timeout = 12;
            command = notify "Stopped - needs attention";
          }];
        }];
        PreToolUse = [{
          matcher = "AskUserQuestion";
          hooks = [{
            type = "command";
            timeout = 12;
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
      searxng = {
        command = "${mcpNpm}";
        args = [ "mcp-searxng" "2.7.0" ];
        env = {
          SEARXNG_URL = "https://search.coditon.com";
          NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
        };
      };
      playwright = {
        command = "${mcpNpm}";
        args = [ "@playwright/mcp" "0.0.83" ];
      };
    };

    # Global CLAUDE.md - applies to all projects
    context = ./CLAUDE.md;

    # Claude plugins as Nix packages
    pluginPackages = with pkgs.claude-plugins; [
      caveman
      ponytail
    ];
  };

  # MCP server dependencies + tools
  home.packages = with pkgs; [
    nodejs
    grim
    slurp
    gh
  ];

  # Slash commands, and the lenses and language contexts they read
  home.file.".claude/commands/tt".source = ./commands;
  home.file.".claude/tt".source = ./reference;
}
