{ pkgs, ... }:
let
  git = "${pkgs.git}/bin/git";
  permissions = import ./permissions.nix;

  curl = "${pkgs.curl}/bin/curl -s -m 5";

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

  # Phone push while the latest message on the claude-afk topic is "on" (toggled from maliwan's waybar)
  notify = message: ''
    ${pkgs.libnotify}/bin/notify-send -u normal 'Claude Code' '${message}' 2>/dev/null || true
    ${curl} 'https://ntfy.coditon.com/claude-afk/json?poll=1&since=latest' | grep -q '"message":"on"' && ${curl} -H "Title: Claude Code: ''${PWD##*/}" -H 'Tags: robot' -H 'Icon: https://www.anthropic.com/favicon.ico' -d '${message}' https://ntfy.coditon.com/claude >/dev/null || true
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

    # Mounted under `/tt:*` below.
    commands = { };

    # Defaults that /model and /effort may change; the change survives a rebuild
    mutableSettings = {
      model = "opus[1m]";
      effortLevel = "xhigh";
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
      context7 = {
        command = "${mcpNpm}";
        args = [ "@upstash/context7-mcp" "4.4.4" ];
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
      houtini-lm = {
        command = "${mcpNpm}";
        args = [ "@houtini/lm" "3.3.4" ];
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
  ];

  # Slash commands, and the lenses and language contexts they read
  home.file.".claude/commands/tt".source = ./commands;
  home.file.".claude/tt".source = ./reference;
}
