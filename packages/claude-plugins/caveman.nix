{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "c2ed24b3e5d412cd0c25197b2bc9af587621fd99";
  src = fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    inherit rev;
    hash = "sha256-m7HhCW4fXU5pIYRWVP6cvSYUkDHt8R90D9UI3tT7euk=";
  };
in
mkClaudePlugin {
  pname = "caveman";
  version = "1.5.0";
  inherit rev src;
  marketplace = {
    name = "caveman";
    inherit src;
    owner = "JuliusBrussee";
    repo = "caveman";
  };
}
