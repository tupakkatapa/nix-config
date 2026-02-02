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
      "tt-check" = builtins.readFile ./commands/tt-check.md;
      "tt-commit" = builtins.readFile ./commands/tt-commit.md;
      "tt-implement" = builtins.readFile ./commands/tt-implement.md;
      "tt-review" = builtins.readFile ./commands/tt-review.md;
      "tt-security" = builtins.readFile ./commands/tt-security.md;
      "tt-explain" = builtins.readFile ./commands/tt-explain.md;
      "tt-mermaid" = builtins.readFile ./commands/tt-mermaid.md;
    };

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
    ];
  };

  # MCP server dependencies
  home.packages = with pkgs; [ nodejs uv ];
}
