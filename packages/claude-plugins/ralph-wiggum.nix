{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "f298d940faf08deec44f7a7a4d382c673450a302";
  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-code";
    inherit rev;
    hash = "sha256-XDfZJuMBL94wxwuuK3Ugxsf1V3B9ylX6zhMWPXz4fU0=";
  };
in
mkClaudePlugin {
  pname = "ralph-wiggum";
  version = "1.0.0";
  inherit rev src;
  pluginSubdir = "plugins/ralph-wiggum";
  marketplace = {
    name = "claude-code";
    inherit src;
    owner = "anthropics";
    repo = "claude-code";
  };
}
