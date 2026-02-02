{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "b9e16498b9b6b06defa34cf0d6d345cd2c13ad31";
  src = fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    inherit rev;
    hash = "sha256-0/biMK5A9DwXI/UeouBX2aopkUslzJPiNi+eZFkkzXI=";
  };
  marketplaceSrc = fetchFromGitHub {
    owner = "obra";
    repo = "superpowers-marketplace";
    rev = "d466ee3584579088a4ee9a694f3059fa73c17ff1";
    hash = "sha256-4juZafMOd+JnP5z1r3EyDqyL9PGlPnOCA/e3I/5kfNQ=";
  };
in
mkClaudePlugin {
  pname = "superpowers";
  version = "4.0.3";
  inherit rev src;
  marketplace = {
    name = "superpowers-marketplace";
    src = marketplaceSrc;
    owner = "obra";
    repo = "superpowers-marketplace";
  };
}
