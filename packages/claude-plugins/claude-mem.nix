{ lib, pkgs, fetchFromGitHub, mkClaudePlugin }:
let
  rev = "a16b25275e5f56b6d35d5fcf1a8324b8670792c8";
  src = fetchFromGitHub {
    owner = "thedotmack";
    repo = "claude-mem";
    inherit rev;
    hash = "sha256-U1eM3NALFmq6ACYVympRPJMnfW7h9RYdLttW4c9jr04=";
  };

  # uvx wrapper that intercepts chroma-mcp calls to use nix-packaged version
  # claude-mem calls: uvx --python 3.13 chroma-mcp --client-type persistent ...
  uvx-wrapper = pkgs.writeShellScriptBin "uvx" ''
    args=("$@")
    for i in "''${!args[@]}"; do
      if [ "''${args[$i]}" = "chroma-mcp" ]; then
        exec ${pkgs.chroma-mcp}/bin/chroma-mcp "''${args[@]:$((i+1))}"
      fi
    done
    exec ${pkgs.uv}/bin/uvx "$@"
  '';
in
mkClaudePlugin {
  pname = "claude-mem";
  version = "9.0.12";
  inherit rev src;
  pluginSubdir = "plugin";
  marketplace = {
    name = "claude-mem";
    inherit src;
    owner = "thedotmack";
    repo = "claude-mem";
  };
  runtimeInputs = [
    pkgs.bun # claude-mem worker
    pkgs.uv # claude-mem uses uvx for Python packages
    pkgs.chroma-mcp # Nix-packaged vector search
    (lib.hiPrio uvx-wrapper) # Override uv's uvx to intercept chroma-mcp
  ];
  # Workaround: claude-mem hardcodes 'thedotmack' marketplace path
  activationScript = ''
    ln -sfn "$HOME/.claude/plugins/marketplaces/claude-mem" "$HOME/.claude/plugins/marketplaces/thedotmack"
  '';
}
