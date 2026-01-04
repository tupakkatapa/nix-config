{ pkgs, ... }:
let
  permissions = import ./permissions.nix;
in
{
  programs.claude-code = {
    enable = true;
    skillsDir = ./skills;

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
      claude-flow = {
        command = "npx";
        args = [ "claude-flow@alpha" "mcp" "start" ];
      };
    };

    # Global CLAUDE.md - applies to all projects
    memory.source = ./CLAUDE.md;

    # Plugin management via homeModules.claudeCode extension
    plugins.fromGitHub = [{
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
  };

  # MCP server dependencies
  home.packages = with pkgs; [ nodejs ];
}
