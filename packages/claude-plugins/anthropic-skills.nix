{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "1ed29a03dc852d30fa6ef2ca53a67dc2c2c2c563";
  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    inherit rev;
    hash = "sha256-9FGubcwHcGBJcKl02aJ+YsTMiwDOdgU/FHALjARG51c=";
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
