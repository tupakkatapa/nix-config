{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "8b0c1d3699b8d83e87fe4605b378da20c41555e0";
  src = fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    inherit rev;
    hash = "sha256-dsGzPscjy7FfaovfYML2q+RmuBJwwEJ9sjeHi+Niv6Y=";
  };
in
mkClaudePlugin {
  pname = "caveman";
  version = "2.7.0";
  inherit rev src;
  marketplace = {
    name = "caveman";
    inherit src;
    owner = "JuliusBrussee";
    repo = "caveman";
  };
}
