{ fetchFromGitHub, mkClaudePlugin }:
let
  rev = "57546260929473d4e0d1c1bb75297be2fdfa1949";
  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "skills";
    inherit rev;
    hash = "sha256-1D9otXxDvmKASBu/vtAEWv6kE+U+jG4OxZpRLZbGEF0=";
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
