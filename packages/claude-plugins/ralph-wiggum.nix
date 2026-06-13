{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "ee81682a72b07705672332d1dc963927a998c177";
  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-code";
    inherit rev;
    hash = "sha256-hgMewrcB+xQuWw1jYovfjFc2LYxI2+vcKITHEn/Wfrs=";
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
