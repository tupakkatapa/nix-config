# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/minimal.nix
# https://github.com/NuschtOS/nixos-modules/blob/main/modules/slim.nix
{ modulesPath
, ...
}: {
  imports = [
    (modulesPath + "/profiles/minimal.nix")
  ];

  # Disable speech-dispatcher
  services.orca.enable = false; # requires speechd
  services.speechd.enable = false;
}

