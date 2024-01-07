# Shell for bootstrapping flake-enabled nix and other tooling
{
  inputs,
  pkgs,
  ...
}: {
  default = pkgs.mkShell {
    NIX_CONFIG = ''
      accept-flake-config = true
      extra-experimental-features = flakes nix-command
      warn-dirty = false
    '';
    nativeBuildInputs = with pkgs; [
      inputs.nix-pxe.packages.${pkgs.system}.pxe-generate

      nix
      home-manager
      git

      sops
      ssh-to-age
      gnupg
      age

      cloc
    ];
  };
}
