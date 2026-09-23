{ fetchFromGitHub, mkClaudePlugin, nodejs }:
let
  rev = "1d95ff7d39de12d87014ea40d4e22201bddc501b";
  src = fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    inherit rev;
    hash = "sha256-PES5XrSYx0VBXWVHEDRykGy0SAmJfV/luzy8Gfg0aAQ=";
  };
in
mkClaudePlugin {
  pname = "ponytail";
  version = "4.10.0";
  inherit rev src;
  # SessionStart/UserPromptSubmit hooks are node scripts
  runtimeInputs = [ nodejs ];
  marketplace = {
    name = "ponytail";
    inherit src;
    owner = "DietrichGebert";
    repo = "ponytail";
  };
}
