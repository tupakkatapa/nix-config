{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "25d22f864ad68cc447a4cb93aefde918aa4aec9f";
  src = fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    inherit rev;
    hash = "sha256-FbmfhFaPs/SnSZdfNdErdIUHXt1FfBzErpPpLy8kdIc=";
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
