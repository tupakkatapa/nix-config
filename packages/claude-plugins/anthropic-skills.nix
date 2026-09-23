{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "34040c9c568585f6929bedeaad110ad08f079624";
  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    inherit rev;
    hash = "sha256-tI4bTTBfI1ylltklGyiyA7pLoKXEWtrT6lrmwrpLbCw=";
  };
  marketplace = {
    name = "anthropic-agent-skills";
    inherit src;
    owner = "anthropics";
    repo = "skills";
  };
in
{
  document-skills = mkClaudePlugin {
    pname = "document-skills";
    version = "1.0.0";
    inherit rev src marketplace;
  };
  example-skills = mkClaudePlugin {
    pname = "example-skills";
    version = "1.0.0";
    inherit rev src marketplace;
  };
}
