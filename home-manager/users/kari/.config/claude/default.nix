{ pkgs, ... }:
let
  permissions = import ./permissions.nix;
in
{
  programs.claude-code = {
    enable = true;
    skillsDir = ./skills;

    # Custom slash commands
    commands = {
      "tt-commit.md" = builtins.readFile ./commands/tt-commit.md;
      "tt-implement.md" = builtins.readFile ./commands/tt-implement.md;
      "tt-review.md" = builtins.readFile ./commands/tt-review.md;
    };

    settings = {
      alwaysThinkingEnabled = true;
      permissions = {
        inherit (permissions) allow deny;
      };
      hooks = {
        UserPromptSubmit = [{
          hooks = [{
            type = "command";
            command = "echo 'ultrathink:'";
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

    # Plugin management via homeModules.claudeCode extension
    plugins = {
      # Plugins with separate marketplace repos
      fromGitHub = [{
        owner = "obra";
        repo = "superpowers";
        version = "4.0.3";
        rev = "b9e16498b9b6b06defa34cf0d6d345cd2c13ad31";
        hash = "sha256-0/biMK5A9DwXI/UeouBX2aopkUslzJPiNi+eZFkkzXI=";
        marketplace = {
          owner = "obra";
          repo = "superpowers-marketplace";
          rev = "d466ee3584579088a4ee9a694f3059fa73c17ff1";
          hash = "sha256-4juZafMOd+JnP5z1r3EyDqyL9PGlPnOCA/e3I/5kfNQ=";
        };
      }];
      # Self-contained plugins (repo is both plugin and marketplace)
      selfContained = [{
        owner = "thedotmack";
        repo = "claude-mem";
        name = "claude-mem";
        version = "9.0.12";
        rev = "a16b25275e5f56b6d35d5fcf1a8324b8670792c8";
        hash = "sha256-U1eM3NALFmq6ACYVympRPJMnfW7h9RYdLttW4c9jr04=";
        pluginSubdir = "plugin";
      }];
    };
  };

  # MCP server dependencies
  home.packages = with pkgs; [ nodejs ];
}
