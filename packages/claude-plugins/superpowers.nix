{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "6fd4507659784c351abbd2bc264c7162cfd386dc";
  src = fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    inherit rev;
    hash = "sha256-P/FD8HTQO+QzvMe3A/B2v2vjs8T6ZmIYH3MPp79dSzo=";
  };
  marketplaceSrc = fetchFromGitHub {
    owner = "obra";
    repo = "superpowers-marketplace";
    rev = "c16dd5785082eb1c11246d3705ebe47410a16fb2";
    hash = "sha256-8J3Qjzi1pdbsOQcZQ3wImOvbtZP9K+qJOpY6iDN8eQg=";
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
