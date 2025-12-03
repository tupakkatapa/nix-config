{ pkgs
, unstable
, ...
}: {
  # AI CLI tools
  environment.systemPackages = [
    pkgs.codex
    unstable.gemini-cli
  ];
}
