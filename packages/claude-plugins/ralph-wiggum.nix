{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "56f36532530f88b572854538d685fcf781141e8c";
  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-code";
    inherit rev;
    hash = "sha256-LXVNQNpw4Sgvc50eKJTZ/1zMNrQEVKfZ8oYNTCJ6G18=";
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
