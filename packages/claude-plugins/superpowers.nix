{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "5bf4e78011075bcfc0dc295f0724994cd123ee71";
  src = fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    inherit rev;
    hash = "sha256-rgeJhjQyABYlhlyFRmgyhbZmmmIPPNkch4CXyTkGEyM=";
  };
  marketplaceSrc = fetchFromGitHub {
    owner = "obra";
    repo = "superpowers-marketplace";
    rev = "14fb891be25c7c8d7fb22a07cc1b91eeb37b4a36";
    hash = "sha256-PjOZfxyNeUb1VR2scVR8L+4UjdC9TeQCm+E//9DduHc=";
  };
in
mkClaudePlugin {
  pname = "superpowers";
  version = "6.4.1";
  inherit rev src;
  marketplace = {
    name = "superpowers-marketplace";
    src = marketplaceSrc;
    owner = "obra";
    repo = "superpowers-marketplace";
  };
}
